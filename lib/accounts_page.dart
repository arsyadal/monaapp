import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Impor untuk TextInputFormatter dan FilteringTextInputFormatter
import 'package:intl/intl.dart'; // Impor untuk NumberFormat
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  String _selectedAccountType = 'Bank'; // Default account type
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _newAccountTypeController = TextEditingController();
  final Box _transactionBox = Hive.box('transactions');
  final Box _accountBox = Hive.box('accounts');
  final List<String> _accountTypes = ['Bank', 'Cash']; // Daftar jenis akun yang tersedia

  final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US'); // Format untuk menambahkan koma setiap tiga angka

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatAmount);
  }

  void _formatAmount() {
    String text = _amountController.text.replaceAll(',', '');
    if (text.isNotEmpty) {
      _amountController.value = _amountController.value.copyWith(
        text: _numberFormat.format(int.parse(text)),
        selection: TextSelection.collapsed(offset: _numberFormat.format(int.parse(text)).length),
      );
    }
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Account'),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    DropdownButton<String>(
                      value: _selectedAccountType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedAccountType = newValue!;
                        });
                      },
                      items: _accountTypes.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _newAccountTypeController,
                      decoration: const InputDecoration(
                        labelText: 'New Account Type',
                      ),
                      onSubmitted: (String newAccountType) {
                        if (newAccountType.isNotEmpty && !_accountTypes.contains(newAccountType)) {
                          setState(() {
                            _accountTypes.add(newAccountType);
                            _selectedAccountType = newAccountType;
                            _newAccountTypeController.clear();
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: 'Rp. ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    final amount = int.parse(_amountController.text.replaceAll(',', ''));
                    final existingAccountIndex = _accountBox.values.toList().indexWhere((account) => account['type'] == _selectedAccountType);

                    if (existingAccountIndex != -1) {
                      // Akumulasi jumlah jika akun sudah ada
                      final existingAccount = _accountBox.getAt(existingAccountIndex);
                      existingAccount['amount'] = (int.parse(existingAccount['amount']) + amount).toString();
                      await _accountBox.putAt(existingAccountIndex, existingAccount);
                    } else {
                      // Tambahkan akun baru jika belum ada
                      final account = {
                        'type': _selectedAccountType,
                        'amount': amount.toString(),
                      };
                      await _accountBox.add(account);
                    }

                    _amountController.clear(); // Clear the controller

                    // Add the account as an income transaction
                    final transaction = {
                      'type': 'Income',
                      'date': DateTime.now().toLocal().toString().split(' ')[0],
                      'amount': amount.toString(),
                      'category': 'Account',
                      'account': _selectedAccountType,
                      'note': 'Initial deposit',
                    };
                    await _transactionBox.add(transaction);
                    print('Transaction saved: $transaction'); // Log untuk memastikan data disimpan

                    Navigator.of(context).pop();

                    // Tampilkan SnackBar
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account successfully created!')),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _calculateTotalBalance(Box accountBox) {
    int total = 0;
    for (var account in accountBox.values) {
      total += int.parse(account['amount'].replaceAll(',', ''));
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: _accountBox.listenable(),
        builder: (context, Box accountBox, _) {
          final totalBalance = _calculateTotalBalance(accountBox);
          final formattedTotalBalance = _numberFormat.format(totalBalance);

          return Column(
            children: [
              Card(
                color: Colors.red[900], // Background merah
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: const Text(
                    'Total Balance',
                    style: TextStyle(
                      color: Colors.white, // Warna teks putih
                      fontWeight: FontWeight.bold, // Teks tebal
                    ),
                  ),
                  subtitle: Text(
                    'Rp. $formattedTotalBalance',
                    style: const TextStyle(
                      color: Colors.white, // Warna teks putih
                      fontWeight: FontWeight.bold, // Teks tebal
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: accountBox.length,
                  itemBuilder: (context, index) {
                    final account = accountBox.getAt(index);
                    return ListTile(
                      title: Text('${account['type']} - ${_numberFormat.format(int.parse(account['amount']))}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red[900], // Warna tombol plus merah pekat
        onPressed: _showAddAccountDialog,
        tooltip: 'Add Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('en');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionIndex = newValue.selection.end;
    final String formattedText =
        _formatter.format(int.parse(newValue.text.replaceAll(',', '')));
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}