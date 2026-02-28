import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'api_service.dart';
import 'accounts_page.dart';
import 'summary_page.dart';
import 'splash_screen.dart';
import 'settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = AppProvider();
  await provider.init();
  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MyApp(),
    ),
  );
}

const Color kPrimary = Color(0xFFE53935);
const Color kIncome = Color(0xFF00C853);
const Color kExpense = Color(0xFFFF1744);
const Color kBackground = Color(0xFFF0F2F8);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return MaterialApp(
      title: 'Monaapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimary,
          brightness: isDark ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : kBackground,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
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
  int _selectedIndex = 0;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _transactionType = 'Expense';
  List<Map<String, String>> _transactions = [];
  List<Map<String, String>> _categories = [];
  List<Map<String, String>> _accounts = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  final ApiService _apiService = ApiService();

  List<Map<String, String>> get _filteredTransactions {
    return _transactions.where((t) {
      if (t['date'] == null) return false;
      try {
        final parts = t['date']!.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          return year == _selectedMonth.year && month == _selectedMonth.month;
        }
      } catch (e) {
        return false;
      }
      return false;
    }).toList();
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
    });
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
    _loadTransactions();
    _loadCategories();
    _loadAccounts();
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kPrimary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await _apiService.getTransactions();
      setState(() {
        _transactions = data.map((item) {
          final m = item as Map<String, dynamic>;
          String dateStr = m['date']?.toString() ?? '';
          if (dateStr.length > 10) dateStr = dateStr.substring(0, 10);
          return {
            'id': m['id']?.toString() ?? '',
            'type': m['type']?.toString() ?? '',
            'date': dateStr,
            'amount': (m['amount'] as num?)?.toStringAsFixed(0) ?? '0',
            'category': m['category']?.toString() ?? '',
            'account': m['account']?.toString() ?? '',
            'note': m['note']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _apiService.getCategories();
      setState(() {
        _categories = data.map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'id': m['id']?.toString() ?? '',
            'name': m['name']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadAccounts() async {
    try {
      final data = await _apiService.getAccounts();
      setState(() {
        _accounts = data.map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'id': m['id']?.toString() ?? '',
            'type': m['type']?.toString() ?? '',
            'amount': (m['amount'] as num?)?.toStringAsFixed(0) ?? '0',
          };
        }).toList();
      });
    } catch (_) {}
  }

  void _showAddCategoryDialog(StateSetter setParentState) {
    final TextEditingController newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dContext) {
        final isDark = Provider.of<AppProvider>(dContext, listen: false).isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text('New Category', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          content: TextField(
            controller: newCategoryController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Category Name',
              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white30 : Colors.grey)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () async {
                if (newCategoryController.text.isNotEmpty) {
                  try {
                    await _apiService.createCategory({'name': newCategoryController.text});
                    await _loadCategories();
                    setParentState(() {
                      _categoryController.text = newCategoryController.text;
                    });
                    if (dContext.mounted) Navigator.pop(dContext);
                  } catch (e) {
                    if (dContext.mounted) {
                      ScaffoldMessenger.of(dContext).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showAddTransactionDialog({Map<String, String>? transactionToEdit}) async {
    // Selalu reload accounts & categories terbaru dari DB sebelum buka dialog
    await Future.wait([_loadAccounts(), _loadCategories()]);

    if (!mounted) return;

    final isEditing = transactionToEdit != null;

    if (isEditing) {
      _transactionType = transactionToEdit['type'] ?? 'Expense';
      _dateController.text = transactionToEdit['date'] ?? DateTime.now().toLocal().toString().split(' ')[0];

      final rawAmt = double.tryParse(transactionToEdit['amount'] ?? '0') ?? 0;
      final localAmt = Provider.of<AppProvider>(context, listen: false).convert(rawAmt);
      _amountController.text = NumberFormat.decimalPattern('en').format(localAmt);

      _categoryController.text = transactionToEdit['category'] ?? '';
      _accountController.text = transactionToEdit['account'] ?? '';
      _noteController.text = transactionToEdit['note'] ?? '';
    } else {
      _transactionType = 'Expense';
      _dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
      _amountController.clear();
      _noteController.clear();
      if (_categories.isNotEmpty) {
        _categoryController.text = _categories[0]['name'] ?? '';
      }
      if (_accounts.isNotEmpty) {
        _accountController.text = _accounts[0]['type'] ?? '';
      }
    }

    // Pastikan nilai dropdown valid di dalam options
    if (_categories.isNotEmpty && !_categories.any((c) => c['name'] == _categoryController.text)) {
      _categoryController.text = _categories[0]['name'] ?? '';
    }
    if (_accounts.isNotEmpty && !_accounts.any((a) => a['type'] == _accountController.text)) {
      _accountController.text = _accounts[0]['type'] ?? '';
    }

    if (_accounts.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('No Accounts'),
          content: const Text('Tambahkan akun terlebih dahulu di tab Accounts.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final isDark = context.read<AppProvider>().isDarkMode;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: kPrimary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add_circle_outline, color: kPrimary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Transaction',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (isEditing)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Delete Transaction?'),
                                    content: const Text('Are you sure you want to delete this transaction?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  try {
                                    await _apiService.deleteTransaction(transactionToEdit['id']!);
                                    await _loadTransactions();
                                    if (context.mounted) Navigator.of(context).pop();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                    }
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Type toggle
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _typeButton('Expense', kExpense, Icons.arrow_upward, setDialogState),
                            _typeButton('Income', kIncome, Icons.arrow_downward, setDialogState),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date
                      _dialogField(
                        controller: _dateController,
                        label: 'Date',
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 12),

                      // Amount
                      _dialogField(
                        controller: _amountController,
                        label: 'Amount',
                        icon: Icons.payments_outlined,
                        prefixText: '${Provider.of<AppProvider>(context, listen: false).currency} ',
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category dropdown
                      _dialogDropdown(
                        label: 'Category',
                        icon: Icons.category_outlined,
                        value: _categories.any((c) => c['name'] == _categoryController.text) 
                            ? _categoryController.text 
                            : null,
                        items: [..._categories.map((c) => c['name'] ?? ''), '+ Add New...'],
                        onChanged: (val) {
                          if (val == '+ Add New...') {
                            _showAddCategoryDialog(setDialogState);
                          } else {
                            setDialogState(() => _categoryController.text = val ?? '');
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Account dropdown
                      _dialogDropdown(
                        label: 'Account',
                        icon: Icons.account_balance_wallet_outlined,
                        value: _accountController.text.isNotEmpty ? _accountController.text : null,
                        items: _accounts.map((a) => a['type'] ?? '').toList(),
                        onChanged: (val) =>
                            setDialogState(() => _accountController.text = val ?? ''),
                      ),
                      const SizedBox(height: 12),

                      // Note
                      _dialogField(
                        controller: _noteController,
                        label: 'Note (optional)',
                        icon: Icons.note_outlined,
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_amountController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Amount tidak boleh kosong')),
                                  );
                                  return;
                                }
                                try {
                                  final localAmtStr = _amountController.text.replaceAll(',', '');
                                  final double localAmount = double.tryParse(localAmtStr) ?? 0;
                                  final int baseAmount = Provider.of<AppProvider>(context, listen: false).convertToBase(localAmount);

                                  final transaction = {
                                    'type': _transactionType,
                                    'date': _dateController.text,
                                    'amount': baseAmount.toString(),
                                    'category': _categoryController.text,
                                    'account': _accountController.text,
                                    'note': _noteController.text,
                                  };
                                  if (isEditing) {
                                    transaction['id'] = transactionToEdit['id']!;
                                    await _apiService.updateTransaction(transaction);
                                  } else {
                                    await _apiService.createTransaction(transaction);
                                  }
                                  await _loadTransactions();
                                  if (context.mounted) Navigator.of(context).pop();
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal simpan: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Save',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _typeButton(
      String type, Color color, IconData icon, StateSetter setDialogState) {
    final isSelected = _transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setDialogState(() => _transactionType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  size: 16),
              const SizedBox(width: 6),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dialogDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTransactionPage() {
    final formatter = NumberFormat.decimalPattern('id');
    final monthFormatter = DateFormat('MMMM yyyy');
    double totalIncome = 0;
    double totalExpenses = 0;
    
    final displayTransactions = _filteredTransactions;
    
    for (var t in displayTransactions) {
      final amount =
          double.tryParse(t['amount']?.replaceAll(',', '') ?? '0') ?? 0;
      if (t['type'] == 'Income') {
        totalIncome += amount;
      } else {
        totalExpenses += amount;
      }
    }
    final balance = totalIncome - totalExpenses;

    return Column(
      children: [
        // Balance header card
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('Total Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                '${context.watch<AppProvider>().currency} ${formatter.format(context.watch<AppProvider>().convert(balance))}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _summaryChip(
                      'Income', totalIncome, Colors.greenAccent.shade100, formatter),
                  Container(
                      width: 1, height: 36, color: Colors.white24),
                  _summaryChip(
                      'Expenses', totalExpenses, Colors.red.shade100, formatter),
                ],
              ),
            ],
          ),
        ),

        // Month Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: kPrimary),
                onPressed: () => _changeMonth(-1),
                style: IconButton.styleFrom(
                  backgroundColor: kPrimary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              Text(
                monthFormatter.format(_selectedMonth),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.watch<AppProvider>().isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: kPrimary),
                onPressed: () => _changeMonth(1),
                style: IconButton.styleFrom(
                  backgroundColor: kPrimary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),

        // Transactions list
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Transactions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.watch<AppProvider>().isDarkMode ? Colors.white : const Color(0xFF1A1A2E))),
              Text('${displayTransactions.length} items',
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 13)),
            ],
          ),
        ),

        Expanded(
          child: displayTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 80, color: kPrimary.withOpacity(0.1)),
                        const SizedBox(height: 24),
                        Text('No transactions yet',
                            style: TextStyle(
                                color: context.watch<AppProvider>().isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('No transactions for this month',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  itemCount: displayTransactions.length,
                  itemBuilder: (context, index) {
                    final t = displayTransactions[index];
                    final isExpense = t['type'] == 'Expense';
                    final color = isExpense ? kExpense : kIncome;
                    final amount = double.tryParse(
                            t['amount']?.replaceAll(',', '') ?? '0') ??
                        0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: context.watch<AppProvider>().isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 0,
                        child: InkWell(
                          onTap: () => _showAddTransactionDialog(transactionToEdit: t),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: context.watch<AppProvider>().isDarkMode ? null : Border.all(color: Colors.grey.shade100, width: 1),
                              boxShadow: context.watch<AppProvider>().isDarkMode ? [] : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              isExpense
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['category'] ?? '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: context.watch<AppProvider>().isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${t['account'] ?? ''} • ${t['date'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isExpense ? '-' : '+'}${context.watch<AppProvider>().currency} ${formatter.format(context.watch<AppProvider>().convert(amount))}',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if ((t['note'] ?? '').isNotEmpty)
                                Text(
                                  t['note']!,
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 11),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
                ),
        ),
      ],
    );
  }

  Widget _summaryChip(
      String label, double amount, Color color, NumberFormat formatter) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'Income'
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${Provider.of<AppProvider>(context, listen: false).currency} ${formatter.format(Provider.of<AppProvider>(context, listen: false).convert(amount))}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // IndexedStack keeps all tabs alive — state tidak hilang saat pindah tab
  Widget _buildBody() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        _buildTransactionPage(),
        AccountsPage(onAccountsChanged: _loadAccounts),
        SummaryPage(transactions: _filteredTransactions),
        const SettingsPage(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Transactions', 'Accounts', 'Summary', 'Settings'];
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadTransactions,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              heroTag: 'main_fab',
              onPressed: _showAddTransactionDialog,
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.watch<AppProvider>().isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BottomNavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
              selectedItemColor: kPrimary,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 12),
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('en');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final int selectionIndex = newValue.selection.end;
    final String formattedText =
        _formatter.format(int.parse(newValue.text.replaceAll(',', '')));
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
