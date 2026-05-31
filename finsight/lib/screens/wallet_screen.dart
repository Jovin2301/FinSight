import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Wallet Screen', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Feature Coming Soon', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}