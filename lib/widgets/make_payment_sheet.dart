import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';

/// Opens the "Make Payment" sheet. Returns true if a payment was made.
Future<bool?> showMakePayment(BuildContext context,
    {required int loanId, int? emiId, num? dueAmount, String? loanCode}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _MakePayment(loanId: loanId, emiId: emiId, dueAmount: dueAmount, loanCode: loanCode),
  );
}

class _MakePayment extends StatefulWidget {
  final int loanId;
  final int? emiId;
  final num? dueAmount;
  final String? loanCode;
  const _MakePayment({required this.loanId, this.emiId, this.dueAmount, this.loanCode});
  @override
  State<_MakePayment> createState() => _MakePaymentState();
}

class _MakePaymentState extends State<_MakePayment> {
  late final Razorpay _razorpay;
  bool _paying = false;
  // what we're paying right now (so the success handler can verify it)
  int? _payEmiId;
  num _payAmount = 0;
  String _payLabel = '';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  static const _options = [
    ('Pay upcoming instalment', 'Pay your instalment for the month', Icons.event_available),
    ('Advance instalment', 'Pay up to 5 instalments in advance', Icons.fast_forward),
    ('Part pre-payment', 'Pay part of the outstanding principal', Icons.pie_chart_outline),
    ('Missed / overdue', 'Clear missed instalments and late fees', Icons.warning_amber_rounded),
    ('Full payment / foreclosure', 'Close the entire loan', Icons.verified_outlined),
  ];

  Future<void> _start(num amount, String label) async {
    if (amount <= 0) amount = 1;
    setState(() { _paying = true; _payEmiId = widget.emiId; _payAmount = amount; _payLabel = label; });
    try {
      final order = await Api.i.payOrder(loanId: widget.loanId, emiId: widget.emiId, amount: amount);
      if (order['mode'] == 'checkout') {
        _razorpay.open({
          'key': order['key_id'],
          'order_id': order['order_id'],
          'amount': order['amount'],         // paise, from the order
          'currency': order['currency'] ?? 'INR',
          'name': 'Naitri',
          'description': '$label — ${widget.loanCode ?? ''}',
          'theme': {'color': '#D2213A'},
        });
        // result comes back through _onSuccess / _onError
      } else {
        // No Razorpay keys yet -> open the razorpay.me hosted page
        final uri = Uri.parse(order['link']);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Finish the payment on Razorpay. It will reflect once confirmed.')));
      }
    } catch (e) {
      if (mounted) setState(() => _paying = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Brand.red, content: Text(e.toString())));
    }
  }

  Future<void> _onSuccess(PaymentSuccessResponse r) async {
    try {
      await Api.i.payVerify(
        orderId: r.orderId ?? '', paymentId: r.paymentId ?? '', signature: r.signature ?? '',
        loanId: widget.loanId, emiId: _payEmiId, amount: _payAmount);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Brand.ok, content: Text('Paid ${money(_payAmount)} — $_payLabel')));
    } catch (e) {
      if (mounted) setState(() => _paying = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Brand.red, content: Text('Payment taken but not confirmed: ${e.toString()}')));
    }
  }

  void _onError(PaymentFailureResponse r) {
    if (mounted) setState(() => _paying = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Brand.red, content: Text(r.message ?? 'Payment cancelled')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Brand.line, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(children: [
              const Text('Make payment', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ]),
          ),
          if (widget.loanCode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('Loan ${widget.loanCode}', style: const TextStyle(color: Brand.inkSoft, fontSize: 13))),
            ),
          if (_paying) const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())
          else Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final (title, sub, icon) = _options[i];
                final amount = widget.dueAmount ?? 0;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _start(amount, title),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Brand.line),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Icon(icon, color: Brand.red),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(sub, style: const TextStyle(color: Brand.inkSoft, fontSize: 12.5)),
                        ],
                      )),
                      const Icon(Icons.chevron_right, color: Brand.inkSoft),
                    ]),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock, size: 13, color: Brand.inkSoft),
              SizedBox(width: 5),
              Text('Secured by Razorpay', style: TextStyle(fontSize: 12, color: Brand.inkSoft)),
            ]),
          ),
        ],
      ),
    );
  }
}
