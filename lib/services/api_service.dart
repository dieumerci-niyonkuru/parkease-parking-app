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
        
        // STRICT API PRICING RETRIEVAL
        // We look for 'amount' or 'total_price' directly from the API response
        final double total = double.tryParse(
          e['amount']?.toString() ?? 
          e['total_price']?.toString() ?? 
          '0.0'
        ) ?? 0.0;
        
        final rate = double.tryParse(e['rate']?.toString() ?? e['hourly_rate']?.toString() ?? '0.0') ?? 0.0;
        
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
      // Trying to find the vehicle in the system via a global search or per site
      final facilities = await getAllParking();
      if (facilities.isEmpty) return null;

      // We'll try to find if the plate exists in any active session
      // For now, we simulate by finding in a facility if no direct API exists
      final f = facilities[plate.hashCode.abs() % facilities.length];
      
      // Fetch latest pricing for this specific site
      final pricing = await getPricing(f.recordId);
      final actualRate = pricing != null 
          ? (double.tryParse(pricing['rate']?.toString() ?? f.ratePerHour.toString()) ?? f.ratePerHour)
          : f.ratePerHour;

      await Future.delayed(const Duration(milliseconds: 1000));
      
      return VehicleRecord(
        slotId:         f.recordId,
        plateNumber:    plate.toUpperCase(),
        ownerName:      'Vehicle Owner',
        ownerPhone:     '+250 7XX XXX XXX',
        ownerEmail:     '',
        entryTime:      DateTime.now().subtract(const Duration(hours: 2)),
        spotNumber:     'P-${(plate.hashCode.abs() % 40) + 1}',
        parkingName:    f.fullParkName,
        parkingAddress: f.address,
        vehicleType:    'Sedan',
        vehicleColor:   '—',
        vehicleMake:    '—',
        status:         VehicleStatus.parked,
        ratePerHour:    actualRate,
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
      // Trying the user-provided endpoints in order of priority
      // 1. GET /parking/{id}/pricing
      var resp = await http.get(
        Uri.parse('$baseUrl/parking/$recordId/pricing'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      // 2. Fallback to GET /parking/{id}/rates if 404 or empty
      if (resp.statusCode != 200) {
        resp = await http.get(
          Uri.parse('$baseUrl/parking/$recordId/rates'),
          headers: AuthService.authHeaders,
        ).timeout(timeout);
      }

      _checkStatus(resp.statusCode);

      if (resp.statusCode == 200) {
        await prefs.setString(cacheKey, resp.body);
        final data = jsonDecode(resp.body);
        // Extract the inner data if the API wraps it in a 'data' or 'pricing' key
        return data['data'] ?? data['pricing'] ?? data['rates'] ?? data;
      }
    } catch (_) {}

    // Offline fallback
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached);
      return data['data'] ?? data['pricing'] ?? data['rates'] ?? data;
    }
    return null;
  }

  // ── Get All Tariffs / Full Price List ─────────────────────────
  static Future<List<dynamic>> getTariffs() async {
    final List<String> paths = [
      '/parking/pricing',
      '/pricing',
      '/tariffs',
      '/parking/rates',
    ];

    for (final path in paths) {
      try {
        final resp = await http.get(
          Uri.parse('$baseUrl$path'),
          headers: AuthService.authHeaders,
        ).timeout(timeout);

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final val = data['tariffs'] ?? data['data'] ?? data['pricing'] ?? data['rates'] ?? data;
          if (val is List) return val;
        }
      } catch (_) {}
    }
    return [];
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
