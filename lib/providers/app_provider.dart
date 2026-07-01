import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/notification_service.dart';
import '../main.dart';

class AppProvider extends ChangeNotifier {
  AppProvider() {
    // Set up global session expiration handler
    ApiService.onSessionExpired = _handleSessionExpired;
  }

  void _handleSessionExpired() async {
    // Prevent multiple calls
    ApiService.onSessionExpired = null;
    
    await AuthService.logout();
    
    // Use the global navigator key to go back to login
    ITECParkingApp.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    
    // Show a snackbar or dialog if possible (navigator might be null if not yet built)
    final context = ITECParkingApp.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please login again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    // Re-enable the handler after a delay
    Future.delayed(const Duration(seconds: 5), () {
      ApiService.onSessionExpired = _handleSessionExpired;
    });
  }
  // ── Facilities ────────────────────────────────────────────────
  List<ParkingFacility> _facilities = [];
  List<ParkingFacility> get facilities => List.unmodifiable(_facilities);

  bool _facilitiesLoading = false;
  bool get facilitiesLoading => _facilitiesLoading;

  // ── History ───────────────────────────────────────────────────
  List<HistoryEntry> _history = [];
  List<HistoryEntry> get history => List.unmodifiable(_history);

  // ── Lookup ────────────────────────────────────────────────────
  VehicleRecord? _currentRecord;
  VehicleRecord? get currentRecord => _currentRecord;

  VehicleRecord? _activeSession;
  VehicleRecord? get activeSession => _activeSession;

  bool _lookupLoading = false;
  bool get lookupLoading => _lookupLoading;

  String? _lookupError;
  String? get lookupError => _lookupError;

  // ── Global Search ─────────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String q) {
    _searchQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  // ── Notifications ─────────────────────────────────────────────
  int get notifCount => NotificationService.unreadCount;

  // ── Init ──────────────────────────────────────────────────────
  Future<void> init() async {
    await Future.wait([
      loadFacilities(),
      loadHistory(),
    ]);
  }

  // ── Load facilities ───────────────────────────────────────────
  Future<void> loadFacilities() async {
    _facilitiesLoading = true;
    notifyListeners();

    _facilities = await ApiService.getAllParking();
    _facilitiesLoading = false;
    notifyListeners();
  }

  // ── Load history ──────────────────────────────────────────────
  Future<void> loadHistory() async {
    _history = await ApiService.getReceipts();
    notifyListeners();
  }

  // ── Lookup vehicle ────────────────────────────────────────────
  Future<void> lookupVehicle(String slotId) async {
    _lookupLoading = true;
    _lookupError  = null;
    _currentRecord = null;
    notifyListeners();

    try {
      final result = await ApiService.lookupVehicle(slotId);
      if (result == null) {
        _lookupError = 'No record found for "$slotId"';
      } else {
        _currentRecord = result;
        if (result.status == VehicleStatus.parked) {
          _activeSession = result;
        }
        await HistoryService.save(result);
        await loadHistory();

        if (result.duration.inHours >= 3) {
          await NotificationService.notifyLongParking(result);
        } else {
          await NotificationService.notifyVehicleLookup(result);
        }
      }
    } catch (e) {
      _lookupError = 'Lookup failed. Check your connection.';
    }

    _lookupLoading = false;
    notifyListeners();
  }

  // ── Process payment ───────────────────────────────────────────
  Future<VehicleRecord?> processPayment(VehicleRecord record) async {
    final exitTime = DateTime.now();
    final receipt  = 'ITEC-${record.slotId.replaceAll('-', '')}-'
        '${exitTime.millisecondsSinceEpoch.toString().substring(7)}';

    final paid = record.totalAmount;

    final updated = record.copyWith(
      status:        VehicleStatus.paid,
      amountPaid:    paid,
      receiptNumber: receipt,
      exitTime:      exitTime,
    );

    await HistoryService.save(updated);
    await HistoryService.updateStatus(
      updated.slotId, 'paid',
      amountPaid:    paid,
      receiptNumber: receipt,
      exitTime:      exitTime,
    );
    await NotificationService.notifyPaymentSuccess(updated);

    if (_activeSession?.slotId == updated.slotId) {
      _activeSession = null;
    }

    _currentRecord = updated;
    await loadHistory();
    notifyListeners();

    return updated;
  }

  // ── Delete history entry ──────────────────────────────────────
  Future<void> deleteHistoryEntry(String slotId) async {
    await HistoryService.deleteEntry(slotId);
    await loadHistory();
  }

  // ── Clear all history ─────────────────────────────────────────
  Future<void> clearHistory() async {
    await HistoryService.clearAll();
    await loadHistory();
  }

  // ── Clear lookup state ────────────────────────────────────────
  void clearLookup() {
    _currentRecord = null;
    _lookupError   = null;
    notifyListeners();
  }

  // ── Stats ─────────────────────────────────────────────────────
  int get totalLots =>
      _facilities.fold(0, (s, f) => s + f.parkingLots);

  int get totalFacilities => _facilities.length;

  int get paidCount =>
      _history.where((h) => h.status == 'paid').length;

  int get activeCount =>
      _history.where((h) => h.status == 'parked').length;

  double get totalRevenue =>
      _history
          .where((h) => h.amountPaid != null)
          .fold(0.0, (s, h) => s + (h.amountPaid ?? 0));
}
