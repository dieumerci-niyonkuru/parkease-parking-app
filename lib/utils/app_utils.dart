import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  // ── Currency Formatter ────────────────────────────────────────
  static String formatRwf(double amount) {
    final formatted = NumberFormat('#,###', 'en_US').format(amount.toInt());
    return 'RWF $formatted';
  }

  static String formatRwfCompact(double amount) {
    if (amount >= 1000000) {
      return 'RWF ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'RWF ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatRwf(amount);
  }

  // ── Date / Time Formatters ─────────────────────────────────────
  static String formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('HH:mm:ss').format(dt);

  static String formatTimeShort(DateTime dt) =>
      DateFormat('HH:mm').format(dt);

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy  HH:mm').format(dt);

  static String formatDateTimeFull(DateTime dt) =>
      DateFormat('dd MMM yyyy  HH:mm:ss').format(dt);

  static String formatDateForReceipt(DateTime dt) =>
      DateFormat('EEEE, dd MMMM yyyy').format(dt);

  // ── Duration Formatter ────────────────────────────────────────
  static String formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds} sec';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (m == 0) return '$h hr${h > 1 ? 's' : ''}';
    return '$h hr${h > 1 ? 's' : ''} $m min';
  }

  static String formatDurationVerbose(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  // ── Amount Calculator ─────────────────────────────────────────
  static double calcAmount(Duration duration, double ratePerHour) {
    final double hours = duration.inMinutes / 60.0;
    final int h = hours.ceil();

    if (h <= 4) {
      return (h == 0 ? 1 : h) * 200.0;
    } else {
      // Logic for 5h and above: (h - 3) * 1000
      return (h - 3) * 1000.0;
    }
  }

  // ── Validators ────────────────────────────────────────────────
  static bool isValidSlotId(String id) {
    return RegExp(r'^\d+-\d+$').hasMatch(id.trim());
  }

  static bool isValidPlate(String plate) {
    final clean = plate.trim().toUpperCase().replaceAll(' ', '');
    // Rwanda: RA[A-Z] NNN [A-Z] format variants
    return clean.length >= 5;
  }

  static bool isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    return RegExp(r'^[0-9]{9,12}$').hasMatch(clean);
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-z]{2,}$',
            caseSensitive: false)
        .hasMatch(email.trim());
  }

  // ── Receipt Number Generator ──────────────────────────────────
  static String generateReceipt(String slotId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = timestamp.substring(timestamp.length - 6);
    final prefix = slotId.replaceAll('-', '').toUpperCase();
    return 'ITEC-$prefix-$suffix';
  }

  // ── Slot ID parser ────────────────────────────────────────────
  static Map<String, int>? parseSlotId(String id) {
    final parts = id.trim().split('-');
    if (parts.length != 2) return null;
    final dbId = int.tryParse(parts[0]);
    final parkId = int.tryParse(parts[1]);
    if (dbId == null || parkId == null) return null;
    return {'dbId': dbId, 'parkingId': parkId};
  }

  // ── String helpers ────────────────────────────────────────────
  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  // ── Color helpers for vehicle types ──────────────────────────
  static String vehicleTypeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'sedan':    return '🚗';
      case 'suv':      return '🚙';
      case 'pickup':   return '🛻';
      case 'minivan':  return '🚐';
      case 'hatchback':return '🚗';
      case 'bus':      return '🚌';
      case 'truck':    return '🚚';
      default:         return '🚘';
    }
  }
}
