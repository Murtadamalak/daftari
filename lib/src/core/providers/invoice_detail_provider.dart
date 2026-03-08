import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/invoice_repository.dart';
import 'app_providers.dart';

/// Holds the full detail of one invoice: header + items list.
class InvoiceDetail {
  InvoiceDetail({required this.invoice, required this.items});
  final InvoiceModel invoice;
  final List<InvoiceItemModel> items;
}

/// Family provider: pass invoice ID → returns AsyncValue<InvoiceDetail>
final invoiceDetailProvider =
    FutureProvider.autoDispose.family<InvoiceDetail, String>((ref, id) async {
  final repo = ref.watch(invoiceRepositoryProvider);
  final invoice = await repo.getById(id);
  if (invoice == null) throw StateError('Invoice $id not found');
  final items = await repo.getItemsByInvoiceId(id);
  return InvoiceDetail(invoice: invoice, items: items);
});
