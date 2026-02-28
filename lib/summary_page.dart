import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'app_provider.dart';

const Color kPrimary = Color(0xFFE53935);
const Color kIncome = Color(0xFF00C853);
const Color kExpense = Color(0xFFFF1744);
const Color kBackground = Color(0xFFF0F2F8);

class SummaryPage extends StatelessWidget {
  final List<Map<String, String>> transactions;

  const SummaryPage({super.key, required this.transactions});

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];
      sheetObject
          .appendRow(['Date', 'Type', 'Amount', 'Category', 'Account', 'Note']);
      for (var transaction in transactions) {
        sheetObject.appendRow([
          transaction['date'] ?? '',
          transaction['type'] ?? '',
          transaction['amount'] ?? '',
          transaction['category'] ?? '',
          transaction['account'] ?? '',
          transaction['note'] ?? ''
        ]);
      }
      List<int>? fileBytes = excel.encode();
      if (fileBytes != null) {
        final blob = html.Blob([fileBytes],
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'transactions.xlsx')
          ..click();
        html.Url.revokeObjectUrl(url);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Exported successfully!'),
                ],
              ),
              backgroundColor: kIncome,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: kExpense,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('id');

    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> categoryExpenses = {};

    for (var transaction in transactions) {
      final amount =
          double.tryParse(transaction['amount']!.replaceAll(',', '')) ?? 0;
      if (transaction['type'] == 'Income') {
        totalIncome += amount;
      } else if (transaction['type'] == 'Expense') {
        totalExpenses += amount;
        final cat = transaction['category'] ?? 'Other';
        categoryExpenses[cat] = (categoryExpenses[cat] ?? 0) + amount;
      }
    }

    final balance = totalIncome - totalExpenses;

    const List<Color> chartColors = [
      Color(0xFFE53935),
      Color(0xFFFF6B35),
      Color(0xFF00C853),
      Color(0xFF00B0FF),
      Color(0xFFFF4081),
      Color(0xFFFFD600),
      Color(0xFF00BCD4),
      Color(0xFF9C27B0),
      Color(0xFFFF5722),
      Color(0xFF4CAF50),
    ];

    List<PieChartSectionData> pieChartSections = [];
    int colorIndex = 0;
    categoryExpenses.forEach((category, amount) {
      final pct = totalExpenses > 0 ? (amount / totalExpenses * 100) : 0;
      pieChartSections.add(
        PieChartSectionData(
          color: chartColors[colorIndex % chartColors.length],
          value: amount,
          title: '${pct.toStringAsFixed(1)}%',
          radius: 55,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;

    return Scaffold(
      backgroundColor: kBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary stat cards
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context: context,
                    label: 'Income',
                    amount: totalIncome,
                    color: kIncome,
                    icon: Icons.arrow_downward_rounded,
                    formatter: formatter,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    context: context,
                    label: 'Expenses',
                    amount: totalExpenses,
                    color: kExpense,
                    icon: Icons.arrow_upward_rounded,
                    formatter: formatter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _balanceCard(context, balance, formatter),

            // Bar chart section
                  _sectionHeader(context, 'Income vs Expenses'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: isDark ? null : Border.all(color: Colors.grey.shade100, width: 1),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (totalIncome > totalExpenses
                                ? totalIncome
                                : totalExpenses) *
                            1.2 +
                        1,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            y: totalIncome,
                            colors: [kIncome],
                            width: 36,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            y: totalExpenses,
                            colors: [kExpense],
                            width: 36,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: SideTitles(showTitles: false),
                      bottomTitles: SideTitles(
                        showTitles: true,
                        getTitles: (double value) {
                          switch (value.toInt()) {
                            case 0:
                              return 'Income';
                            case 1:
                              return 'Expenses';
                            default:
                              return '';
                          }
                        },
                        getTextStyles: (value) => TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval:
                          (totalIncome > totalExpenses ? totalIncome : totalExpenses) /
                                  4 +
                              1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),

            // Legend for bar chart
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(context, kIncome, 'Income  ${context.watch<AppProvider>().currency} ${formatter.format(context.watch<AppProvider>().convert(totalIncome))}'),
                const SizedBox(width: 24),
                _legendDot(context, kExpense,
                    'Expenses  ${context.watch<AppProvider>().currency} ${formatter.format(context.watch<AppProvider>().convert(totalExpenses))}'),
              ],
            ),

            const SizedBox(height: 28),

            // Pie chart section
            _sectionHeader(context, 'Expenses by Category'),
            const SizedBox(height: 12),
            if (categoryExpenses.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'No expense data available',
                    style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade400, fontSize: 15),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: isDark ? null : Border.all(color: Colors.grey.shade100, width: 1),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          centerSpaceRadius: 44,
                          sectionsSpace: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Pie legend
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: () {
                        int i = 0;
                        return categoryExpenses.entries.map((e) {
                          final color = chartColors[i % chartColors.length];
                          i++;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      }(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportToExcel(context),
                icon: const Icon(Icons.download_rounded),
                label: const Text(
                  'Export to Excel',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required NumberFormat formatter,
  }) {
    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? null : Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${Provider.of<AppProvider>(context, listen: false).currency} ${formatter.format(Provider.of<AppProvider>(context, listen: false).convert(amount))}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(BuildContext context, double balance, NumberFormat formatter) {
    final isPositive = balance >= 0;
    final color = isPositive ? kIncome : kExpense;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
              : [const Color(0xFFFF1744), const Color(0xFFFF6584)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Net Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 4),
              Text('Income - Expenses',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          Text(
            '${isPositive ? '+' : ''}${Provider.of<AppProvider>(context, listen: false).currency} ${formatter.format(Provider.of<AppProvider>(context, listen: false).convert(balance))}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
      ),
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
