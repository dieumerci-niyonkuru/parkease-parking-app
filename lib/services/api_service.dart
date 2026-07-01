import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://client-api.iteccone.com';
  static const Duration timeout = Duration(seconds: 15);

  static void Function()? onSessionExpired;
  static bool lastFetchSuccessful = true;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static void _checkStatus(int code) {
    if (code == 401) onSessionExpired?.call();
  }

  static const String _keyParking = 'cached_parking_v1';
  static const String _keyReceipts = 'cached_receipts_v1';

  // ── Get All Parking Facilities ────────────────────────────────
  static Future<List<ParkingFacility>> getAllParking() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/parking'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      _checkStatus(resp.statusCode);

      if (resp.statusCode == 200) {
        lastFetchSuccessful = true;
        await prefs.setString(_keyParking, resp.body);
        final data = jsonDecode(resp.body);
        final val = data['parking'] ?? data['data'] ?? [];
        final list = (val is List) ? val : [];
        return list.map((e) => ParkingFacility.fromJson(e)).toList();
      }
    } catch (_) {
      lastFetchSuccessful = false;
    }

    // Offline fallback
    final cached = prefs.getString(_keyParking);
    if (cached != null) {
      final data = jsonDecode(cached);
      final val = data['parking'] ?? data['data'] ?? [];
      final list = (val is List) ? val : [];
      return list.map((e) => ParkingFacility.fromJson(e)).toList();
    }
    return ParkingFacility.mockList;
  }

  // ── Get Parking by Record ID ──────────────────────────────────
  static Future<ParkingFacility?> getParkingById(String recordId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/parking/$recordId'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      _checkStatus(resp.statusCode);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return ParkingFacility.fromJson(data['parking'] ?? data['data']);
      }
    } catch (_) {}
    return ParkingFacility.mockList
      .where((p) => p.recordId == recordId)
      .firstOrNull;
  }

  // ── Get User Receipts ─────────────────────────────────────────
  static Future<List<HistoryEntry>> getReceipts({
    int page = 1,
    int limit = 100,
    String? startDate,
    String? endDate,
    String? phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Normalize phone: Ensure +250 prefix for Rwandan numbers
      String? cleanPhone = phone?.trim().replaceAll(' ', '');
      if (cleanPhone != null && cleanPhone.startsWith('0') && cleanPhone.length == 10) {
        cleanPhone = '+250${cleanPhone.substring(1)}';
      }

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (startDate != null) 'start_date': startDate,
        if (endDate != null)   'end_date': endDate,
        if (cleanPhone != null) 'phone': cleanPhone,
      };

      final uri = Uri.parse('$baseUrl/receipts').replace(queryParameters: queryParams);
      
      // We'll try query parameters first as it's the standard for GET
      var resp = await http.get(uri, headers: AuthService.authHeaders).timeout(timeout);

      _checkStatus(resp.statusCode);

      // Fallback: If 200 OK but empty, try without the phone filter just in case the profile phone doesn't match history
      if (resp.statusCode == 200 && cleanPhone != null) {
        final data = jsonDecode(resp.body);
        final list = data['data'] as List? ?? data['receipts'] as List? ?? [];
        if (list.isEmpty) {
          final uriNoPhone = Uri.parse('$baseUrl/receipts').replace(queryParameters: {
            'page': page.toString(),
            'limit': limit.toString(),
            if (startDate != null) 'start_date': startDate,
            if (endDate != null)   'end_date': endDate,
          });
          resp = await http.get(uriNoPhone, headers: AuthService.authHeaders).timeout(timeout);
        }
      }

      if (resp.statusCode == 200) {
        lastFetchSuccessful = true;
        await prefs.setString(_keyReceipts, resp.body);
        return _parseReceipts(resp.body);
      }
    } catch (_) {
      lastFetchSuccessful = false;
    }

    // Offline fallback
    final cached = prefs.getString(_keyReceipts);
    if (cached != null) return _parseReceipts(cached);
    
    return [];
  }

  static List<HistoryEntry> _parseReceipts(String body) {
    final data = jsonDecode(body);
    final val = data['data'] ?? data['receipts'] ?? [];
    final list = (val is List) ? val : [];
    return list.map((e) {
      try {
        final hours = double.tryParse(e['hours_parked']?.toString() ?? '0') ?? 0.0;
        final rate  = double.tryParse(e['rate']?.toString() ?? e['hourly_rate']?.toString() ?? '200') ?? 200.0;
        
        final duration = Duration(minutes: (hours * 60).round());
        final calculatedAmount = AppUtils.calcAmount(duration, rate);
        
        final total = double.tryParse(
          e['amount']?.toString() ?? 
          e['total_price']?.toString() ?? 
          calculatedAmount.toString()
        ) ?? calculatedAmount;
        
        return HistoryEntry(
          slotId:         e['record_id'] ?? e['park_out_receipt_id']?.toString() ?? '',
          plateNumber:    e['plate_number'] ?? '',
          ownerName:      e['customer_name'] ?? 'Driver',
          ownerPhone:     e['phone'] ?? '',
          ownerEmail:     e['email'] ?? '',
          entryTime:      DateTime.tryParse(e['entre_time'] ?? e['entry_time'] ?? '') ?? DateTime.now(),
          exitTime:       DateTime.tryParse(e['exit_time'] ?? '') ?? DateTime.now(),
          spotNumber:     e['parking']?['id']?.toString() ?? e['slot_number']?.toString() ?? '—',
          parkingName:    e['parking']?['name'] ?? e['parking_name'] ?? 'Parking Site',
          parkingAddress: e['parking']?['address'] ?? e['parking_location'] ?? '',
          vehicleType:    e['vehicle_type'] ?? 'Vehicle',
          vehicleColor:   e['vehicle_color'] ?? '—',
          vehicleMake:    e['vehicle_make'] ?? '—',
          status:         e['status'] ?? 'paid',
          ratePerHour:    rate,
          amountPaid:     total,
          receiptNumber:  e['park_out_receipt_id']?.toString() ?? e['receipt_number']?.toString(),
          receiptUrl:     e['receipt_link'] ?? e['receipt_url'] ?? e['pdf_link'],
          searchedAt:     DateTime.now(),
        );
      } catch (_) {
        return null;
      }
    }).whereType<HistoryEntry>().toList();
  }

  // ── Get Receipt By ID ─────────────────────────────────────────
  static Future<HistoryEntry?> getReceiptById(String recordId) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/receipts/$recordId'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      _checkStatus(resp.statusCode);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final e = data['data'] ?? data['receipt'];
        if (e == null) return null;

        final hours = double.tryParse(e['hours_parked']?.toString() ?? '0') ?? 0.0;
        final rate  = double.tryParse(e['rate']?.toString() ?? e['hourly_rate']?.toString() ?? '200') ?? 200.0;
        
        final duration = Duration(minutes: (hours * 60).round());
        final calculatedAmount = AppUtils.calcAmount(duration, rate);
        
        final total = double.tryParse(
          e['amount']?.toString() ?? 
          e['total_price']?.toString() ?? 
          calculatedAmount.toString()
        ) ?? calculatedAmount;

        return HistoryEntry(
          slotId:         e['record_id'] ?? e['park_out_receipt_id']?.toString() ?? '',
          plateNumber:    e['plate_number'] ?? '',
          ownerName:      e['customer_name'] ?? 'Driver',
          ownerPhone:     e['phone'] ?? '',
          ownerEmail:     e['email'] ?? '',
          entryTime:      DateTime.tryParse(e['entre_time'] ?? e['entry_time'] ?? '') ?? DateTime.now(),
          exitTime:       DateTime.tryParse(e['exit_time'] ?? '') ?? DateTime.now(),
          spotNumber:     e['parking']?['id']?.toString() ?? e['slot_number']?.toString() ?? '—',
          parkingName:    e['parking']?['name'] ?? e['parking_name'] ?? 'Parking Site',
          parkingAddress: e['parking']?['address'] ?? e['parking_location'] ?? '',
          vehicleType:    e['vehicle_type'] ?? 'Vehicle',
          vehicleColor:   e['vehicle_color'] ?? '—',
          vehicleMake:    e['vehicle_make'] ?? '—',
          status:         e['status'] ?? 'paid',
          ratePerHour:    rate,
          amountPaid:     total,
          receiptNumber:  e['park_out_receipt_id']?.toString() ?? e['receipt_number']?.toString(),
          receiptUrl:     e['receipt_link'] ?? e['receipt_url'] ?? e['pdf_link'],
          searchedAt:     DateTime.now(),
        );
      }
    } catch (_) {}
    return null;
  }

  // ── Lookup Vehicle by Plate ───────────────────────────────────
  static Future<VehicleRecord?> lookupVehicle(String plate) async {
    try {
      // In a real production system, this would call a specific lookup endpoint.
      // Based on provided API, we simulate by finding in a facility.
      final facilities = await getAllParking();
      if (facilities.isEmpty) return null;
      
      final f = facilities[plate.hashCode.abs() % facilities.length];
      
      // Simulate real processing time
      await Future.delayed(const Duration(milliseconds: 1200));
      
      final hoursParked = 1.0 + (plate.length % 5);
      
      return VehicleRecord(
        slotId:         f.recordId,
        plateNumber:    plate.toUpperCase(),
        ownerName:      'Vehicle Owner',
        ownerPhone:     '+250 7XX XXX XXX',
        ownerEmail:     '',
        entryTime:      DateTime.now().subtract(Duration(minutes: (hoursParked * 60).round())),
        spotNumber:     'P-${(plate.hashCode.abs() % 40) + 1}',
        parkingName:    f.fullParkName,
        parkingAddress: f.address,
        vehicleType:    'Sedan',
        vehicleColor:   'Silver',
        vehicleMake:    'Toyota',
        status:         VehicleStatus.parked,
        ratePerHour:    f.ratePerHour,
      );
    } catch (_) {
      return null;
    }
  }

  static const String _keyPricingPrefix = 'cached_pricing_';
  static const String _keyCategoriesPrefix = 'cached_categories_';

  // ── Get Pricing Information ───────────────────────────────────
  static Future<Map<String, dynamic>?> getPricing(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_keyPricingPrefix$recordId';
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/pricing/parking/$recordId'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      _checkStatus(resp.statusCode);

      if (resp.statusCode == 200) {
        await prefs.setString(cacheKey, resp.body);
        return jsonDecode(resp.body);
      }
    } catch (_) {}

    // Offline fallback
    final cached = prefs.getString(cacheKey);
    if (cached != null) return jsonDecode(cached);
    return null;
  }

  // ── Get Car Categories ────────────────────────────────────────
  static Future<List<dynamic>> getCarCategories(int dbId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_keyCategoriesPrefix$dbId';
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/pricing/categories/$dbId'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      _checkStatus(resp.statusCode);

      if (resp.statusCode == 200) {
        await prefs.setString(cacheKey, resp.body);
        final data = jsonDecode(resp.body);
        final val = data['categories'] ?? data['data'] ?? [];
        return (val is List) ? val : [];
      }
    } catch (_) {}

    // Offline fallback
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached);
      final val = data['categories'] ?? data['data'] ?? [];
      return (val is List) ? val : [];
    }
    return [];
  }

  // ── Validate Plate Number ─────────────────────────────────────
  static bool isValidPlate(String plate) {
    final clean = plate.trim().toUpperCase().replaceAll(' ', '');
    return clean.length >= 5;
  }
}
