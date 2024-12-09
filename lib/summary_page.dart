import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryPage extends StatelessWidget {
  final List<Map<String, String>> transactions;

  const SummaryPage({super.key, required this.transactions});

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

    // Log untuk memeriksa apakah data sudah benar
    print('Total Income: $totalIncome');
    print('Total Expenses: $totalExpenses');
    print('Category Expenses: $categoryExpenses');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary Page'),
      ),
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
                height: 200, // Tentukan tinggi untuk memastikan widget diatur dengan benar
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
                height: 200, // Tentukan tinggi untuk memastikan widget diatur dengan benar
                child: PieChart(
                  PieChartData(
                    sections: pieChartSections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}