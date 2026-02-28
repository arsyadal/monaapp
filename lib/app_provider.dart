import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppProvider with ChangeNotifier {
  bool _isDarkMode = false;
  String _currency = 'Rp';
  String? _token;
  bool _usePin = false;
  String? _pinCode;

  bool get isDarkMode => _isDarkMode;
  String get currency => _currency;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get usePin => _usePin;
  String? get pinCode => _pinCode;

  double get exchangeRate {
    switch (_currency) {
      case '\$':
        return 1 / 16000.0;
      case '€':
        return 1 / 17500.0;
      case '£':
        return 1 / 20000.0;
      case 'Rp':
      default:
        return 1.0;
    }
  }

  double convert(double amount) {
    if (_currency == 'Rp') return amount;
    return amount * exchangeRate;
  }

  int convertToBase(double amount) {
    if (_currency == 'Rp') return amount.round();
    return (amount / exchangeRate).round();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _currency = prefs.getString('currency') ?? 'Rp';
    _token = prefs.getString('auth_token');
    _usePin = prefs.getBool('use_pin') ?? false;
    _pinCode = prefs.getString('pin_code');
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  Future<void> setCurrency(String cu) async {
    _currency = cu;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', cu);
    notifyListeners();
  }

  Future<void> setToken(String? tk) async {
    _token = tk;
    final prefs = await SharedPreferences.getInstance();
    if (tk != null) {
      await prefs.setString('auth_token', tk);
    } else {
      await prefs.remove('auth_token');
    }
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    _usePin = true;
    _pinCode = pin;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_pin', true);
    await prefs.setString('pin_code', pin);
    notifyListeners();
  }

  Future<void> disablePin() async {
    _usePin = false;
    _pinCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_pin', false);
    await prefs.remove('pin_code');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        await setToken(data['token']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('http://localhost:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        await setToken(data['token']);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
