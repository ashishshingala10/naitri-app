import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import '../widgets/make_payment_sheet.dart';

/// Scans a Naitri pay QR. Expected payload (JSON):
///   {"loan_id":1,"emi_id":12,"amount":1786,"loan_code":"NAI-L-2026-00001"}
/// Branch staff show this QR from the admin portal.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});
  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_handled) return;
    final raw = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
    if (raw == null) return;

    Map? data;
    try { data = jsonDecode(raw) as Map; } catch (_) {}
    if (data == null || data['loan_id'] == null) {
      _snack('This QR is not a Naitri payment code');
      return;
    }
    _handled = true;
    await _controller.stop();
    if (!mounted) return;
    final paid = await showMakePayment(context,
        loanId: data['loan_id'],
        emiId: data['emi_id'],
        dueAmount: data['amount'],
        loanCode: data['loan_code']);
    if (mounted) {
      if (paid == true) {
        Navigator.pop(context);
      } else {
        _handled = false;
        _controller.start();
      }
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), backgroundColor: Brand.ink));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan to pay')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // viewfinder
          Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          Positioned(
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
              child: const Text('Point at the branch payment QR',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}
