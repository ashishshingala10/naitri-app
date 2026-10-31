import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../theme.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String? devOtp;
  const OtpScreen({super.key, required this.phone, this.devOtp});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.devOtp != null) _otp.text = widget.devOtp!; // auto-fill in dev
  }

  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Api.i.verifyOtp(widget.phone, _otp.text.trim());
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter the code', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Sent to +91 ${widget.phone}', style: const TextStyle(color: Brand.inkSoft, fontSize: 15)),
              if (widget.devOtp != null) Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Dev code: ${widget.devOtp}', style: const TextStyle(color: Brand.gold, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 26),
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                style: const TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white, hintText: '••••••',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Brand.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Brand.line)),
                ),
              ),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Brand.red)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Verify & continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
