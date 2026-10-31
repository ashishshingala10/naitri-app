import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import '../widgets/loan_card.dart';
import '../widgets/make_payment_sheet.dart';
import 'loan_detail_screen.dart';
import 'pay_emis_screen.dart';
import 'login_screen.dart';
import 'selfie_capture_screen.dart';
import 'scan_qr_screen.dart';
import 'documents_screen.dart';
import '../services/notifications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const _ServiceTab(),
      const _ScanTab(),
      const PayEmisScreen(),
      const _MenuTab(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages), // keeps tab state → fast switching
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Brand.red.withOpacity(0.10),
          labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Brand.red), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.headset_mic_outlined), selectedIcon: Icon(Icons.headset_mic, color: Brand.red), label: 'Service'),
            NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
            NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments, color: Brand.red), label: 'Pay EMIs'),
            NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
          ],
        ),
      ),
    );
  }
}

// --------------------------- HOME TAB ---------------------------
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with AutomaticKeepAliveClientMixin {
  Future<Map>? _future;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _loadAndSync();
  }

  Future<Map> _loadAndSync() async {
    final data = await Api.i.home();
    // Schedule on-device EMI reminders from the fresh loan data (best-effort)
    Notifications.i.syncFromLoans((data['loans'] as List).cast<Map>());
    return data;
  }

  Future<void> _reload() async {
    setState(() => _future = _loadAndSync());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<Map>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _ErrorView(message: snap.error.toString(), onRetry: _reload);
            }
            final member = snap.data!['member'] as Map;
            final loans = (snap.data!['loans'] as List).cast<Map>();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Brand.line)),
                  child: Row(children: const [
                    Icon(Icons.search, color: Brand.inkSoft),
                    SizedBox(width: 10),
                    Text('Search Naitri', style: TextStyle(color: Brand.inkSoft)),
                  ]),
                ),
                const SizedBox(height: 16),
                Text('Hi ${member['full_name'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(member['member_code'] ?? '', style: const TextStyle(color: Brand.inkSoft, fontSize: 13)),
                const SizedBox(height: 16),
                Row(children: const [
                  Text('Your relations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 10),
                if (loans.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(22), child: Text('No active loans yet.'))),
                ...loans.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LoanCard(
                        loan: l,
                        onOpen: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => LoanDetailScreen(loanId: l['id']))),
                        onPay: () async {
                          final nd = l['next_due'] as Map?;
                          await showMakePayment(context,
                              loanId: l['id'], dueAmount: nd?['amount'], loanCode: l['loan_code']);
                          _reload();
                        },
                      ),
                    )),
                const SizedBox(height: 8),
                const Text('Quick actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _QuickActions(onReload: _reload),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Future<void> Function() onReload;
  const _QuickActions({required this.onReload});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.payments_outlined, 'Make\npayments', () {}),
      (Icons.receipt_long_outlined, 'View\nstatements', () {}),
      (Icons.account_balance_outlined, 'Change\nbank', () {}),
      (Icons.camera_alt_outlined, 'Submit\nselfie', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()));
      }),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((it) => Expanded(
        child: InkWell(
          onTap: it.$3,
          child: Column(children: [
            Container(
              width: 54, height: 54,
              decoration: const BoxDecoration(color: Color(0xFFFDEBEE), shape: BoxShape.circle),
              child: Icon(it.$1, color: Brand.red),
            ),
            const SizedBox(height: 6),
            Text(it.$2, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: Brand.inkSoft, height: 1.1)),
          ]),
        ),
      )).toList(),
    );
  }
}

// --------------------------- OTHER TABS (light placeholders) ---------------------------
class _ServiceTab extends StatelessWidget {
  const _ServiceTab();
  @override
  Widget build(BuildContext context) => const _Simple(
      icon: Icons.headset_mic, title: 'Service', lines: [
        'View statements & certificates',
        'Download your loan agreement',
        'Raise a complaint',
      ]);
}

class _ScanTab extends StatelessWidget {
  const _ScanTab();
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 72, color: Brand.red),
                const SizedBox(height: 16),
                const Text('Scan & pay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Scan the QR shown at a Naitri branch to pay an instalment instantly.',
                    textAlign: TextAlign.center, style: TextStyle(color: Brand.inkSoft)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ScanQrScreen())),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Open scanner'),
                ),
              ],
            ),
          ),
        ),
      );
}

class _MenuTab extends StatelessWidget {
  const _MenuTab();

  // Fetch home, pick a loan (first if several), run [onLoan].
  Future<void> _withLoan(BuildContext context, void Function(Map loan) onLoan) async {
    try {
      final data = await Api.i.home();
      final loans = (data['loans'] as List).cast<Map>();
      if (loans.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No loans on your account yet')));
        return;
      }
      onLoan(loans.first);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Brand.red, content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, VoidCallback)>[
      (Icons.description_outlined, 'Documents & statements', () {
        _withLoan(context, (l) => Navigator.push(context, MaterialPageRoute(
          builder: (_) => DocumentsScreen(loanId: l['id'], loanCode: l['loan_code'] ?? ''))));
      }),
      (Icons.lock_outline, 'Device status', () {
        _withLoan(context, (l) => Navigator.push(context, MaterialPageRoute(
          builder: (_) => LoanDetailScreen(loanId: l['id']))));
      }),
      (Icons.camera_alt_outlined, 'Submit handover photos', () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SelfieCaptureScreen()));
      }),
      (Icons.help_outline, 'Help & support', () {}),
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Menu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...rows.map((r) => Card(child: ListTile(
                leading: Icon(r.$1, color: Brand.red),
                title: Text(r.$2),
                trailing: const Icon(Icons.chevron_right),
                onTap: r.$3,
              ))),
          const SizedBox(height: 10),
          Card(child: ListTile(
            leading: const Icon(Icons.logout, color: Brand.red),
            title: const Text('Log out'),
            onTap: () async {
              await Api.i.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
          )),
        ],
      ),
    );
  }
}

class _Simple extends StatelessWidget {
  final IconData icon; final String title; final List<String> lines;
  const _Simple({required this.icon, required this.title, required this.lines});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...lines.map((l) => Card(child: ListTile(leading: Icon(icon, color: Brand.red), title: Text(l)))),
      ]),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final String message; final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => ListView(children: [
    const SizedBox(height: 120),
    const Icon(Icons.cloud_off, size: 48, color: Brand.inkSoft),
    const SizedBox(height: 12),
    Center(child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Brand.inkSoft))),
    const SizedBox(height: 16),
    Center(child: OutlinedButton(onPressed: onRetry, child: const Text('Retry'))),
  ]);
}
