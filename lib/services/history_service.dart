import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class HistoryService {
  static const String _key = 'parking_history_v2';

  // ── Save record to history ────────────────────────────────────
  static Future<void> save(VehicleRecord record) async {
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

  // ── Get all history (local only — no /history API exists) ─────
  static Future<List<HistoryEntry>> getAll({bool forceLocal = false}) async {
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
      'receiptUrl': h.receiptUrl,
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
