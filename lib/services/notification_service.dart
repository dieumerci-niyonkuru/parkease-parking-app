import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final List<AppNotification> _inAppNotifications = [];
  static List<AppNotification> get notifications =>
      List.unmodifiable(_inAppNotifications);
  static int get unreadCount =>
      _inAppNotifications.where((n) => !n.isRead).length;

  // ── Initialize ────────────────────────────────────────────────
  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'itec_parking',
      'ITEC Parking',
      description: 'Parking alerts and payment confirmations',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Seed welcome notification
    _addInApp(AppNotification(
      id: 'welcome',
      title: '🚗 Welcome to ITEC Parking',
      body: 'Rwanda National Parking System — tap to look up a vehicle.',
      type: NotificationType.system,
      time: DateTime.now(),
    ));
  }

  static void _onNotificationTap(NotificationResponse resp) {}

  // ── Show Push Notification ────────────────────────────────────
  static Future<void> _showPush({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'itec_parking',
          'ITEC Parking',
          channelDescription: 'Parking alerts and payment confirmations',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00C896),
          styleInformation: BigTextStyleInformation(''),
          enableLights: true,
          ledColor: Color(0xFF00C896),
          ledOnMs: 500,
          ledOffMs: 500,
        ),
      );
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (_) {}
  }

  // ── In-app notification helpers ───────────────────────────────
  static void _addInApp(AppNotification n) {
    _inAppNotifications.insert(0, n);
    if (_inAppNotifications.length > 50) {
      _inAppNotifications.removeRange(50, _inAppNotifications.length);
    }
  }

  // ── Specific Notification Types ───────────────────────────────
  static Future<void> notifyVehicleLookup(VehicleRecord v) async {
    final n = AppNotification(
      id: 'lookup_${v.slotId}',
      title: 'Vehicle Found — ${v.plateNumber}',
      body: '${v.ownerName} • ${v.parkingName} • ${v.durationDisplay} parked',
      type: NotificationType.system,
      time: DateTime.now(),
      data: {'slotId': v.slotId},
    );
    _addInApp(n);
    await _showPush(
      id: v.slotId.hashCode,
      title: '🔍 Vehicle Found: ${v.plateNumber}',
      body: '${v.ownerName} has been parked for ${v.durationDisplay}',
    );
  }

  static Future<void> notifyPaymentSuccess(VehicleRecord v) async {
    final rwf = _formatRwf(v.totalAmount);
    final n = AppNotification(
      id: 'pay_${v.slotId}_${DateTime.now().millisecondsSinceEpoch}',
      title: '✅ Payment Confirmed — $rwf',
      body: '${v.plateNumber} • ${v.parkingName} • Receipt: ${v.receiptNumber}',
      type: NotificationType.payment,
      time: DateTime.now(),
      data: {'slotId': v.slotId, 'amount': v.totalAmount},
    );
    _addInApp(n);
    await _showPush(
      id: v.slotId.hashCode + 1000,
      title: '✅ Payment Confirmed — $rwf RWF',
      body: 'Receipt: ${v.receiptNumber} for ${v.plateNumber}',
    );
  }

  static Future<void> notifyLongParking(VehicleRecord v) async {
    final n = AppNotification(
      id: 'long_${v.slotId}',
      title: '⏰ Long Stay Alert',
      body: '${v.plateNumber} has been parked for ${v.durationDisplay} — Amount: ${_formatRwf(v.totalAmount)} RWF',
      type: NotificationType.alert,
      time: DateTime.now(),
      data: {'slotId': v.slotId},
    );
    _addInApp(n);
    await _showPush(
      id: v.slotId.hashCode + 2000,
      title: '⏰ Long Stay — ${v.plateNumber}',
      body: 'Parked ${v.durationDisplay} — ${_formatRwf(v.totalAmount)} RWF due',
    );
  }

  static Future<void> notifySystemStatus(String msg) async {
    final n = AppNotification(
      id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
      title: '📡 ITEC System Update',
      body: msg,
      type: NotificationType.system,
      time: DateTime.now(),
    );
    _addInApp(n);
  }

  // ── Mark read ─────────────────────────────────────────────────
  static void markRead(String id) {
    final idx = _inAppNotifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _inAppNotifications[idx] = _inAppNotifications[idx].copyWith(isRead: true);
    }
  }

  static void markAllRead() {
    for (var i = 0; i < _inAppNotifications.length; i++) {
      _inAppNotifications[i] = _inAppNotifications[i].copyWith(isRead: true);
    }
  }

  static void clearAll() => _inAppNotifications.clear();

  static String _formatRwf(double amount) =>
      amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  // ── Add in-app notification ───────────────────────────────────
  static Future<void> addInApp({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    _addInApp(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, body: body, type: type, time: DateTime.now(), data: data,
    ));
  }

}
