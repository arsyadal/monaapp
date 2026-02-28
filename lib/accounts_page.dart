import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';

const Color kPrimary = Color(0xFFE53935);
const Color kBackground = Color(0xFFF0F2F8);

class AccountsPage extends StatefulWidget {
  final VoidCallback? onAccountsChanged;

  const AccountsPage({super.key, this.onAccountsChanged});

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  String _selectedAccountType = 'Bank';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _newAccountTypeController =
      TextEditingController();
  final List<Map<String, String>> _accounts = [];
  final List<String> _accountTypes = ['Bank', 'Cash'];
  final ApiService _apiService = ApiService();

  final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US'); // Format untuk menambahkan koma setiap tiga angka

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatAmount);
  }

  Future<void> _loadAccounts() async {
    try {
      final data = await _apiService.getAccounts();
      setState(() {
        _accounts.clear();
        _accounts.addAll(data.map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'id': m['id']?.toString() ?? '',
            'type': m['type']?.toString() ?? '',
            'amount': (m['amount'] as num?)?.toStringAsFixed(0) ?? '0',
          };
        }).toList());
      });
    } catch (_) {}
  }

  IconData _getAccountIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bank':
        return Icons.account_balance_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'credit':
        return Icons.credit_card_rounded;
      case 'savings':
        return Icons.savings_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Color _getAccountColor(int index) {
    const colors = [
      Color(0xFFE53935),
      Color(0xFF00C853),
      Color(0xFFFF6B35),
      Color(0xFF00B0FF),
      Color(0xFFFF4081),
    ];
    return colors[index % colors.length];
  }

  void _showAddAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;
            return Dialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance_wallet,
                              color: kPrimary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Account',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Account type dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedAccountType,
                      decoration: _inputDecoration(
                          'Account Type', Icons.category_outlined),
                      items: _accountTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) =>
                          setDialogState(() => _selectedAccountType = val!),
                    ),
                    const SizedBox(height: 12),

                    // New account type
                    TextField(
                      controller: _newAccountTypeController,
                      decoration: _inputDecoration(
                          'Or create new type', Icons.add_circle_outline),
                      onSubmitted: (newType) {
                        if (newType.isNotEmpty &&
                            !_accountTypes.contains(newType)) {
                          setDialogState(() {
                            _accountTypes.add(newType);
                            _selectedAccountType = newType;
                            _newAccountTypeController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Amount
                    TextField(
                      controller: _amountController,
                      decoration: _inputDecoration(
                              'Initial Balance', Icons.payments_outlined)
                          .copyWith(prefixText: '${Provider.of<AppProvider>(context, listen: false).currency} '),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                              final amountText = _amountController.text
                                  .replaceAll(',', '');
                              if (amountText.isEmpty) return;
                              final rawAmount = double.parse(amountText);
                              final amount = Provider.of<AppProvider>(context, listen: false).convertToBase(rawAmount);

                              final existingIndex = _accounts.indexWhere(
                                  (a) => a['type'] == _selectedAccountType);

                              try {
                                if (existingIndex != -1) {
                                  setState(() {
                                    _accounts[existingIndex]['amount'] =
                                        (int.parse(_accounts[existingIndex]
                                                    ['amount']!) +
                                                amount)
                                            .toString();
                                  });
                                  await _apiService
                                      .updateAccount(_accounts[existingIndex]);
                                } else {
                                  final account = {
                                    'type': _selectedAccountType,
                                    'amount': amount.toString(),
                                  };
                                  setState(() => _accounts.add(account));
                                  await _apiService.createAccount(account);
                                }

                                _amountController.clear();

                                final transaction = {
                                  'type': 'Income',
                                  'date': DateTime.now()
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                                  'amount': amount.toString(),
                                  'category': 'Account',
                                  'account': _selectedAccountType,
                                  'note': 'Initial deposit',
                                };
                                await _apiService.createTransaction(transaction);
                                // Beritahu MyHomePage bahwa akun baru ditambahkan
                                widget.onAccountsChanged?.call();
                                if (context.mounted) Navigator.of(context).pop();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Gagal menyimpan akun: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  _loadAccounts(); // revert state from server
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Save',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('id');
    double totalBalance = 0;
    for (var acc in _accounts) {
      totalBalance += double.tryParse(acc['amount'] ?? '0') ?? 0;
    }

    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          // Total balance header
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Balance',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(
                      '${Provider.of<AppProvider>(context, listen: false).currency} ${formatter.format(Provider.of<AppProvider>(context, listen: false).convert(totalBalance))}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${_accounts.length} accounts',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),

          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Accounts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Provider.of<AppProvider>(context, listen: false).isDarkMode ? Colors.white : const Color(0xFF1A1A2E))),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: kPrimary, size: 20),
                  onPressed: _loadAccounts,
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Accounts list
          Expanded(
            child: _accounts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            size: 80, color: kPrimary.withOpacity(0.1)),
                        const SizedBox(height: 24),
                        Text('No accounts yet',
                            style: TextStyle(
                                color: Provider.of<AppProvider>(context, listen: false).isDarkMode ? Colors.white : const Color(0xFF1A1A2E), 
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Tap + to add your first account',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    itemCount: _accounts.length,
                    itemBuilder: (context, index) {
                      final account = _accounts[index];
                      final color = _getAccountColor(index);
                      final amount =
                          double.tryParse(account['amount'] ?? '0') ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: Provider.of<AppProvider>(context, listen: false).isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Provider.of<AppProvider>(context, listen: false).isDarkMode ? null : Border.all(color: Colors.grey.shade100, width: 1),
                          boxShadow: Provider.of<AppProvider>(context, listen: false).isDarkMode ? [] : [
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
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _getAccountIcon(account['type'] ?? ''),
                                color: color,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    account['type'] ?? '-',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Provider.of<AppProvider>(context, listen: false).isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Account balance',
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${Provider.of<AppProvider>(context, listen: false).currency} ${formatter.format(Provider.of<AppProvider>(context, listen: false).convert(amount))}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Provider.of<AppProvider>(context, listen: false).isDarkMode ? Colors.white : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountDialog,
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
