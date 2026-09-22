import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:daftar_debt_manager/src/data/repositories/invoice_repository.dart';
import 'package:daftar_debt_manager/src/data/local/offline_database.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  try {
    final db = await OfflineDatabase.instance.database;
    final items = await db.query('invoice_items');
    print('Invoice items count: ${items.length}');
    if (items.isNotEmpty) {
      print('First item: ${items.first}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
