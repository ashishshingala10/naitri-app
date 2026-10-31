import 'package:flutter/material.dart';
import '../theme.dart';
import '../util.dart';

class LoanCard extends StatelessWidget {
  final Map loan;
  final VoidCallback onOpen;
  final VoidCallback onPay;
  const LoanCard({super.key, required this.loan, required this.onOpen, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final nextDue = loan['next_due'] as Map?;
    final status = (loan['status'] ?? '').toString();
    final active = status == 'active' || status == 'disbursed' || status == 'approved';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE6F6EF) : Brand.line,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(active ? 'Active' : status,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: active ? Brand.ok : Brand.inkSoft)),
              ),
              const Spacer(),
              Text(loan['loan_code'] ?? '', style: const TextStyle(fontSize: 11, color: Brand.inkSoft)),
            ]),
            const SizedBox(height: 10),
            Text(loan['handset_model'] ?? 'Handset loan',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${money(loan['price'])} • ${loan['tenure_months']} months',
                style: const TextStyle(color: Brand.inkSoft, fontSize: 13)),
            if (nextDue != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Brand.page, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.event, size: 18, color: Brand.inkSoft),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${money(nextDue['amount'])} due on ${shortDate(nextDue['due_date'])}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  TextButton(
                    onPressed: onPay,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Brand.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      minimumSize: const Size(0, 34),
                    ),
                    child: const Text('Pay'),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 8),
            Row(children: [
              _mini(Icons.receipt_long, 'Statement', onOpen),
              _mini(Icons.description_outlined, 'Details', onOpen),
              const Spacer(),
              IconButton(onPressed: onOpen, icon: const Icon(Icons.chevron_right, color: Brand.inkSoft)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _mini(IconData icon, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: InkWell(
          onTap: onTap,
          child: Column(children: [
            Icon(icon, size: 20, color: Brand.red),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Brand.inkSoft)),
          ]),
        ),
      );
}
