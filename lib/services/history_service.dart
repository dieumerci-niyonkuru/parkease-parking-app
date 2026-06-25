import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'auth_service.dart';

class HistoryService {
  static const String _key = 'parking_history_v2';
  static const String _base = 'https://client-api.iteccone.com';
  static const Duration _timeout = Duration(seconds: 10);

  // ── Save record to history ────────────────────────────────────
  static Future<void> save(VehicleRecord record) async {
    // Attempt API save
    try {
      final payload = {
        'slotId': record.slotId,
        'plateNumber': record.plateNumber,
        'parkingName': record.parkingName,
        'entryTime': record.entryTime.toIso8601String(),
        'status': record.status,
      };
      await http.post(
        Uri.parse('$_base/history'),
        headers: AuthService.authHeaders,
        body: jsonEncode(payload),
      ).timeout(_timeout);
    } catch (_) {}

    // Fallback/Local Cache
    final prefs = await SharedPreferences.getInstance();
    final list = await getAll(forceLocal: true);

    list.removeWhere((h) => h.slotId == record.slotId);
    list.insert(0, HistoryEntry.fromRecord(record));
    if (list.length > 100) list.removeRange(100, list.length);

    await _saveLocal(prefs, list);
  }

  // ── Update existing entry status ──────────────────────────────
  static Future<void> updateStatus(
    String slotId,
    String newStatus, {
    double? amountPaid,
    String? receiptNumber,
    DateTime? exitTime,
  }) async {
    // Attempt API update
    try {
      final payload = {
        'status': newStatus,
        if (amountPaid != null) 'amountPaid': amountPaid,
        if (receiptNumber != null) 'receiptNumber': receiptNumber,
        if (exitTime != null) 'exitTime': exitTime.toIso8601String(),
      };
      await http.put(
        Uri.parse('$_base/history/$slotId'),
        headers: AuthService.authHeaders,
        body: jsonEncode(payload),
      ).timeout(_timeout);
    } catch (_) {}

    // Fallback/Local Cache
    final list = await getAll(forceLocal: true);
    final idx = list.indexWhere((h) => h.slotId == slotId);
    if (idx < 0) return;

    list[idx].status = newStatus;
    if (amountPaid != null) list[idx].amountPaid = amountPaid;
    if (receiptNumber != null) list[idx].receiptNumber = receiptNumber;
    if (exitTime != null) list[idx].exitTime = exitTime;

    final prefs = await SharedPreferences.getInstance();
    await _saveLocal(prefs, list);
  }

  // ── Get all history ───────────────────────────────────────────
  static Future<List<HistoryEntry>> getAll({bool forceLocal = false}) async {
    if (!forceLocal && AuthService.isLoggedIn) {
      try {
        final resp = await http.get(
          Uri.parse('$_base/history'),
          headers: AuthService.authHeaders,
        ).timeout(_timeout);

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final list = (data['history'] as List?) ?? [];
          final entries = list.map((e) => HistoryEntry(
            slotId: e['slotId'],
            plateNumber: e['plateNumber'],
            ownerName: e['ownerName'],
            ownerPhone: e['ownerPhone'],
            ownerEmail: e['ownerEmail'],
            entryTime: DateTime.parse(e['entryTime']),
            exitTime: e['exitTime'] != null ? DateTime.parse(e['exitTime']) : null,
            spotNumber: e['spotNumber'],
            parkingName: e['parkingName'],
            parkingAddress: e['parkingAddress'],
            vehicleType: e['vehicleType'],
            vehicleColor: e['vehicleColor'],
            vehicleMake: e['vehicleMake'],
            status: e['status'],
            ratePerHour: (e['ratePerHour'] as num?)?.toDouble() ?? 0.0,
            amountPaid: e['amountPaid'] != null ? (e['amountPaid'] as num).toDouble() : null,
            receiptNumber: e['receiptNumber'],
            searchedAt: e['searchedAt'] != null ? DateTime.parse(e['searchedAt']) : DateTime.now(),
          )).toList();
          
          // Cache the API results locally
          final prefs = await SharedPreferences.getInstance();
          await _saveLocal(prefs, entries);
          return entries;
        }
      } catch (_) {}
    }

    // Fallback to local
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) {
      final j = jsonDecode(s) as Map<String, dynamic>;
      return HistoryEntry(
        slotId:         j['slotId'],
        plateNumber:    j['plateNumber'],
        ownerName:      j['ownerName'],
        ownerPhone:     j['ownerPhone'],
        ownerEmail:     j['ownerEmail'],
        entryTime:      DateTime.parse(j['entryTime']),
        exitTime:       j['exitTime'] != null ? DateTime.parse(j['exitTime']) : null,
        spotNumber:     j['spotNumber'],
        parkingName:    j['parkingName'],
        parkingAddress: j['parkingAddress'],
        vehicleType:    j['vehicleType'],
        vehicleColor:   j['vehicleColor'],
        vehicleMake:    j['vehicleMake'],
        status:         j['status'],
        ratePerHour:    (j['ratePerHour'] as num).toDouble(),
        amountPaid:     j['amountPaid'] != null ? (j['amountPaid'] as num).toDouble() : null,
        receiptNumber:  j['receiptNumber'],
        searchedAt:     DateTime.parse(j['searchedAt']),
      );
    }).toList();
  }

  // ── Delete single entry ───────────────────────────────────────
  static Future<void> deleteEntry(String slotId) async {
    try {
      await http.delete(
        Uri.parse('$_base/history/$slotId'),
        headers: AuthService.authHeaders,
      ).timeout(_timeout);
    } catch (_) {}

    final list = await getAll(forceLocal: true);
    list.removeWhere((h) => h.slotId == slotId);
    final prefs = await SharedPreferences.getInstance();
    await _saveLocal(prefs, list);
  }

  // ── Helper: Save local cache ──────────────────────────────────
  static Future<void> _saveLocal(SharedPreferences prefs, List<HistoryEntry> list) async {
    final encoded = list.map((h) => jsonEncode({
      'slotId': h.slotId, 'plateNumber': h.plateNumber,
      'ownerName': h.ownerName, 'ownerPhone': h.ownerPhone,
      'ownerEmail': h.ownerEmail,
      'entryTime': h.entryTime.toIso8601String(),
      'exitTime': h.exitTime?.toIso8601String(),
      'spotNumber': h.spotNumber,
      'parkingName': h.parkingName,
      'parkingAddress': h.parkingAddress,
      'vehicleType': h.vehicleType,
      'vehicleColor': h.vehicleColor,
      'vehicleMake': h.vehicleMake,
      'status': h.status,
      'ratePerHour': h.ratePerHour,
      'amountPaid': h.amountPaid,
      'receiptNumber': h.receiptNumber,
      'searchedAt': h.searchedAt.toIso8601String(),
    })).toList();
    await prefs.setStringList(_key, encoded);
  }

  // ── Clear all history ─────────────────────────────────────────
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<void> clear() => clearAll();

  // ── Get history count ─────────────────────────────────────────
  static Future<int> count() async {
    final list = await getAll(forceLocal: true);
    return list.length;
  }
}
