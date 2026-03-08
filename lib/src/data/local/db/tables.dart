import 'package:drift/drift.dart';

class Products extends Table {
  TextColumn get id => text()();

  TextColumn get barcode => text().nullable()();

  TextColumn get name => text()();

  TextColumn get unit => text()();

  RealColumn get retailPrice => real()();

  RealColumn get wholesalePrice => real().nullable()();

  RealColumn get stock => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get phone => text().nullable()();

  RealColumn get totalDebt => real().withDefault(const Constant(0.0))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Invoices extends Table {
  TextColumn get id => text()(); // INV-001 ...

  IntColumn get num => integer()(); // numeric sequence

  DateTimeColumn get date => dateTime()();

  TextColumn get customerId => text().nullable()();

  TextColumn get customerName => text()();

  TextColumn get customerPhone => text().nullable()();

  RealColumn get subtotal => real()();

  RealColumn get discount => real().withDefault(const Constant(0.0))();

  RealColumn get grandTotal => real()();

  RealColumn get paid => real()();

  RealColumn get debt => real()();

  TextColumn get payType => text()(); // cash / partial / debt

  TextColumn get note => text().nullable()();

  TextColumn get status => text()(); // paid / partial / unpaid

  TextColumn get shopName => text()();

  TextColumn get shopLogoPath => text().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};

  @override
  List<String> get customConstraints => ['UNIQUE(num)'];
}

class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get invoiceId => text()();

  TextColumn get productName => text()();

  TextColumn get unit => text()();

  RealColumn get qty => real()();

  RealColumn get unitPrice => real()();

  TextColumn get priceType => text()(); // retail / wholesale

  RealColumn get total => real()();

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY(invoice_id) REFERENCES invoices(id) ON DELETE CASCADE',
      ];
}
