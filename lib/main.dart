import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Impor untuk TextInputFormatter dan FilteringTextInputFormatter
import 'package:intl/intl.dart'; // Impor untuk NumberFormat
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'accounts_page.dart'; // Impor AccountsPage

void main() async {
  // Inisialisasi Hive
  await Hive.initFlutter();
  await Hive.openBox('transactions');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int _selectedIndex = 0;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _transactionType = 'Expense'; // Default transaction type
  final List<Map<String, String>> _transactions = [];
  final Box _transactionBox = Hive.box('transactions');

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toLocal().toString().split(' ')[0]; // Set initial date to today
    _loadTransactions();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _loadTransactions() async {
    final data = _transactionBox.values.toList();
    setState(() {
      _transactions.clear();
      _transactions.addAll(data.cast<Map<String, String>>());
      print('Transactions loaded: $_transactions'); // Log untuk memastikan data dimuat
    });
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Transaction'),
              content: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _transactionType == 'Expense' ? Colors.red : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _transactionType = 'Expense';
                            });
                          },
                          child: const Text('Expense'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _transactionType == 'Income' ? Colors.green : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _transactionType = 'Income';
                            });
                          },
                          child: const Text('Income'),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
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
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                    ),
                    TextField(
                      controller: _accountController,
                      decoration: const InputDecoration(
                        labelText: 'Account',
                      ),
                    ),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                      ),
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
                    final transaction = {
                      'type': _transactionType,
                      'date': _dateController.text,
                      'amount': _amountController.text,
                      'category': _categoryController.text,
                      'account': _accountController.text,
                      'note': _noteController.text,
                    };
                    await _transactionBox.add(transaction);
                    print('Transaction saved: $transaction'); // Log untuk memastikan data disimpan
                    await _loadTransactions(); // Muat ulang data setelah menyimpan transaksi baru
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

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return ListView.builder(
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            final color = transaction['type'] == 'Expense' ? Colors.red : Colors.green;
            return ListTile(
              title: Text(
                '${transaction['type']} - ${transaction['amount']}',
                style: TextStyle(color: color),
              ),
              subtitle: Text('${transaction['date']} - ${transaction['category']} - ${transaction['account']}'),
              trailing: Text(transaction['note'] ?? ''),
            );
          },
        );
      case 1:
        return const AccountsPage(); // Gunakan AccountsPage di sini
      case 2:
        return const Center(child: Text('Summary Page'));
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddTransactionDialog,
              tooltip: 'Add Transaction',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Summary',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('en');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int selectionIndex = newValue.selection.end;
    final String formattedText = _formatter.format(int.parse(newValue.text.replaceAll(',', '')));
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}