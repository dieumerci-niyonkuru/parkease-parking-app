import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override void initState() {
    super.initState();
    NotificationService.markAllRead();
    setState(() {});
  }

  @override Widget build(BuildContext context) {
    final notifs = NotificationService.notifications;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Text('Notifications', style: AppTheme.heading4),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context)),
        actions: [
          if (notifs.isNotEmpty)
            TextButton(
              onPressed: () {
                NotificationService.clearAll();
                setState(() {});
              },
              child: Text('Clear', style: AppTheme.body.copyWith(color: AppTheme.danger))),
        ],
      ),
      body: notifs.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.notifications_off_outlined, color: AppTheme.textHint, size: 56),
            const SizedBox(height: 14),
            Text('No notifications', style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
            const SizedBox(height: 6),
            Text('Activity alerts will appear here', style: AppTheme.body),
          ]))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifs.length,
            itemBuilder: (_, i) {
              final n = notifs[i];
              return _NotifCard(notif: n)
                .animate().fadeIn(delay: Duration(milliseconds: i * 40)).slideX(begin: -0.03);
            },
          ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final AppNotification notif;
  const _NotifCard({required this.notif});

  Color get _color => switch (notif.type) {
    NotificationType.payment  => AppTheme.success,
    NotificationType.reminder => AppTheme.warning,
    NotificationType.alert    => AppTheme.danger,
    NotificationType.system   => AppTheme.primary,
  };

  IconData get _icon => switch (notif.type) {
    NotificationType.payment  => Icons.check_circle_rounded,
    NotificationType.reminder => Icons.access_time_rounded,
    NotificationType.alert    => Icons.warning_rounded,
    NotificationType.system   => Icons.info_rounded,
  };

  @override Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notif.isRead ? AppTheme.bgCard : _color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: notif.isRead ? AppTheme.border : _color.withValues(alpha: 0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(_icon, color: _color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(notif.title,
              style: AppTheme.body.copyWith(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600))),
            if (!notif.isRead)
              Container(width: 8, height: 8,
                decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          ]),
          const SizedBox(height: 4),
          Text(notif.body, style: AppTheme.bodySmall),
          const SizedBox(height: 6),
          Text(DateFormat('d MMM · HH:mm').format(notif.time), style: AppTheme.label),
        ])),
      ]),
    );
  }
}
