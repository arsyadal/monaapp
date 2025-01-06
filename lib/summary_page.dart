import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart';
import 'dart:html' as html;

class SummaryPage extends StatelessWidget {
  final List<Map<String, String>> transactions;

  const SummaryPage({super.key, required this.transactions});

  Future<void> _exportToExcel(BuildContext context) async {
    try {
      // Buat file Excel
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      // Tambahkan header
      sheetObject
          .appendRow(['Date', 'Type', 'Amount', 'Category', 'Account', 'Note']);

      // Tambahkan data transaksi
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

      // Konversi Excel ke bytes
      List<int>? fileBytes = excel.encode();

      if (fileBytes != null) {
        // Buat Blob untuk file Excel
        final blob = html.Blob([
          fileBytes
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

        // Buat URL untuk download
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Buat elemen anchor untuk download
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'transactions.xlsx')
          ..click();

        // Bersihkan URL
        html.Url.revokeObjectUrl(url);

        // Tampilkan notifikasi sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transactions exported successfully')),
        );
      }
    } catch (e) {
      // Tangani error
      print('Error exporting to Excel: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> categoryExpenses = {};

    for (var transaction in transactions) {
      final amount = double.parse(transaction['amount']!.replaceAll(',', ''));
      if (transaction['type'] == 'Income') {
        totalIncome += amount;
      } else if (transaction['type'] == 'Expense') {
        totalExpenses += amount;
        if (categoryExpenses.containsKey(transaction['category'])) {
          categoryExpenses[transaction['category']!] =
              categoryExpenses[transaction['category']!]! + amount;
        } else {
          categoryExpenses[transaction['category']!] = amount;
        }
      }
    }

    List<PieChartSectionData> pieChartSections = [];
    int colorIndex = 0;
    List<Color> colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.cyan,
      Colors.pink,
      Colors.brown,
      Colors.green,
      Colors.red,
      Colors.teal,
    ];

    categoryExpenses.forEach((category, amount) {
      pieChartSections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: category,
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    // Log untuk memeriksa data
    print('Total Income: $totalIncome');
    print('Total Expenses: $totalExpenses');
    print('Category Expenses: $categoryExpenses');

    return Scaffold(
    
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Income vs Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            y: totalIncome,
                            colors: [Colors.green],
                            width: 20,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            y: totalExpenses,
                            colors: [Colors.red],
                            width: 20,
                          ),
                        ],
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: SideTitles(showTitles: true),
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
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Expenses by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: pieChartSections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _exportToExcel(context),
                child: const Text('Export to Excel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
