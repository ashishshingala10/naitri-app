import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets/make_payment_sheet.dart';

class PayEmisScreen extends StatefulWidget {
  const PayEmisScreen({super.key});
  @override
  State<PayEmisScreen> createState() => _PayEmisScreenState();
}

class _PayEmisScreenState extends State<PayEmisScreen> with AutomaticKeepAliveClientMixin {
  Future<Map>? _future;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = Api.i.dues();
  }

  Future<void> _reload() async {
    setState(() => _future = Api.i.dues());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(alignment: Alignment.centerLeft,
                child: Text('Make loan payments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            ),
            const TabBar(
              labelColor: Brand.red, unselectedLabelColor: Brand.inkSoft, indicatorColor: Brand.red,
              labelStyle: TextStyle(fontWeight: FontWeight.w700),
              tabs: [Tab(text: 'Overdue'), Tab(text: 'Upcoming')],
            ),
            Expanded(
              child: FutureBuilder<Map>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text(snap.error.toString(), style: const TextStyle(color: Brand.inkSoft)));
                  }
                  final overdue = (snap.data!['overdue'] as List).cast<Map>();
                  final upcoming = (snap.data!['upcoming'] as List).cast<Map>();
                  return TabBarView(children: [
                    _list(overdue, overdue: true),
                    _list(upcoming, overdue: false),
                  ]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<Map> rows, {required bool overdue}) {
    if (rows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(children: [
          const SizedBox(height: 120),
          Icon(overdue ? Icons.check_circle_outline : Icons.event_available, size: 48, color: Brand.ok),
          const SizedBox(height: 12),
          Center(child: Text(overdue ? 'Nothing overdue — you\'re all caught up' : 'No upcoming dues',
              style: const TextStyle(color: Brand.inkSoft))),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (_, i) {
          final r = rows[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(r['handset_model'] ?? 'Handset loan',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    Text(money(r['amount']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                  const SizedBox(height: 2),
                  Text(r['loan_code'] ?? '', style: const TextStyle(color: Brand.inkSoft, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(overdue ? Icons.warning_amber_rounded : Icons.event,
                        size: 16, color: overdue ? Brand.red : Brand.inkSoft),
                    const SizedBox(width: 6),
                    Text('Instalment ${r['installment_no']} • due ${shortDate(r['due_date'])}',
                        style: TextStyle(fontSize: 12.5, color: overdue ? Brand.red : Brand.inkSoft)),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        minimumSize: const Size(0, 38),
                      ),
                      onPressed: () async {
                        await showMakePayment(context,
                            loanId: r['loan_id'], emiId: r['emi_id'],
                            dueAmount: r['amount'], loanCode: r['loan_code']);
                        _reload();
                      },
                      child: const Text('Pay now'),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
