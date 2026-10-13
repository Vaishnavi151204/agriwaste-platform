import 'package:flutter/material.dart';

class MockPaymentScreen extends StatefulWidget {
  final double amount;
  final String title;
  final VoidCallback onSuccess;

  const MockPaymentScreen({
    super.key,
    required this.amount,
    required this.title,
    required this.onSuccess,
  });

  @override
  State<MockPaymentScreen> createState() => _MockPaymentScreenState();
}

class _MockPaymentScreenState extends State<MockPaymentScreen> {
  bool _paying = false;
  String _method = 'UPI';

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _paying = false);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Payment Successful ✅'),
        content: Text('₹${widget.amount.toStringAsFixed(0)} paid via $_method'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSuccess();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Amount Payable'),
            Text(
              '₹${widget.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _methodTile('UPI', Icons.qr_code),
            _methodTile('Google Pay', Icons.account_balance_wallet),
            _methodTile('PhonePe', Icons.phone_android),
            _methodTile('Cash on Delivery', Icons.money),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _paying ? null : _pay,
                child: _paying
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text('Pay ₹${widget.amount.toStringAsFixed(0)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodTile(String name, IconData icon) {
    final selected = _method == name;
    return Card(
      color: selected ? Colors.green.shade50 : null,
      child: ListTile(
        leading: Icon(icon),
        title: Text(name),
        trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
        onTap: () => setState(() => _method = name),
      ),
    );
  }
}