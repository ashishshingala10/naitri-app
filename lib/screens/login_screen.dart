import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api.dart';
import '../theme.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _next() async {
    final phone = _phone.text.trim();
    if (phone.length != 10) {
      setState(() => _error = 'Enter your 10-digit mobile number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final devOtp = await Api.i.requestOtp(phone);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => OtpScreen(phone: phone, devOtp: devOtp),
      ));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: Brand.red, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                ),
                const SizedBox(width: 10),
                const Text('Naitri', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ]),
              const Spacer(),
              const Text('Sign in to your loan account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15)),
              const SizedBox(height: 8),
              const Text('We\'ll send a one-time code to your registered number.',
                  style: TextStyle(color: Brand.inkSoft, fontSize: 15)),
              const SizedBox(height: 26),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                style: const TextStyle(fontSize: 18, letterSpacing: 1),
                decoration: InputDecoration(
                  prefixText: '+91  ',
                  prefixStyle: const TextStyle(fontSize: 18, color: Brand.ink),
                  hintText: 'Mobile number',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Brand.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Brand.line)),
                ),
              ),
              if (_error != null) Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Brand.red, fontSize: 14)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _next,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Get OTP'),
                ),
              ),
              const SizedBox(height: 14),
              const Center(child: Text('Not a member yet? Visit your nearest Naitri branch.',
                  style: TextStyle(color: Brand.inkSoft, fontSize: 13))),
            ],
          ),
        ),
      ),
    );
  }
}
