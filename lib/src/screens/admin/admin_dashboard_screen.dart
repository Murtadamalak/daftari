import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  int _usersCount = 0;
  int _activeSubsCount = 0;
  int _pendingCount = 0;
  List<dynamic> _recentSubs = [];
  String _adminName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Admin name
      final adminId = _supabase.auth.currentUser?.id;
      if (adminId != null) {
        final adminProfile = await _supabase
            .from('profiles')
            .select('full_name')
            .eq('id', adminId)
            .maybeSingle();
        _adminName = (adminProfile?['full_name'] as String?) ?? 'المدير';
      }

      // Basic counts
      final usersRes = await _supabase.from('profiles').select('id');
      final activeSubsRes = await _supabase
          .from('subscriptions')
          .select('id')
          .eq('status', 'active')
          .neq('plan_type', 'free');
      final pendingRes = await _supabase
          .from('payment_requests')
          .select('id')
          .eq('status', 'pending');

      // Recent subs with end_date
      final recentRes = await _supabase
          .from('subscriptions')
          .select('*, profiles(full_name)')
          .eq('status', 'active')
          .neq('plan_type', 'free')
          .order('activated_at', ascending: false)
          .limit(15);

      if (mounted) {
        setState(() {
          _usersCount = usersRes.length;
          _activeSubsCount = activeSubsRes.length;
          _pendingCount = pendingRes.length;
          _recentSubs = recentRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Remaining days helper ───────────────────────────────────────────────────
  int _daysRemaining(dynamic endDateStr) {
    if (endDateStr == null) return 0;
    try {
      final end = DateTime.parse(endDateStr.toString());
      final diff = end.difference(DateTime.now()).inDays;
      return diff < 0 ? 0 : diff;
    } catch (_) {
      return 0;
    }
  }

  Color _daysColor(int days) {
    if (days <= 3) return const Color(0xFFDC2626);
    if (days <= 10) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF4DB896)));
    }

    return RefreshIndicator(
      color: const Color(0xFF4DB896),
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: [
          // ── Welcome Banner ─────────────────────────────────────────────────
          _buildWelcomeBanner(),
          const SizedBox(height: 20),

          // ── KPI Cards ──────────────────────────────────────────────────────
          _buildKpiGrid(),
          const SizedBox(height: 24),

          // ── Section header ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DB896).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_outline,
                        color: Color(0xFF4DB896), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الاشتراكات النشطة',
                    style: GoogleFonts.almarai(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_recentSubs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4DB896).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_recentSubs.length}',
                        style: GoogleFonts.almarai(
                          fontSize: 11,
                          color: const Color(0xFF4DB896),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: _fetchData,
                icon: const Icon(Icons.refresh, color: Color(0xFF8AADA5)),
                iconSize: 20,
                tooltip: 'تحديث',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Subscriptions List ─────────────────────────────────────────────
          if (_recentSubs.isEmpty)
            _EmptyCard(
              icon: Icons.people_outline,
              message: 'لا توجد اشتراكات نشطة',
            )
          else
            ..._recentSubs
                .map((sub) => _buildSubTile(sub as Map<String, dynamic>)),
        ],
      ),
    );
  }

  // ── Welcome Banner ──────────────────────────────────────────────────────────

  Widget _buildWelcomeBanner() {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? '🌅 صباح الخير'
        : now.hour < 17
            ? '🌤 مساء الخير'
            : '🌙 مساء النور';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A2F), Color(0xFF0D2B22), Color(0xFF0A1E18)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4DB896).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4DB896).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.almarai(
                    color: const Color(0xFF4DB896),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.almarai(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      const TextSpan(text: 'أهلاً بيك '),
                      TextSpan(
                        text: 'سيدي ',
                        style: GoogleFonts.almarai(
                          color: const Color(0xFFD8A84A),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: _adminName,
                        style: GoogleFonts.almarai(
                          color: const Color(0xFFD8A84A),
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8A84A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD8A84A).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined,
                          color: Color(0xFFD8A84A), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        'مدير النظام',
                        style: GoogleFonts.almarai(
                          color: const Color(0xFFD8A84A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
                  style: GoogleFonts.almarai(
                    color: const Color(0xFF8AADA5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8A84A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD8A84A).withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.admin_panel_settings,
                    color: Color(0xFFD8A84A), size: 30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── KPI Grid ────────────────────────────────────────────────────────────────

  Widget _buildKpiGrid() {
    final cards = [
      _KpiData(
        title: 'إجمالي المستخدمين',
        value: '$_usersCount',
        icon: Icons.people_outline,
        color: const Color(0xFF4DB896),
        bg: const Color(0xFF4DB896).withOpacity(0.1),
      ),
      _KpiData(
        title: 'مشتركون نشطون',
        value: '$_activeSubsCount',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF22C55E),
        bg: const Color(0xFF22C55E).withOpacity(0.1),
      ),
      _KpiData(
        title: 'طلبات معلّقة',
        value: '$_pendingCount',
        icon: Icons.pending_actions_outlined,
        color: _pendingCount > 0
            ? const Color(0xFFDC2626)
            : const Color(0xFF8AADA5),
        bg: _pendingCount > 0
            ? const Color(0xFFDC2626).withOpacity(0.1)
            : const Color(0xFF8AADA5).withOpacity(0.08),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return Container(
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.color.withOpacity(0.2), width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(c.icon, color: c.color, size: 24),
              const Spacer(),
              Text(
                c.value,
                style: GoogleFonts.almarai(
                  color: c.color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                c.title,
                style: GoogleFonts.almarai(
                  color: c.color.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Sub Tile ────────────────────────────────────────────────────────────────

  Widget _buildSubTile(Map<String, dynamic> sub) {
    final dynamic profileData = sub['profiles'];
    final profileMap = profileData is List
        ? (profileData.isNotEmpty
            ? profileData[0] as Map<String, dynamic>
            : null)
        : profileData as Map<String, dynamic>?;
    final name = (profileMap?['full_name'] as String?) ?? 'مستخدم';
    final planType = sub['plan_type'] ?? 'free';
    final planLabel = planType == 'yearly'
        ? 'سنوية'
        : planType == 'monthly'
            ? 'شهرية'
            : 'مجانية';
    final daysLeft = _daysRemaining(sub['end_date'] as String?);
    final dColor = _daysColor(daysLeft);
    final endDate = sub['end_date'] != null
        ? DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(sub['end_date'] as String))
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13211D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: daysLeft <= 3
              ? const Color(0xFFDC2626).withOpacity(0.3)
              : const Color(0xFF4DB896).withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4DB896).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0] : 'م',
                  style: GoogleFonts.almarai(
                    color: const Color(0xFF4DB896),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Name + details ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.almarai(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8A84A).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'باقة $planLabel',
                          style: GoogleFonts.almarai(
                            color: const Color(0xFFD8A84A),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'حتى $endDate',
                        style: GoogleFonts.almarai(
                          color: const Color(0xFF8AADA5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Days remaining badge ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: dColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: dColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$daysLeft',
                        style: GoogleFonts.almarai(
                          color: dColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        'يوم',
                        style: GoogleFonts.almarai(
                          color: dColor.withOpacity(0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (daysLeft <= 3)
                  Text(
                    '⚠️ ينتهي قريباً',
                    style: GoogleFonts.almarai(
                      color: const Color(0xFFDC2626),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper classes ────────────────────────────────────────────────────────────

class _KpiData {
  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF4DB896).withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4DB896).withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: const Color(0xFF4DB896).withOpacity(0.4)),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.almarai(
              color: const Color(0xFF8AADA5),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
