import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Impor untuk TextInputFormatter dan FilteringTextInputFormatter
import 'package:intl/intl.dart'; // Impor untuk NumberFormat
import 'package:hive/hive.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  String _selectedAccountType = 'Bank'; // Default account type
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _newAccountTypeController = TextEditingController();
  final List<Map<String, String>> _accounts = []; // Daftar untuk menyimpan data akun
  final Box _transactionBox = Hive.box('transactions');
  final Box _accountBox = Hive.box('accounts');
  final List<String> _accountTypes = ['Bank', 'Cash']; // Daftar jenis akun yang tersedia

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final data = _accountBox.values.toList();
    setState(() {
      _accounts.clear();
      _accounts.addAll(data.cast<Map<String, String>>());
      print('Accounts loaded: $_accounts'); // Log untuk memastikan data dimuat
    });
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
                    final existingAccountIndex = _accounts.indexWhere((account) => account['type'] == _selectedAccountType);

                    if (existingAccountIndex != -1) {
                      // Akumulasi jumlah jika akun sudah ada
                      setState(() {
                        _accounts[existingAccountIndex]['amount'] = (int.parse(_accounts[existingAccountIndex]['amount']!) + amount).toString();
                      });
                      await _accountBox.putAt(existingAccountIndex, _accounts[existingAccountIndex]);
                    } else {
                      // Tambahkan akun baru jika belum ada
                      final account = {
                        'type': _selectedAccountType,
                        'amount': amount.toString(),
                      };
                      setState(() {
                        _accounts.add(account);
                      });
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
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Page'),
      ),
      body: ListView.builder(
        itemCount: _accounts.length,
        itemBuilder: (context, index) {
          final account = _accounts[index];
          return ListTile(
            title: Text('${account['type']} - ${account['amount']}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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