import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/providers/app_providers.dart';
import '../core/providers/invoices_provider.dart';
import '../data/repositories/invoice_repository.dart';
import '../core/widgets/refresh_action_button.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredAsync = ref.watch(filteredInvoicesProvider);
    final selectedStatus = ref.watch(invoiceStatusFilterProvider);
    final sortField = ref.watch(invoiceSortFieldProvider);
    final sortAscending = ref.watch(invoiceSortAscendingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('سجل الفواتير'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          RefreshActionButton(
            onPressed: () => ref.invalidate(allInvoicesProvider),
          ),
          filteredAsync.when(
            data: (list) => Padding(
              padding: const EdgeInsets.only(left: 8, right: 4),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length} فاتورة',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search & Filter Header ─────────────────────────────────────────
          _SearchAndFilterBar(
            controller: _searchController,
            selectedStatus: selectedStatus,
            sortField: sortField,
            sortAscending: sortAscending,
            onSearchChanged: (val) =>
                ref.read(invoiceSearchQueryProvider.notifier).state = val,
            onFilterChanged: (filter) =>
                ref.read(invoiceStatusFilterProvider.notifier).state = filter,
            onSortFieldChanged: (field) {
              final current = ref.read(invoiceSortFieldProvider);
              if (current == field) {
                // Toggle direction if same field tapped
                ref.read(invoiceSortAscendingProvider.notifier).state =
                    !ref.read(invoiceSortAscendingProvider);
              } else {
                ref.read(invoiceSortFieldProvider.notifier).state = field;
                ref.read(invoiceSortAscendingProvider.notifier).state = true;
              }
            },
          ),

          // ─── Invoices List ──────────────────────────────────────────────────
          Expanded(
            child: filteredAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text('حدث خطأ: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return _EmptyState(
                    hasFilters: _searchController.text.isNotEmpty ||
                        selectedStatus != InvoiceStatusFilter.all,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: invoices.length,
                  itemBuilder: (context, i) {
                    return _InvoiceCard(
                      invoice: invoices[i],
                      onTap: () =>
                          context.go('/invoices/details/${invoices[i].id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/invoices/create'),
        icon: const Icon(Icons.add),
        label: const Text('فاتورة جديدة'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search & Filter Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.selectedStatus,
    required this.sortField,
    required this.sortAscending,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortFieldChanged,
  });

  final TextEditingController controller;
  final InvoiceStatusFilter selectedStatus;
  final InvoiceSortField sortField;
  final bool sortAscending;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<InvoiceStatusFilter> onFilterChanged;
  final ValueChanged<InvoiceSortField> onSortFieldChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Background extension from AppBar ──
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
        ),

        // ── Foreground Floating Dashboard Card ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return TextField(
                      controller: controller,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'ابحث برقم الفاتورة أو اسم الزبون...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: Color(0xFF9CA3AF)),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF9CA3AF)),
                                onPressed: () {
                                  controller.clear();
                                  onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB), // Very light gray
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Sort Row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.sort_rounded,
                        size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 6),
                    const Text(
                      'ترتيب:',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: InvoiceSortField.values.map((field) {
                            final isSelected = sortField == field;
                            final primary =
                                Theme.of(context).colorScheme.primary;
                            return GestureDetector(
                              onTap: () => onSortFieldChanged(field),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primary.withValues(alpha: 0.12)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? primary.withValues(alpha: 0.4)
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      field.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? primary
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Icon(
                                          sortAscending
                                              ? Icons.arrow_upward_rounded
                                              : Icons.arrow_downward_rounded,
                                          key: ValueKey(sortAscending),
                                          size: 12,
                                          color: primary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Elegant Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: InvoiceStatusFilter.values.map((filter) {
                    final isSelected = selectedStatus == filter;
                    final color = _filterColor(filter);

                    return GestureDetector(
                      onTap: () => onFilterChanged(filter),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              filter.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? color
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 3,
                              width: 16,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _filterColor(InvoiceStatusFilter filter) {
    switch (filter) {
      case InvoiceStatusFilter.all:
        return const Color(0xFF6366F1); // Indigo
      case InvoiceStatusFilter.paid:
        return const Color(0xFF10B981); // Emerald
      case InvoiceStatusFilter.partial:
        return const Color(0xFFF59E0B); // Amber
      case InvoiceStatusFilter.unpaid:
        return const Color(0xFFEF4444); // Red
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice Card
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceCard extends ConsumerWidget {
  const _InvoiceCard({required this.invoice, required this.onTap});

  final InvoiceModel invoice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusInfo = _statusInfo(invoice);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: Invoice ID + Status Badge + Delete ──────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Invoice number
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'فاتورة #${invoice.formattedNum}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    children: [
                      _StatusBadge(
                        label: statusInfo.label,
                        color: statusInfo.color,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () =>
                            _confirmDeleteInvoice(context, ref, invoice),
                        tooltip: 'حذف',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Row 2: Customer & Date ────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      invoice.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('yyyy/MM/dd').format(invoice.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Row 3: Totals ─────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _AmountChip(
                      label: 'الإجمالي',
                      amount: invoice.grandTotal,
                      color: theme.colorScheme.primary,
                      bold: true,
                    ),
                    const Spacer(),
                    _AmountChip(
                      label: 'المدفوع',
                      amount: invoice.paid,
                      color: const Color(0xFF43A047),
                    ),
                    if (invoice.debt > 0) ...[
                      const Spacer(),
                      _AmountChip(
                        label: 'الدين',
                        amount: invoice.debt,
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteInvoice(
      BuildContext context, WidgetRef ref, InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفاتورة'),
        content:
            Text('هل أنت متأكد من حذف فاتورة رقم ${invoice.formattedNum}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(invoiceRepositoryProvider).deleteInvoice(invoice.id);
      ref.invalidate(allInvoicesProvider);
    }
  }

  ({String label, Color color}) _statusInfo(InvoiceModel invoice) {
    if (invoice.payType == 'تسديد دين') {
      return (
        label: 'دُفعة دين',
        color: const Color(0xFF6366F1)
      ); // Indigo for payments
    }
    switch (invoice.status) {
      case 'paid':
        return (label: 'مسدد', color: const Color(0xFF43A047));
      case 'partial':
        return (label: 'جزئي', color: const Color(0xFFFB8C00));
      case 'unpaid':
      default:
        return (label: 'دين', color: const Color(0xFFE53935));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });
  final String label;
  final double amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          '${NumberFormat('#,##0', 'en').format(amount)} IQD',
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters});
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'لا توجد نتائج مطابقة' : 'لا توجد فواتير بعد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'جرّب تغيير نص البحث أو الفلتر'
                  : 'اضغط على الزر أدناه لإنشاء أول فاتورة',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
