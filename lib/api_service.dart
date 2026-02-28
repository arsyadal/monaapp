import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getTransactions() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/transactions'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<void> createTransaction(Map<String, dynamic> transaction) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: headers,
      body: json.encode(transaction),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create transaction');
    }
  }

  Future<void> updateTransaction(Map<String, dynamic> transaction) async {
    final id = transaction['id'];
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: headers,
      body: json.encode(transaction),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update transaction');
    }
  }

  Future<void> deleteTransaction(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction');
    }
  }

  Future<List<dynamic>> getCategories() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/categories'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> createCategory(Map<String, dynamic> category) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: headers,
      body: json.encode(category),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create category');
    }
  }

  Future<List<dynamic>> getAccounts() async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/accounts'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load accounts');
    }
  }

  Future<void> createAccount(Map<String, dynamic> account) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/accounts'),
      headers: headers,
      body: json.encode(account),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create account');
    }
  }

  Future<void> updateAccount(Map<String, dynamic> account) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/accounts/${account['id']}'),
      headers: headers,
      body: json.encode(account),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update account');
    }
  }

  Future<void> deleteAccount(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/accounts/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete account');
    }
  }

  Future<void> deleteCategory(String id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category');
    }
  }
}