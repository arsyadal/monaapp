import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'database.g.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get account => text()();
  TextColumn get note => text().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
}

@DriftDatabase(tables: [Transactions, Categories, Accounts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<List<Transaction>> getAllTransactions() => select(transactions).get();
  Future<List<Category>> getAllCategories() => select(categories).get();
  Future<List<Account>> getAllAccounts() => select(accounts).get();

  Future<int> insertTransaction(Insertable<Transaction> transaction) => into(transactions).insert(transaction);
  Future<int> insertCategory(Insertable<Category> category) => into(categories).insert(category);
  Future<int> insertAccount(Insertable<Account> account) => into(accounts).insert(account);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.sqlite'));
    return NativeDatabase(file);
  });
}