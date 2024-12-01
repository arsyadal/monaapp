import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Impor untuk TextInputFormatter dan FilteringTextInputFormatter
import 'package:intl/intl.dart'; // Impor untuk NumberFormat

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  String _selectedAccountType = 'Bank'; // Default account type
  final TextEditingController _amountController = TextEditingController();
  final List<Map<String, String>> _accounts =
      []; // Daftar untuk menyimpan data akun

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
                      items: <String>['Bank', 'Cash']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
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
                  onPressed: () {
                    setState(() {
                      _accounts.add({
                        'type': _selectedAccountType,
                        'amount': _amountController.text,
                      });
                    });
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
