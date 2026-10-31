import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/make_payment_sheet.dart';

class LoanDetailScreen extends StatefulWidget {
  final int loanId;
  const LoanDetailScreen({super.key, required this.loanId});
  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  Future<Map>? _future;

  @override
  void initState() {
    super.initState();
    _future = Api.i.loan(widget.loanId);
  }

  void _reload() => setState(() => _future = Api.i.loan(widget.loanId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan details')),
      body: FutureBuilder<Map>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString(), style: const TextStyle(color: Brand.inkSoft)));
          }
          final loan = snap.data!;
          final s = loan['summary'] as Map;
          final total = (loan['emi_amount'] ?? 0) * (loan['tenure_months'] ?? 0);
          final paidAmt = (s['paid_amount'] ?? 0) as num;
          final progress = total == 0 ? 0.0 : (paidAmt / total).clamp(0.0, 1.0);
          final schedule = (loan['schedule'] as List).cast<Map>();
          final txns = (loan['transactions'] as List).cast<Map>();
          final device = loan['device'] as Map?;

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // header summary
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan['handset_model'] ?? 'Handset loan',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(loan['loan_code'] ?? '', style: const TextStyle(color: Brand.inkSoft, fontSize: 12)),
                      const SizedBox(height: 14),
                      Text(money(loan['price']), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.toDouble(),
                          minHeight: 8,
                          backgroundColor: Brand.line,
                          color: Brand.ok,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Paid ${money(paidAmt)}', style: const TextStyle(fontSize: 12.5, color: Brand.ok, fontWeight: FontWeight.w700)),
                        Text('Remaining ${money(s['remaining'])}', style: const TextStyle(fontSize: 12.5, color: Brand.inkSoft)),
                      ]),
                    ],
                  ),
                ),
                const TabBar(
                  labelColor: Brand.red,
                  unselectedLabelColor: Brand.inkSoft,
                  indicatorColor: Brand.red,
                  labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  tabs: [Tab(text: 'Overview'), Tab(text: 'Schedule'), Tab(text: 'Transactions')],
                ),
                Expanded(
                  child: TabBarView(children: [
                    _overview(loan, s, device),
                    _schedule(schedule),
                    _transactions(txns),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: FilledButton(
            onPressed: () async {
              final loan = await _future;
              final sch = (loan!['schedule'] as List).cast<Map>();
              final next = sch.firstWhere((e) => e['status'] != 'paid', orElse: () => {});
              await showMakePayment(context,
                  loanId: widget.loanId,
                  emiId: next['id'] is int ? next['id'] : null,
                  dueAmount: next['amount'],
                  loanCode: loan['loan_code']);
              _reload();
            },
            child: const Text('Make payment'),
          ),
        ),
      ),
    );
  }

  Widget _overview(Map loan, Map s, Map? device) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _row('Loan start date', shortDate(loan['disbursed_at'])),
              _row('Tenure', '${loan['tenure_months']} months'),
              _row('Rate of interest p.a.', '${loan['interest_rate']}%'),
              _row('Monthly EMI', money(loan['emi_amount'])),
              _row('EMIs paid', '${s['emis_paid']}'),
              _row('EMIs pending', '${s['emis_pending']}', last: true),
            ]),
          )),
          const SizedBox(height: 14),
          if (device != null) _deviceCard(device),
        ],
      );

  Widget _deviceCard(Map d) {
    final locked = d['lock_state'] == 'locked';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: locked ? const Color(0xFFFDEBEE) : const Color(0xFFE6F6EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(locked ? Icons.lock : Icons.lock_open, color: locked ? Brand.red : Brand.ok),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device ${locked ? 'locked' : 'active'}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(locked
                  ? 'Your handset is restricted for an overdue instalment. Pay the dues to unlock within minutes.'
                  : '${d['model'] ?? 'Handset'} • working normally',
                  style: const TextStyle(color: Brand.inkSoft, fontSize: 12.5)),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _schedule(List<Map> rows) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Brand.line),
        itemBuilder: (_, i) {
          final e = rows[i];
          final paid = e['status'] == 'paid';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: paid ? const Color(0xFFE6F6EF) : Brand.page,
              child: paid ? const Icon(Icons.check, color: Brand.ok, size: 20)
                          : Text('${e['installment_no']}', style: const TextStyle(color: Brand.inkSoft)),
            ),
            title: Text(money(e['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Due ${shortDate(e['due_date'])}', style: const TextStyle(fontSize: 12.5)),
            trailing: Text((e['status'] ?? '').toString().toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: paid ? Brand.ok : (e['status'] == 'overdue' ? Brand.red : Brand.inkSoft))),
          );
        },
      );

  Widget _transactions(List<Map> rows) => rows.isEmpty
      ? const Center(child: Text('No payments yet', style: TextStyle(color: Brand.inkSoft)))
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Brand.line),
          itemBuilder: (_, i) {
            final t = rows[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFFE6F6EF), child: Icon(Icons.south_west, color: Brand.ok, size: 20)),
              title: Text(money(t['amount']), style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${(t['method'] ?? '').toString().toUpperCase()} • ${shortDate(t['created_at'])}', style: const TextStyle(fontSize: 12.5)),
              trailing: Text(t['reference'] ?? '', style: const TextStyle(fontSize: 10, color: Brand.inkSoft)),
            );
          },
        );

  Widget _row(String k, String v, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(k, style: const TextStyle(color: Brand.inkSoft, fontSize: 13.5)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        ]),
      );
}
