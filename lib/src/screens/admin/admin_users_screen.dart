import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─── Admin Colors ─────────────────────────────────────────────────────────────
const _bg = Color(0xFF0A1612);
const _surface = Color(0xFF13211D);
const _surface2 = Color(0xFF1D332D);
const _primary = Color(0xFF4DB896);
const _gold = Color(0xFFD8A84A);
const _textMain = Color(0xFFF0F7F5);
const _textMuted = Color(0xFF8AADA5);
const _danger = Color(0xFFDC2626);
const _warning = Color(0xFFD97706);
const _success = Color(0xFF16A34A);

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final res = await _supabase
        .from('profiles')
        .select('*, subscriptions(*), payment_requests(status)');
    if (mounted) {
      setState(() {
        _users = res;
        _isLoading = false;
      });
    }
  }

  // ── Days helper ──────────────────────────────────────────────────────────────
  int _daysLeft(dynamic endDateStr) {
    if (endDateStr == null) return 0;
    try {
      final d = DateTime.parse(endDateStr.toString())
          .difference(DateTime.now())
          .inDays;
      return d < 0 ? 0 : d;
    } catch (_) {
      return 0;
    }
  }

  Color _daysColor(int days) {
    if (days <= 3) return _danger;
    if (days <= 10) return _warning;
    return _success;
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _manualAction(String planType, String userId) async {
    try {
      await _supabase.rpc<dynamic>('activate_subscription', params: {
        'p_user_id': userId,
        'p_plan': planType,
        'p_admin_id': _supabase.auth.currentUser!.id,
      });
      _showSnack('تم تفعيل الاشتراك ✓', _success);
      _fetchUsers();
    } catch (e) {
      _showSnack('خطأ: ${e.toString()}', _danger);
    }
  }

  Future<void> _stopSubscription(String userId) async {
    final confirmed = await _confirmDialog(
      title: 'إيقاف الاشتراك',
      content: 'هل أنت متأكد من إيقاف باقة المستخدم؟',
      confirmLabel: 'إيقاف',
      confirmColor: _danger,
    );
    if (confirmed != true) return;
    try {
      await _supabase.from('subscriptions').update({
        'status': 'expired',
        'end_date': DateTime.now().toIso8601String()
      }).eq('user_id', userId);
      _showSnack('تم إيقاف الاشتراك', _warning);
      _fetchUsers();
    } catch (e) {
      _showSnack('خطأ: ${e.toString()}', _danger);
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────
  Future<bool?> _confirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: GoogleFonts.cairo(
                color: _textMain, fontWeight: FontWeight.w700)),
        content: Text(content,
            style: GoogleFonts.cairo(color: _textMuted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: _textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: confirmColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: GoogleFonts.cairo(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showActivateByCustomerDialog() {
    final customerIdCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '12');

    showDialog<void>(
      context: context,
      builder: (ctx) => _AdminDialog(
        title: 'تفعيل برقم العميل',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AdminTextField(
                controller: customerIdCtrl, label: 'رقم العميل (A1B2C3D4)'),
            const SizedBox(height: 12),
            _AdminTextField(
                controller: daysCtrl,
                label: 'عدد الأيام',
                keyboardType: TextInputType.number),
          ],
        ),
        onConfirm: () async {
          final cId = customerIdCtrl.text.trim();
          final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
          if (cId.isEmpty || days <= 0) return;
          Navigator.pop(ctx);
          try {
            await _supabase
                .rpc<dynamic>('activate_subscription_by_days', params: {
              'p_customer_id': cId,
              'p_days': days,
              'p_admin_id': _supabase.auth.currentUser!.id,
            });
            if (mounted) {
              _showSnack('تم تفعيل المشترك لـ $days يوم ✓', _success);
              _fetchUsers();
            }
          } catch (e) {
            if (mounted) _showSnack('خطأ: ${e.toString()}', _danger);
          }
        },
      ),
    );
  }

  void _showCustomDaysDialogForUser(String customerId) {
    final daysCtrl = TextEditingController(text: '5');
    showDialog<void>(
      context: context,
      builder: (ctx) => _AdminDialog(
        title: 'تفعيل مدة مخصصة',
        child: _AdminTextField(
            controller: daysCtrl,
            label: 'عدد الأيام',
            keyboardType: TextInputType.number),
        onConfirm: () async {
          final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
          if (days <= 0) return;
          Navigator.pop(ctx);
          try {
            await _supabase
                .rpc<dynamic>('activate_subscription_by_days', params: {
              'p_customer_id': customerId,
              'p_days': days,
              'p_admin_id': _supabase.auth.currentUser!.id,
            });
            if (mounted) {
              _showSnack('تم التفعيل لمدة $days يوم ✓', _success);
              _fetchUsers();
            }
          } catch (e) {
            if (mounted) _showSnack('خطأ: ${e.toString()}', _danger);
          }
        },
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    final dynamic subsRaw = user['subscriptions'];
    final List<dynamic> subscriptions =
        subsRaw is List ? subsRaw : (subsRaw == null ? [] : [subsRaw]);
    final Map<String, dynamic>? sub = subscriptions.isNotEmpty
        ? subscriptions[0] as Map<String, dynamic>?
        : null;
    final userId = user['id'] as String;
    final fullName = (user['full_name'] as String?) ?? 'مستخدم';
    final shopName = (user['shop_name'] as String?) ?? '';
    final cId = userId.substring(0, 8).toUpperCase();
    final days = _daysLeft(sub?['end_date']);
    final dColor = _daysColor(days);

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        fullName.isNotEmpty ? fullName[0] : 'م',
                        style: GoogleFonts.cairo(
                          color: _primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textMain),
                        ),
                        Text(
                          shopName,
                          style: GoogleFonts.cairo(
                              color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Customer ID ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag, color: _gold, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'رقم العميل: $cId',
                      style: GoogleFonts.cairo(
                        color: _gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Subscription info ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                      label: 'الباقة',
                      value: sub != null
                          ? (sub['plan_type'] == 'yearly'
                              ? 'سنوية'
                              : sub['plan_type'] == 'monthly'
                                  ? 'شهرية'
                                  : 'مجانية')
                          : 'لا يوجد',
                    ),
                    const Divider(color: Color(0xFF1D332D), height: 16),
                    _InfoRow(
                      label: 'تاريخ الانتهاء',
                      value: sub?['end_date'] != null
                          ? DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(sub?['end_date'] as String))
                          : '—',
                    ),
                    const Divider(color: Color(0xFF1D332D), height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الأيام المتبقية',
                            style: GoogleFonts.cairo(
                                color: _textMuted, fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: dColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: dColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$days يوم',
                            style: GoogleFonts.cairo(
                              color: dColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'إجراءات',
                style: GoogleFonts.cairo(
                    color: _textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'شهر',
                      color: const Color(0xFF1D4ED8),
                      icon: Icons.calendar_month_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        _manualAction('monthly', userId);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: 'سنة',
                      color: _gold,
                      icon: Icons.star_outline,
                      onTap: () {
                        Navigator.pop(context);
                        _manualAction('yearly', userId);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: 'أيام',
                      color: _primary,
                      icon: Icons.timelapse_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomDaysDialogForUser(cId);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ActionBtn(
                label: 'إيقاف الاشتراك',
                color: _danger,
                icon: Icons.block_outlined,
                fullWidth: true,
                onTap: () {
                  Navigator.pop(context);
                  _stopSubscription(userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }

    final filtered = _search.isEmpty
        ? _users
        : _users.where((u) {
            final name = ((u['full_name'] as String?) ?? '').toLowerCase();
            final phone = ((u['phone'] as String?) ?? '').toLowerCase();
            final q = _search.toLowerCase();
            return name.contains(q) || phone.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.cairo(color: _textMain, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'بحث بالاسم أو الهاتف...',
                hintStyle: GoogleFonts.cairo(color: _textMuted, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: _textMuted, size: 18),
                filled: true,
                fillColor: _surface2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: RefreshIndicator(
              color: _primary,
              onRefresh: _fetchUsers,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final userMap = filtered[index] as Map<String, dynamic>;
                  final dynamic subsRaw = userMap['subscriptions'];
                  final List<dynamic> subscriptions = subsRaw is List
                      ? subsRaw
                      : (subsRaw == null ? [] : [subsRaw]);
                  final sub = (subscriptions.isNotEmpty)
                      ? subscriptions[0] as Map<String, dynamic>?
                      : null;

                  final dynamic requestsRaw = userMap['payment_requests'];
                  final List<dynamic> paymentRequests = (requestsRaw is List)
                      ? requestsRaw
                      : (requestsRaw == null ? [] : [requestsRaw]);
                  final hasPending = paymentRequests
                      .any((r) => (r['status'] as String?) == 'pending');
                  final userId = userMap['id'] as String;
                  final fullName =
                      (userMap['full_name'] as String?) ?? 'مستخدم';
                  final cId = userId.substring(0, 8).toUpperCase();
                  final days = _daysLeft(sub?['end_date']);
                  final dColor = _daysColor(days);
                  final isActive = sub != null && sub['status'] == 'active';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasPending
                            ? _warning.withOpacity(0.3)
                            : days <= 3 && isActive
                                ? _danger.withOpacity(0.3)
                                : _primary.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showUserDetails(userMap),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              // ── Avatar ──
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    fullName.isNotEmpty ? fullName[0] : 'م',
                                    style: GoogleFonts.cairo(
                                      color: _primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // ── Name + ID ──
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            fullName,
                                            style: GoogleFonts.cairo(
                                              color: _textMain,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (hasPending)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _warning.withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text('معلّق',
                                                style: GoogleFonts.cairo(
                                                    color: _warning,
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: _gold.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text('#$cId',
                                              style: GoogleFonts.cairo(
                                                color: _gold,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              )),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          (userMap['phone'] as String?) ?? '—',
                                          style: GoogleFonts.cairo(
                                              color: _textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // ── Days Badge ──
                              if (isActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: dColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: dColor.withOpacity(0.3),
                                        width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '$days',
                                        style: GoogleFonts.cairo(
                                          color: dColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'يوم',
                                        style: GoogleFonts.cairo(
                                          color: dColor.withOpacity(0.7),
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _danger.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'منتهي',
                                    style: GoogleFonts.cairo(
                                      color: _danger.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_left,
                                  size: 16, color: _textMuted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        foregroundColor: _bg,
        onPressed: _showActivateByCustomerDialog,
        icon: const Icon(Icons.flash_on),
        label: Text('تفعيل أيام',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, color: _bg)),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.cairo(color: _textMuted, fontSize: 13)),
        Text(value,
            style: GoogleFonts.cairo(
                color: _textMain, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: color.withOpacity(0.25), width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label,
            style:
                GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 12)),
      ),
    );
  }
}

class _AdminDialog extends StatelessWidget {
  const _AdminDialog({
    required this.title,
    required this.child,
    required this.onConfirm,
  });
  final String title;
  final Widget child;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title,
          style:
              GoogleFonts.cairo(color: _textMain, fontWeight: FontWeight.w700)),
      content: child,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء', style: GoogleFonts.cairo(color: _textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: _bg,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onConfirm,
          child: Text('تفعيل',
              style:
                  GoogleFonts.cairo(fontWeight: FontWeight.w700, color: _bg)),
        ),
      ],
    );
  }
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.cairo(color: _textMain, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: _textMuted),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primary.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
      ),
    );
  }
}
