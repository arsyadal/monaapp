import 'package:mysql1/mysql1.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<MySqlConnection> _getConnection() async {
    final settings = ConnectionSettings(
      host: '192.168.100.7', // Ganti dengan alamat host Anda
      port: 3306, // Ganti dengan port server Anda
      user: 'root', // Ganti dengan username Anda
      password: 'root', // Ganti dengan password Anda
      db: 'test', // Ganti dengan nama database Anda
    );
    return await MySqlConnection.connect(settings);
  }

  Future<void> createTables() async {
    final conn = await _getConnection();
    await conn.query('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type VARCHAR(50),
        date DATE,
        amount DECIMAL(10, 2),
        category VARCHAR(50),
        account VARCHAR(50),
        note TEXT
      )
    ''');
    await conn.query('''
      CREATE TABLE IF NOT EXISTS categories (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(50)
      )
    ''');
    await conn.query('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        type VARCHAR(50)
      )
    ''');
    await conn.close();
  }

  Future<void> insertData(String table, Map<String, dynamic> data) async {
    final conn = await _getConnection();
    final fields = data.keys.join(', ');
    final values = data.values.map((value) => '?').join(', ');
    final result = await conn.query('INSERT INTO $table ($fields) VALUES ($values)', data.values.toList());
    print('Inserted row id: ${result.insertId}');
    await conn.close();
  }

  Future<List<Map<String, dynamic>>> getData(String table) async {
    final conn = await _getConnection();
    final results = await conn.query('SELECT * FROM $table');
    final data = results.map((row) => row.fields).toList();
    await conn.close();
    return data;
  }
}