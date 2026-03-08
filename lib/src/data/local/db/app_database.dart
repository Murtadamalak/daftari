import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Customers,
    Invoices,
    InvoiceItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'daftar_db'));

  @override
  int get schemaVersion => 1;

  // Future migrations can be added here when schemaVersion changes.
}
