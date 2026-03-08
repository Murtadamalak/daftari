// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retailPriceMeta =
      const VerificationMeta('retailPrice');
  @override
  late final GeneratedColumn<double> retailPrice = GeneratedColumn<double>(
      'retail_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _wholesalePriceMeta =
      const VerificationMeta('wholesalePrice');
  @override
  late final GeneratedColumn<double> wholesalePrice = GeneratedColumn<double>(
      'wholesale_price', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<double> stock = GeneratedColumn<double>(
      'stock', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, barcode, name, unit, retailPrice, wholesalePrice, stock, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<Product> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('retail_price')) {
      context.handle(
          _retailPriceMeta,
          retailPrice.isAcceptableOrUnknown(
              data['retail_price']!, _retailPriceMeta));
    } else if (isInserting) {
      context.missing(_retailPriceMeta);
    }
    if (data.containsKey('wholesale_price')) {
      context.handle(
          _wholesalePriceMeta,
          wholesalePrice.isAcceptableOrUnknown(
              data['wholesale_price']!, _wholesalePriceMeta));
    }
    if (data.containsKey('stock')) {
      context.handle(
          _stockMeta, stock.isAcceptableOrUnknown(data['stock']!, _stockMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      retailPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}retail_price'])!,
      wholesalePrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}wholesale_price']),
      stock: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stock']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String? barcode;
  final String name;
  final String unit;
  final double retailPrice;
  final double? wholesalePrice;
  final double? stock;
  final DateTime createdAt;
  const Product(
      {required this.id,
      this.barcode,
      required this.name,
      required this.unit,
      required this.retailPrice,
      this.wholesalePrice,
      this.stock,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['name'] = Variable<String>(name);
    map['unit'] = Variable<String>(unit);
    map['retail_price'] = Variable<double>(retailPrice);
    if (!nullToAbsent || wholesalePrice != null) {
      map['wholesale_price'] = Variable<double>(wholesalePrice);
    }
    if (!nullToAbsent || stock != null) {
      map['stock'] = Variable<double>(stock);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      name: Value(name),
      unit: Value(unit),
      retailPrice: Value(retailPrice),
      wholesalePrice: wholesalePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(wholesalePrice),
      stock:
          stock == null && nullToAbsent ? const Value.absent() : Value(stock),
      createdAt: Value(createdAt),
    );
  }

  factory Product.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      unit: serializer.fromJson<String>(json['unit']),
      retailPrice: serializer.fromJson<double>(json['retailPrice']),
      wholesalePrice: serializer.fromJson<double?>(json['wholesalePrice']),
      stock: serializer.fromJson<double?>(json['stock']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'barcode': serializer.toJson<String?>(barcode),
      'name': serializer.toJson<String>(name),
      'unit': serializer.toJson<String>(unit),
      'retailPrice': serializer.toJson<double>(retailPrice),
      'wholesalePrice': serializer.toJson<double?>(wholesalePrice),
      'stock': serializer.toJson<double?>(stock),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Product copyWith(
          {String? id,
          Value<String?> barcode = const Value.absent(),
          String? name,
          String? unit,
          double? retailPrice,
          Value<double?> wholesalePrice = const Value.absent(),
          Value<double?> stock = const Value.absent(),
          DateTime? createdAt}) =>
      Product(
        id: id ?? this.id,
        barcode: barcode.present ? barcode.value : this.barcode,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        retailPrice: retailPrice ?? this.retailPrice,
        wholesalePrice:
            wholesalePrice.present ? wholesalePrice.value : this.wholesalePrice,
        stock: stock.present ? stock.value : this.stock,
        createdAt: createdAt ?? this.createdAt,
      );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      unit: data.unit.present ? data.unit.value : this.unit,
      retailPrice:
          data.retailPrice.present ? data.retailPrice.value : this.retailPrice,
      wholesalePrice: data.wholesalePrice.present
          ? data.wholesalePrice.value
          : this.wholesalePrice,
      stock: data.stock.present ? data.stock.value : this.stock,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('stock: $stock, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, barcode, name, unit, retailPrice, wholesalePrice, stock, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.unit == this.unit &&
          other.retailPrice == this.retailPrice &&
          other.wholesalePrice == this.wholesalePrice &&
          other.stock == this.stock &&
          other.createdAt == this.createdAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String?> barcode;
  final Value<String> name;
  final Value<String> unit;
  final Value<double> retailPrice;
  final Value<double?> wholesalePrice;
  final Value<double?> stock;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.unit = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.wholesalePrice = const Value.absent(),
    this.stock = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    this.barcode = const Value.absent(),
    required String name,
    required String unit,
    required double retailPrice,
    this.wholesalePrice = const Value.absent(),
    this.stock = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        unit = Value(unit),
        retailPrice = Value(retailPrice),
        createdAt = Value(createdAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? unit,
    Expression<double>? retailPrice,
    Expression<double>? wholesalePrice,
    Expression<double>? stock,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (unit != null) 'unit': unit,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (wholesalePrice != null) 'wholesale_price': wholesalePrice,
      if (stock != null) 'stock': stock,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? barcode,
      Value<String>? name,
      Value<String>? unit,
      Value<double>? retailPrice,
      Value<double?>? wholesalePrice,
      Value<double?>? stock,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<double>(retailPrice.value);
    }
    if (wholesalePrice.present) {
      map['wholesale_price'] = Variable<double>(wholesalePrice.value);
    }
    if (stock.present) {
      map['stock'] = Variable<double>(stock.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('unit: $unit, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('wholesalePrice: $wholesalePrice, ')
          ..write('stock: $stock, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, Customer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _totalDebtMeta =
      const VerificationMeta('totalDebt');
  @override
  late final GeneratedColumn<double> totalDebt = GeneratedColumn<double>(
      'total_debt', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, totalDebt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<Customer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('total_debt')) {
      context.handle(_totalDebtMeta,
          totalDebt.isAcceptableOrUnknown(data['total_debt']!, _totalDebtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Customer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Customer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      totalDebt: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_debt'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class Customer extends DataClass implements Insertable<Customer> {
  final String id;
  final String name;
  final String? phone;
  final double totalDebt;
  final DateTime createdAt;
  const Customer(
      {required this.id,
      required this.name,
      this.phone,
      required this.totalDebt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['total_debt'] = Variable<double>(totalDebt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      totalDebt: Value(totalDebt),
      createdAt: Value(createdAt),
    );
  }

  factory Customer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Customer(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      totalDebt: serializer.fromJson<double>(json['totalDebt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'totalDebt': serializer.toJson<double>(totalDebt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Customer copyWith(
          {String? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          double? totalDebt,
          DateTime? createdAt}) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        totalDebt: totalDebt ?? this.totalDebt,
        createdAt: createdAt ?? this.createdAt,
      );
  Customer copyWithCompanion(CustomersCompanion data) {
    return Customer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      totalDebt: data.totalDebt.present ? data.totalDebt.value : this.totalDebt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Customer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('totalDebt: $totalDebt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, totalDebt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Customer &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.totalDebt == this.totalDebt &&
          other.createdAt == this.createdAt);
}

class CustomersCompanion extends UpdateCompanion<Customer> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<double> totalDebt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.totalDebt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.totalDebt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<Customer> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<double>? totalDebt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (totalDebt != null) 'total_debt': totalDebt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<double>? totalDebt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      totalDebt: totalDebt ?? this.totalDebt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (totalDebt.present) {
      map['total_debt'] = Variable<double>(totalDebt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('totalDebt: $totalDebt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoicesTable extends Invoices with TableInfo<$InvoicesTable, Invoice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _numMeta = const VerificationMeta('num');
  @override
  late final GeneratedColumn<int> num = GeneratedColumn<int>(
      'num', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerPhoneMeta =
      const VerificationMeta('customerPhone');
  @override
  late final GeneratedColumn<String> customerPhone = GeneratedColumn<String>(
      'customer_phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _grandTotalMeta =
      const VerificationMeta('grandTotal');
  @override
  late final GeneratedColumn<double> grandTotal = GeneratedColumn<double>(
      'grand_total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paidMeta = const VerificationMeta('paid');
  @override
  late final GeneratedColumn<double> paid = GeneratedColumn<double>(
      'paid', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _debtMeta = const VerificationMeta('debt');
  @override
  late final GeneratedColumn<double> debt = GeneratedColumn<double>(
      'debt', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _payTypeMeta =
      const VerificationMeta('payType');
  @override
  late final GeneratedColumn<String> payType = GeneratedColumn<String>(
      'pay_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shopNameMeta =
      const VerificationMeta('shopName');
  @override
  late final GeneratedColumn<String> shopName = GeneratedColumn<String>(
      'shop_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shopLogoPathMeta =
      const VerificationMeta('shopLogoPath');
  @override
  late final GeneratedColumn<String> shopLogoPath = GeneratedColumn<String>(
      'shop_logo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        num,
        date,
        customerId,
        customerName,
        customerPhone,
        subtotal,
        discount,
        grandTotal,
        paid,
        debt,
        payType,
        note,
        status,
        shopName,
        shopLogoPath
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoices';
  @override
  VerificationContext validateIntegrity(Insertable<Invoice> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('num')) {
      context.handle(
          _numMeta, num.isAcceptableOrUnknown(data['num']!, _numMeta));
    } else if (isInserting) {
      context.missing(_numMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
    } else if (isInserting) {
      context.missing(_customerNameMeta);
    }
    if (data.containsKey('customer_phone')) {
      context.handle(
          _customerPhoneMeta,
          customerPhone.isAcceptableOrUnknown(
              data['customer_phone']!, _customerPhoneMeta));
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('grand_total')) {
      context.handle(
          _grandTotalMeta,
          grandTotal.isAcceptableOrUnknown(
              data['grand_total']!, _grandTotalMeta));
    } else if (isInserting) {
      context.missing(_grandTotalMeta);
    }
    if (data.containsKey('paid')) {
      context.handle(
          _paidMeta, paid.isAcceptableOrUnknown(data['paid']!, _paidMeta));
    } else if (isInserting) {
      context.missing(_paidMeta);
    }
    if (data.containsKey('debt')) {
      context.handle(
          _debtMeta, debt.isAcceptableOrUnknown(data['debt']!, _debtMeta));
    } else if (isInserting) {
      context.missing(_debtMeta);
    }
    if (data.containsKey('pay_type')) {
      context.handle(_payTypeMeta,
          payType.isAcceptableOrUnknown(data['pay_type']!, _payTypeMeta));
    } else if (isInserting) {
      context.missing(_payTypeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('shop_name')) {
      context.handle(_shopNameMeta,
          shopName.isAcceptableOrUnknown(data['shop_name']!, _shopNameMeta));
    } else if (isInserting) {
      context.missing(_shopNameMeta);
    }
    if (data.containsKey('shop_logo_path')) {
      context.handle(
          _shopLogoPathMeta,
          shopLogoPath.isAcceptableOrUnknown(
              data['shop_logo_path']!, _shopLogoPathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Invoice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Invoice(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      num: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}num'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name'])!,
      customerPhone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_phone']),
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      grandTotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}grand_total'])!,
      paid: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid'])!,
      debt: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}debt'])!,
      payType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pay_type'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      shopName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shop_name'])!,
      shopLogoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shop_logo_path']),
    );
  }

  @override
  $InvoicesTable createAlias(String alias) {
    return $InvoicesTable(attachedDatabase, alias);
  }
}

class Invoice extends DataClass implements Insertable<Invoice> {
  final String id;
  final int num;
  final DateTime date;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final double paid;
  final double debt;
  final String payType;
  final String? note;
  final String status;
  final String shopName;
  final String? shopLogoPath;
  const Invoice(
      {required this.id,
      required this.num,
      required this.date,
      this.customerId,
      required this.customerName,
      this.customerPhone,
      required this.subtotal,
      required this.discount,
      required this.grandTotal,
      required this.paid,
      required this.debt,
      required this.payType,
      this.note,
      required this.status,
      required this.shopName,
      this.shopLogoPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['num'] = Variable<int>(num);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['customer_name'] = Variable<String>(customerName);
    if (!nullToAbsent || customerPhone != null) {
      map['customer_phone'] = Variable<String>(customerPhone);
    }
    map['subtotal'] = Variable<double>(subtotal);
    map['discount'] = Variable<double>(discount);
    map['grand_total'] = Variable<double>(grandTotal);
    map['paid'] = Variable<double>(paid);
    map['debt'] = Variable<double>(debt);
    map['pay_type'] = Variable<String>(payType);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['status'] = Variable<String>(status);
    map['shop_name'] = Variable<String>(shopName);
    if (!nullToAbsent || shopLogoPath != null) {
      map['shop_logo_path'] = Variable<String>(shopLogoPath);
    }
    return map;
  }

  InvoicesCompanion toCompanion(bool nullToAbsent) {
    return InvoicesCompanion(
      id: Value(id),
      num: Value(num),
      date: Value(date),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: Value(customerName),
      customerPhone: customerPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(customerPhone),
      subtotal: Value(subtotal),
      discount: Value(discount),
      grandTotal: Value(grandTotal),
      paid: Value(paid),
      debt: Value(debt),
      payType: Value(payType),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      status: Value(status),
      shopName: Value(shopName),
      shopLogoPath: shopLogoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(shopLogoPath),
    );
  }

  factory Invoice.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Invoice(
      id: serializer.fromJson<String>(json['id']),
      num: serializer.fromJson<int>(json['num']),
      date: serializer.fromJson<DateTime>(json['date']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
      customerPhone: serializer.fromJson<String?>(json['customerPhone']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discount: serializer.fromJson<double>(json['discount']),
      grandTotal: serializer.fromJson<double>(json['grandTotal']),
      paid: serializer.fromJson<double>(json['paid']),
      debt: serializer.fromJson<double>(json['debt']),
      payType: serializer.fromJson<String>(json['payType']),
      note: serializer.fromJson<String?>(json['note']),
      status: serializer.fromJson<String>(json['status']),
      shopName: serializer.fromJson<String>(json['shopName']),
      shopLogoPath: serializer.fromJson<String?>(json['shopLogoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'num': serializer.toJson<int>(num),
      'date': serializer.toJson<DateTime>(date),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String>(customerName),
      'customerPhone': serializer.toJson<String?>(customerPhone),
      'subtotal': serializer.toJson<double>(subtotal),
      'discount': serializer.toJson<double>(discount),
      'grandTotal': serializer.toJson<double>(grandTotal),
      'paid': serializer.toJson<double>(paid),
      'debt': serializer.toJson<double>(debt),
      'payType': serializer.toJson<String>(payType),
      'note': serializer.toJson<String?>(note),
      'status': serializer.toJson<String>(status),
      'shopName': serializer.toJson<String>(shopName),
      'shopLogoPath': serializer.toJson<String?>(shopLogoPath),
    };
  }

  Invoice copyWith(
          {String? id,
          int? num,
          DateTime? date,
          Value<String?> customerId = const Value.absent(),
          String? customerName,
          Value<String?> customerPhone = const Value.absent(),
          double? subtotal,
          double? discount,
          double? grandTotal,
          double? paid,
          double? debt,
          String? payType,
          Value<String?> note = const Value.absent(),
          String? status,
          String? shopName,
          Value<String?> shopLogoPath = const Value.absent()}) =>
      Invoice(
        id: id ?? this.id,
        num: num ?? this.num,
        date: date ?? this.date,
        customerId: customerId.present ? customerId.value : this.customerId,
        customerName: customerName ?? this.customerName,
        customerPhone:
            customerPhone.present ? customerPhone.value : this.customerPhone,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        grandTotal: grandTotal ?? this.grandTotal,
        paid: paid ?? this.paid,
        debt: debt ?? this.debt,
        payType: payType ?? this.payType,
        note: note.present ? note.value : this.note,
        status: status ?? this.status,
        shopName: shopName ?? this.shopName,
        shopLogoPath:
            shopLogoPath.present ? shopLogoPath.value : this.shopLogoPath,
      );
  Invoice copyWithCompanion(InvoicesCompanion data) {
    return Invoice(
      id: data.id.present ? data.id.value : this.id,
      num: data.num.present ? data.num.value : this.num,
      date: data.date.present ? data.date.value : this.date,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
      customerPhone: data.customerPhone.present
          ? data.customerPhone.value
          : this.customerPhone,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discount: data.discount.present ? data.discount.value : this.discount,
      grandTotal:
          data.grandTotal.present ? data.grandTotal.value : this.grandTotal,
      paid: data.paid.present ? data.paid.value : this.paid,
      debt: data.debt.present ? data.debt.value : this.debt,
      payType: data.payType.present ? data.payType.value : this.payType,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      shopName: data.shopName.present ? data.shopName.value : this.shopName,
      shopLogoPath: data.shopLogoPath.present
          ? data.shopLogoPath.value
          : this.shopLogoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Invoice(')
          ..write('id: $id, ')
          ..write('num: $num, ')
          ..write('date: $date, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('paid: $paid, ')
          ..write('debt: $debt, ')
          ..write('payType: $payType, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('shopName: $shopName, ')
          ..write('shopLogoPath: $shopLogoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      num,
      date,
      customerId,
      customerName,
      customerPhone,
      subtotal,
      discount,
      grandTotal,
      paid,
      debt,
      payType,
      note,
      status,
      shopName,
      shopLogoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Invoice &&
          other.id == this.id &&
          other.num == this.num &&
          other.date == this.date &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName &&
          other.customerPhone == this.customerPhone &&
          other.subtotal == this.subtotal &&
          other.discount == this.discount &&
          other.grandTotal == this.grandTotal &&
          other.paid == this.paid &&
          other.debt == this.debt &&
          other.payType == this.payType &&
          other.note == this.note &&
          other.status == this.status &&
          other.shopName == this.shopName &&
          other.shopLogoPath == this.shopLogoPath);
}

class InvoicesCompanion extends UpdateCompanion<Invoice> {
  final Value<String> id;
  final Value<int> num;
  final Value<DateTime> date;
  final Value<String?> customerId;
  final Value<String> customerName;
  final Value<String?> customerPhone;
  final Value<double> subtotal;
  final Value<double> discount;
  final Value<double> grandTotal;
  final Value<double> paid;
  final Value<double> debt;
  final Value<String> payType;
  final Value<String?> note;
  final Value<String> status;
  final Value<String> shopName;
  final Value<String?> shopLogoPath;
  final Value<int> rowid;
  const InvoicesCompanion({
    this.id = const Value.absent(),
    this.num = const Value.absent(),
    this.date = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.customerPhone = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.paid = const Value.absent(),
    this.debt = const Value.absent(),
    this.payType = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.shopName = const Value.absent(),
    this.shopLogoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvoicesCompanion.insert({
    required String id,
    required int num,
    required DateTime date,
    this.customerId = const Value.absent(),
    required String customerName,
    this.customerPhone = const Value.absent(),
    required double subtotal,
    this.discount = const Value.absent(),
    required double grandTotal,
    required double paid,
    required double debt,
    required String payType,
    this.note = const Value.absent(),
    required String status,
    required String shopName,
    this.shopLogoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        num = Value(num),
        date = Value(date),
        customerName = Value(customerName),
        subtotal = Value(subtotal),
        grandTotal = Value(grandTotal),
        paid = Value(paid),
        debt = Value(debt),
        payType = Value(payType),
        status = Value(status),
        shopName = Value(shopName);
  static Insertable<Invoice> custom({
    Expression<String>? id,
    Expression<int>? num,
    Expression<DateTime>? date,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<String>? customerPhone,
    Expression<double>? subtotal,
    Expression<double>? discount,
    Expression<double>? grandTotal,
    Expression<double>? paid,
    Expression<double>? debt,
    Expression<String>? payType,
    Expression<String>? note,
    Expression<String>? status,
    Expression<String>? shopName,
    Expression<String>? shopLogoPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (num != null) 'num': num,
      if (date != null) 'date': date,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (subtotal != null) 'subtotal': subtotal,
      if (discount != null) 'discount': discount,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (paid != null) 'paid': paid,
      if (debt != null) 'debt': debt,
      if (payType != null) 'pay_type': payType,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (shopName != null) 'shop_name': shopName,
      if (shopLogoPath != null) 'shop_logo_path': shopLogoPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvoicesCompanion copyWith(
      {Value<String>? id,
      Value<int>? num,
      Value<DateTime>? date,
      Value<String?>? customerId,
      Value<String>? customerName,
      Value<String?>? customerPhone,
      Value<double>? subtotal,
      Value<double>? discount,
      Value<double>? grandTotal,
      Value<double>? paid,
      Value<double>? debt,
      Value<String>? payType,
      Value<String?>? note,
      Value<String>? status,
      Value<String>? shopName,
      Value<String?>? shopLogoPath,
      Value<int>? rowid}) {
    return InvoicesCompanion(
      id: id ?? this.id,
      num: num ?? this.num,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      paid: paid ?? this.paid,
      debt: debt ?? this.debt,
      payType: payType ?? this.payType,
      note: note ?? this.note,
      status: status ?? this.status,
      shopName: shopName ?? this.shopName,
      shopLogoPath: shopLogoPath ?? this.shopLogoPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (num.present) {
      map['num'] = Variable<int>(num.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
    }
    if (customerPhone.present) {
      map['customer_phone'] = Variable<String>(customerPhone.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<double>(grandTotal.value);
    }
    if (paid.present) {
      map['paid'] = Variable<double>(paid.value);
    }
    if (debt.present) {
      map['debt'] = Variable<double>(debt.value);
    }
    if (payType.present) {
      map['pay_type'] = Variable<String>(payType.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (shopName.present) {
      map['shop_name'] = Variable<String>(shopName.value);
    }
    if (shopLogoPath.present) {
      map['shop_logo_path'] = Variable<String>(shopLogoPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoicesCompanion(')
          ..write('id: $id, ')
          ..write('num: $num, ')
          ..write('date: $date, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
          ..write('customerPhone: $customerPhone, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('paid: $paid, ')
          ..write('debt: $debt, ')
          ..write('payType: $payType, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('shopName: $shopName, ')
          ..write('shopLogoPath: $shopLogoPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvoiceItemsTable extends InvoiceItems
    with TableInfo<$InvoiceItemsTable, InvoiceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvoiceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  @override
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
      'qty', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitPriceMeta =
      const VerificationMeta('unitPrice');
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
      'unit_price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _priceTypeMeta =
      const VerificationMeta('priceType');
  @override
  late final GeneratedColumn<String> priceType = GeneratedColumn<String>(
      'price_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<double> total = GeneratedColumn<double>(
      'total', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, invoiceId, productName, unit, qty, unitPrice, priceType, total];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'invoice_items';
  @override
  VerificationContext validateIntegrity(Insertable<InvoiceItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
          _qtyMeta, qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta));
    } else if (isInserting) {
      context.missing(_qtyMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(_unitPriceMeta,
          unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta));
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('price_type')) {
      context.handle(_priceTypeMeta,
          priceType.isAcceptableOrUnknown(data['price_type']!, _priceTypeMeta));
    } else if (isInserting) {
      context.missing(_priceTypeMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvoiceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvoiceItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      qty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}qty'])!,
      unitPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_price'])!,
      priceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}price_type'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total'])!,
    );
  }

  @override
  $InvoiceItemsTable createAlias(String alias) {
    return $InvoiceItemsTable(attachedDatabase, alias);
  }
}

class InvoiceItem extends DataClass implements Insertable<InvoiceItem> {
  final int id;
  final String invoiceId;
  final String productName;
  final String unit;
  final double qty;
  final double unitPrice;
  final String priceType;
  final double total;
  const InvoiceItem(
      {required this.id,
      required this.invoiceId,
      required this.productName,
      required this.unit,
      required this.qty,
      required this.unitPrice,
      required this.priceType,
      required this.total});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['product_name'] = Variable<String>(productName);
    map['unit'] = Variable<String>(unit);
    map['qty'] = Variable<double>(qty);
    map['unit_price'] = Variable<double>(unitPrice);
    map['price_type'] = Variable<String>(priceType);
    map['total'] = Variable<double>(total);
    return map;
  }

  InvoiceItemsCompanion toCompanion(bool nullToAbsent) {
    return InvoiceItemsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      productName: Value(productName),
      unit: Value(unit),
      qty: Value(qty),
      unitPrice: Value(unitPrice),
      priceType: Value(priceType),
      total: Value(total),
    );
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvoiceItem(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      productName: serializer.fromJson<String>(json['productName']),
      unit: serializer.fromJson<String>(json['unit']),
      qty: serializer.fromJson<double>(json['qty']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      priceType: serializer.fromJson<String>(json['priceType']),
      total: serializer.fromJson<double>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'productName': serializer.toJson<String>(productName),
      'unit': serializer.toJson<String>(unit),
      'qty': serializer.toJson<double>(qty),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'priceType': serializer.toJson<String>(priceType),
      'total': serializer.toJson<double>(total),
    };
  }

  InvoiceItem copyWith(
          {int? id,
          String? invoiceId,
          String? productName,
          String? unit,
          double? qty,
          double? unitPrice,
          String? priceType,
          double? total}) =>
      InvoiceItem(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        productName: productName ?? this.productName,
        unit: unit ?? this.unit,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        priceType: priceType ?? this.priceType,
        total: total ?? this.total,
      );
  InvoiceItem copyWithCompanion(InvoiceItemsCompanion data) {
    return InvoiceItem(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      unit: data.unit.present ? data.unit.value : this.unit,
      qty: data.qty.present ? data.qty.value : this.qty,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      priceType: data.priceType.present ? data.priceType.value : this.priceType,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItem(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productName: $productName, ')
          ..write('unit: $unit, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('priceType: $priceType, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, invoiceId, productName, unit, qty, unitPrice, priceType, total);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvoiceItem &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.productName == this.productName &&
          other.unit == this.unit &&
          other.qty == this.qty &&
          other.unitPrice == this.unitPrice &&
          other.priceType == this.priceType &&
          other.total == this.total);
}

class InvoiceItemsCompanion extends UpdateCompanion<InvoiceItem> {
  final Value<int> id;
  final Value<String> invoiceId;
  final Value<String> productName;
  final Value<String> unit;
  final Value<double> qty;
  final Value<double> unitPrice;
  final Value<String> priceType;
  final Value<double> total;
  const InvoiceItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productName = const Value.absent(),
    this.unit = const Value.absent(),
    this.qty = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.priceType = const Value.absent(),
    this.total = const Value.absent(),
  });
  InvoiceItemsCompanion.insert({
    this.id = const Value.absent(),
    required String invoiceId,
    required String productName,
    required String unit,
    required double qty,
    required double unitPrice,
    required String priceType,
    required double total,
  })  : invoiceId = Value(invoiceId),
        productName = Value(productName),
        unit = Value(unit),
        qty = Value(qty),
        unitPrice = Value(unitPrice),
        priceType = Value(priceType),
        total = Value(total);
  static Insertable<InvoiceItem> custom({
    Expression<int>? id,
    Expression<String>? invoiceId,
    Expression<String>? productName,
    Expression<String>? unit,
    Expression<double>? qty,
    Expression<double>? unitPrice,
    Expression<String>? priceType,
    Expression<double>? total,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productName != null) 'product_name': productName,
      if (unit != null) 'unit': unit,
      if (qty != null) 'qty': qty,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (priceType != null) 'price_type': priceType,
      if (total != null) 'total': total,
    });
  }

  InvoiceItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? invoiceId,
      Value<String>? productName,
      Value<String>? unit,
      Value<double>? qty,
      Value<double>? unitPrice,
      Value<String>? priceType,
      Value<double>? total}) {
    return InvoiceItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productName: productName ?? this.productName,
      unit: unit ?? this.unit,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      priceType: priceType ?? this.priceType,
      total: total ?? this.total,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (priceType.present) {
      map['price_type'] = Variable<String>(priceType.value);
    }
    if (total.present) {
      map['total'] = Variable<double>(total.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvoiceItemsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productName: $productName, ')
          ..write('unit: $unit, ')
          ..write('qty: $qty, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('priceType: $priceType, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $InvoicesTable invoices = $InvoicesTable(this);
  late final $InvoiceItemsTable invoiceItems = $InvoiceItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [products, customers, invoices, invoiceItems];
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  Value<String?> barcode,
  required String name,
  required String unit,
  required double retailPrice,
  Value<double?> wholesalePrice,
  Value<double?> stock,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String?> barcode,
  Value<String> name,
  Value<String> unit,
  Value<double> retailPrice,
  Value<double?> wholesalePrice,
  Value<double?> stock,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get retailPrice => $composableBuilder(
      column: $table.retailPrice, builder: (column) => column);

  GeneratedColumn<double> get wholesalePrice => $composableBuilder(
      column: $table.wholesalePrice, builder: (column) => column);

  GeneratedColumn<double> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> retailPrice = const Value.absent(),
            Value<double?> wholesalePrice = const Value.absent(),
            Value<double?> stock = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            barcode: barcode,
            name: name,
            unit: unit,
            retailPrice: retailPrice,
            wholesalePrice: wholesalePrice,
            stock: stock,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> barcode = const Value.absent(),
            required String name,
            required String unit,
            required double retailPrice,
            Value<double?> wholesalePrice = const Value.absent(),
            Value<double?> stock = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            barcode: barcode,
            name: name,
            unit: unit,
            retailPrice: retailPrice,
            wholesalePrice: wholesalePrice,
            stock: stock,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    Product,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
    Product,
    PrefetchHooks Function()>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String name,
  Value<String?> phone,
  Value<double> totalDebt,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> phone,
  Value<double> totalDebt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDebt => $composableBuilder(
      column: $table.totalDebt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDebt => $composableBuilder(
      column: $table.totalDebt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<double> get totalDebt =>
      $composableBuilder(column: $table.totalDebt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<double> totalDebt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            totalDebt: totalDebt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<double> totalDebt = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            totalDebt: totalDebt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    Customer,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (Customer, BaseReferences<_$AppDatabase, $CustomersTable, Customer>),
    Customer,
    PrefetchHooks Function()>;
typedef $$InvoicesTableCreateCompanionBuilder = InvoicesCompanion Function({
  required String id,
  required int num,
  required DateTime date,
  Value<String?> customerId,
  required String customerName,
  Value<String?> customerPhone,
  required double subtotal,
  Value<double> discount,
  required double grandTotal,
  required double paid,
  required double debt,
  required String payType,
  Value<String?> note,
  required String status,
  required String shopName,
  Value<String?> shopLogoPath,
  Value<int> rowid,
});
typedef $$InvoicesTableUpdateCompanionBuilder = InvoicesCompanion Function({
  Value<String> id,
  Value<int> num,
  Value<DateTime> date,
  Value<String?> customerId,
  Value<String> customerName,
  Value<String?> customerPhone,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> grandTotal,
  Value<double> paid,
  Value<double> debt,
  Value<String> payType,
  Value<String?> note,
  Value<String> status,
  Value<String> shopName,
  Value<String?> shopLogoPath,
  Value<int> rowid,
});

class $$InvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get num => $composableBuilder(
      column: $table.num, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get grandTotal => $composableBuilder(
      column: $table.grandTotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paid => $composableBuilder(
      column: $table.paid, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get debt => $composableBuilder(
      column: $table.debt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payType => $composableBuilder(
      column: $table.payType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shopName => $composableBuilder(
      column: $table.shopName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shopLogoPath => $composableBuilder(
      column: $table.shopLogoPath, builder: (column) => ColumnFilters(column));
}

class $$InvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get num => $composableBuilder(
      column: $table.num, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get grandTotal => $composableBuilder(
      column: $table.grandTotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paid => $composableBuilder(
      column: $table.paid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get debt => $composableBuilder(
      column: $table.debt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payType => $composableBuilder(
      column: $table.payType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shopName => $composableBuilder(
      column: $table.shopName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shopLogoPath => $composableBuilder(
      column: $table.shopLogoPath,
      builder: (column) => ColumnOrderings(column));
}

class $$InvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoicesTable> {
  $$InvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get num =>
      $composableBuilder(column: $table.num, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);

  GeneratedColumn<String> get customerPhone => $composableBuilder(
      column: $table.customerPhone, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get grandTotal => $composableBuilder(
      column: $table.grandTotal, builder: (column) => column);

  GeneratedColumn<double> get paid =>
      $composableBuilder(column: $table.paid, builder: (column) => column);

  GeneratedColumn<double> get debt =>
      $composableBuilder(column: $table.debt, builder: (column) => column);

  GeneratedColumn<String> get payType =>
      $composableBuilder(column: $table.payType, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get shopName =>
      $composableBuilder(column: $table.shopName, builder: (column) => column);

  GeneratedColumn<String> get shopLogoPath => $composableBuilder(
      column: $table.shopLogoPath, builder: (column) => column);
}

class $$InvoicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvoicesTable,
    Invoice,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (Invoice, BaseReferences<_$AppDatabase, $InvoicesTable, Invoice>),
    Invoice,
    PrefetchHooks Function()> {
  $$InvoicesTableTableManager(_$AppDatabase db, $InvoicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> num = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String?> customerId = const Value.absent(),
            Value<String> customerName = const Value.absent(),
            Value<String?> customerPhone = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> grandTotal = const Value.absent(),
            Value<double> paid = const Value.absent(),
            Value<double> debt = const Value.absent(),
            Value<String> payType = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> shopName = const Value.absent(),
            Value<String?> shopLogoPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion(
            id: id,
            num: num,
            date: date,
            customerId: customerId,
            customerName: customerName,
            customerPhone: customerPhone,
            subtotal: subtotal,
            discount: discount,
            grandTotal: grandTotal,
            paid: paid,
            debt: debt,
            payType: payType,
            note: note,
            status: status,
            shopName: shopName,
            shopLogoPath: shopLogoPath,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int num,
            required DateTime date,
            Value<String?> customerId = const Value.absent(),
            required String customerName,
            Value<String?> customerPhone = const Value.absent(),
            required double subtotal,
            Value<double> discount = const Value.absent(),
            required double grandTotal,
            required double paid,
            required double debt,
            required String payType,
            Value<String?> note = const Value.absent(),
            required String status,
            required String shopName,
            Value<String?> shopLogoPath = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InvoicesCompanion.insert(
            id: id,
            num: num,
            date: date,
            customerId: customerId,
            customerName: customerName,
            customerPhone: customerPhone,
            subtotal: subtotal,
            discount: discount,
            grandTotal: grandTotal,
            paid: paid,
            debt: debt,
            payType: payType,
            note: note,
            status: status,
            shopName: shopName,
            shopLogoPath: shopLogoPath,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InvoicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvoicesTable,
    Invoice,
    $$InvoicesTableFilterComposer,
    $$InvoicesTableOrderingComposer,
    $$InvoicesTableAnnotationComposer,
    $$InvoicesTableCreateCompanionBuilder,
    $$InvoicesTableUpdateCompanionBuilder,
    (Invoice, BaseReferences<_$AppDatabase, $InvoicesTable, Invoice>),
    Invoice,
    PrefetchHooks Function()>;
typedef $$InvoiceItemsTableCreateCompanionBuilder = InvoiceItemsCompanion
    Function({
  Value<int> id,
  required String invoiceId,
  required String productName,
  required String unit,
  required double qty,
  required double unitPrice,
  required String priceType,
  required double total,
});
typedef $$InvoiceItemsTableUpdateCompanionBuilder = InvoiceItemsCompanion
    Function({
  Value<int> id,
  Value<String> invoiceId,
  Value<String> productName,
  Value<String> unit,
  Value<double> qty,
  Value<double> unitPrice,
  Value<String> priceType,
  Value<double> total,
});

class $$InvoiceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceId => $composableBuilder(
      column: $table.invoiceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priceType => $composableBuilder(
      column: $table.priceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));
}

class $$InvoiceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceId => $composableBuilder(
      column: $table.invoiceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qty => $composableBuilder(
      column: $table.qty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitPrice => $composableBuilder(
      column: $table.unitPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priceType => $composableBuilder(
      column: $table.priceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));
}

class $$InvoiceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvoiceItemsTable> {
  $$InvoiceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceId =>
      $composableBuilder(column: $table.invoiceId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get priceType =>
      $composableBuilder(column: $table.priceType, builder: (column) => column);

  GeneratedColumn<double> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);
}

class $$InvoiceItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InvoiceItemsTable,
    InvoiceItem,
    $$InvoiceItemsTableFilterComposer,
    $$InvoiceItemsTableOrderingComposer,
    $$InvoiceItemsTableAnnotationComposer,
    $$InvoiceItemsTableCreateCompanionBuilder,
    $$InvoiceItemsTableUpdateCompanionBuilder,
    (
      InvoiceItem,
      BaseReferences<_$AppDatabase, $InvoiceItemsTable, InvoiceItem>
    ),
    InvoiceItem,
    PrefetchHooks Function()> {
  $$InvoiceItemsTableTableManager(_$AppDatabase db, $InvoiceItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvoiceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvoiceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvoiceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> invoiceId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double> qty = const Value.absent(),
            Value<double> unitPrice = const Value.absent(),
            Value<String> priceType = const Value.absent(),
            Value<double> total = const Value.absent(),
          }) =>
              InvoiceItemsCompanion(
            id: id,
            invoiceId: invoiceId,
            productName: productName,
            unit: unit,
            qty: qty,
            unitPrice: unitPrice,
            priceType: priceType,
            total: total,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String invoiceId,
            required String productName,
            required String unit,
            required double qty,
            required double unitPrice,
            required String priceType,
            required double total,
          }) =>
              InvoiceItemsCompanion.insert(
            id: id,
            invoiceId: invoiceId,
            productName: productName,
            unit: unit,
            qty: qty,
            unitPrice: unitPrice,
            priceType: priceType,
            total: total,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InvoiceItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InvoiceItemsTable,
    InvoiceItem,
    $$InvoiceItemsTableFilterComposer,
    $$InvoiceItemsTableOrderingComposer,
    $$InvoiceItemsTableAnnotationComposer,
    $$InvoiceItemsTableCreateCompanionBuilder,
    $$InvoiceItemsTableUpdateCompanionBuilder,
    (
      InvoiceItem,
      BaseReferences<_$AppDatabase, $InvoiceItemsTable, InvoiceItem>
    ),
    InvoiceItem,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db, _db.invoices);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db, _db.invoiceItems);
}
