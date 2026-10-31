import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../util.dart';

/// On-device EMI reminders. No server/FCM needed — reminders are scheduled
/// locally from each loan's due dates (3 days before, at 10:00 AM).
/// For server-pushed reminders in production, add Firebase Cloud Messaging.
class Notifications {
  Notifications._();
  static final Notifications i = Notifications._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));

    // Android 13+ runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'emi_reminders', 'EMI reminders',
      channelDescription: 'Reminds you before an instalment is due',
      importance: Importance.high, priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Rebuild all reminders from the current set of loans (from /api/app/home).
  Future<void> syncFromLoans(List<Map> loans) async {
    if (!_ready) await init();
    await _plugin.cancelAll();

    int id = 1;
    final now = DateTime.now();
    for (final l in loans) {
      final nd = l['next_due'] as Map?;
      if (nd == null || nd['due_date'] == null) continue;
      DateTime due;
      try { due = DateTime.parse(nd['due_date']); } catch (_) { continue; }

      final remindAt = DateTime(due.year, due.month, due.day - 3, 10, 0);
      if (remindAt.isBefore(now)) continue; // don't schedule in the past

      final model = l['handset_model'] ?? 'your handset loan';
      try {
        await _plugin.zonedSchedule(
          id++,
          'EMI due soon',
          '${money(nd['amount'])} for $model is due on ${shortDate(nd['due_date'])}. Pay in the app.',
          tz.TZDateTime.from(remindAt, tz.local),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        // Scheduling can fail without exact-alarm permission; reminders are best-effort.
      }
    }
  }
}
