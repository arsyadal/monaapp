import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'main.dart'; // for kPrimary

class PinScreen extends StatefulWidget {
  final Widget nextScreen;
  const PinScreen({super.key, required this.nextScreen});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _input = '';

  void _tapNumber(String n) {
    if (_input.length < 4) {
      setState(() => _input += n);
      if (_input.length == 4) {
        _checkPin();
      }
    }
  }

  void _delete() {
    if (_input.isNotEmpty) {
      setState(() => _input = _input.substring(0, _input.length - 1));
    }
  }

  void _checkPin() {
    final correct = context.read<AppProvider>().pinCode;
    if (_input == correct) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.nextScreen));
    } else {
      setState(() => _input = '');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : kPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_rounded, size: 60, color: Colors.white),
            const SizedBox(height: 16),
            const Text('Enter App PIN', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _input.length > index ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                );
              }),
            ),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_calcButton('1'), _calcButton('2'), _calcButton('3')],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_calcButton('4'), _calcButton('5'), _calcButton('6')],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_calcButton('7'), _calcButton('8'), _calcButton('9')],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 70), // empty space
              _calcButton('0'),
              InkWell(
                onTap: _delete,
                child: const SizedBox(
                  width: 70, height: 70,
                  child: Icon(Icons.backspace_outlined, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcButton(String n) {
    return InkWell(
      onTap: () => _tapNumber(n),
      splashColor: Colors.white30,
      customBorder: const CircleBorder(),
      child: Container(
        width: 70, height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Text(n, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
