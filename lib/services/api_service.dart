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

  static void _checkStatus(int code) {
    if (code == 401) {
      onSessionExpired?.call();
    }
  }

  // ── Generic HTTP Helpers ──────────────────────────────────────
  static Future<http.Response> post(String path, {Map<String, dynamic>? body}) {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: {...AuthService.authHeaders, 'Content-Type': 'application/json'},
      body: body != null ? jsonEncode(body) : '{}',
    ).timeout(timeout);
  }

  static Future<http.Response> get(String path) {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: AuthService.authHeaders,
    ).timeout(timeout);
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
        final val = data['parking'] ?? data['data'] ?? data['result'] ?? [];
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
      final val = data['parking'] ?? data['data'] ?? data['result'] ?? [];
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
        // STRICT API PRICING RETRIEVAL
        // We look for 'amount' or 'total_price' directly from the API response
        final double total = double.tryParse(
          e['amount']?.toString() ?? 
          e['total_price']?.toString() ?? 
          '0.0'
        ) ?? 0.0;
        
        final rate = double.tryParse(e['correctPrice']?.toString() ?? e['correctprice']?.toString() ?? e['correct_price']?.toString() ?? e['rate']?.toString() ?? e['hourly_rate']?.toString() ?? '0.0') ?? 0.0;
        
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
        final rate  = double.tryParse(e['correctPrice']?.toString() ?? e['correctprice']?.toString() ?? e['correct_price']?.toString() ?? e['rate']?.toString() ?? e['hourly_rate']?.toString() ?? '200') ?? 200.0;
        
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

  // ── Lookup Plate (real API: POST /payment/lookup) ─────────────
  // Searches every registered parking database for the plate and reports what
  // is owed. Returns the first match as a VehicleRecord (carrying the real
  // amount owed, db_id, p_in_id, payment_type and payable flag needed to pay).
  static Future<VehicleRecord?> lookupVehicle(String plate, {List<ParkingFacility>? facilities}) async {
    final result = await paymentLookup(plate);
    if (result['success'] == true) {
      final matches = (result['matches'] as List?) ?? [];
      if (matches.isNotEmpty) {
        return VehicleRecord.fromPaymentMatch(
          (matches.first as Map).cast<String, dynamic>(),
          fallbackPlate: plate,
          facilities: facilities,
        );
      }
    }
    return null; // not found / not currently parked → caller shows friendly message
  }

  /// POST /payment/lookup — returns {success, matches, message}.
  static Future<Map<String, dynamic>> paymentLookup(String plateNo, {int? dbId, int? parkingId}) async {
    try {
      final body = <String, dynamic>{'plate_no': plateNo.trim().toUpperCase()};
      if (dbId != null) body['db_id'] = dbId;
      if (parkingId != null) body['parking_id'] = parkingId;

      final resp = await http.post(
        Uri.parse('$baseUrl/payment/lookup'),
        headers: AuthService.authHeaders,
        body: jsonEncode(body),
      ).timeout(timeout);

      _checkStatus(resp.statusCode);
      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if (resp.statusCode == 200 && data['status'] == 'success') {
        return {'success': true, 'matches': data['matches'] ?? []};
      }
      if (resp.statusCode == 404) {
        return {'success': false, 'notFound': true, 'message': data['message'] ?? 'Plate not found or not currently parked.'};
      }
      return {'success': false, 'message': AppUtils.friendlyHttpError(resp.statusCode, serverMessage: data['message']?.toString())};
    } catch (_) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  /// POST /payment/initiate — starts a MoMo self-payment.
  /// Returns {success, reqRef, dbId, transactionId, message}.
  static Future<Map<String, dynamic>> paymentInitiate({
    required int dbId,
    required String plateNo,
    required String pInId,
    required String paymentType,
    required String payerPhone,
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/payment/initiate'),
        headers: AuthService.authHeaders,
        body: jsonEncode({
          'db_id': dbId,
          'plate_no': plateNo,
          'p_in_id': int.tryParse(pInId) ?? pInId,
          'payment_type': paymentType,
          'payer_phone': payerPhone,
        }),
      ).timeout(timeout);

      _checkStatus(resp.statusCode);
      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      if ((resp.statusCode == 202 || resp.statusCode == 200) && data['status'] == 'pending') {
        return {
          'success': true,
          'reqRef': data['req_ref']?.toString(),
          'dbId': data['db_id'] ?? dbId,
          'transactionId': data['transaction_id']?.toString(),
          'message': data['message'] ?? 'Payment initiated. Please approve on your phone.',
        };
      }
      return {'success': false, 'message': data['message']?.toString() ?? AppUtils.friendlyHttpError(resp.statusCode)};
    } catch (_) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  /// GET /payment/status/{db_id}/{req_ref} — poll payment completion.
  /// Returns {success, state: PENDING|SUCCESSFUL|FAILED, amount, charged}.
  static Future<Map<String, dynamic>> paymentStatus(int dbId, String reqRef) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/payment/status/$dbId/$reqRef'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (resp.statusCode == 200 && data['status'] == 'success') {
        final inner = (data['data'] as Map?)?.cast<String, dynamic>() ?? {};
        return {
          'success': true,
          'state': (inner['status'] ?? 'PENDING').toString().toUpperCase(),
          'amount': double.tryParse(inner['amount']?.toString() ?? ''),
          'charged': double.tryParse(inner['charged_amount']?.toString() ?? ''),
        };
      }
      return {'success': false, 'message': data['message']?.toString() ?? 'Could not check payment status.'};
    } catch (_) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  static const String _keyPricingPrefix = 'cached_pricing_';
  static const String _keyCategoriesPrefix = 'cached_categories_';

  // ── Get Pricing Information ───────────────────────────────────
  static Future<Map<String, dynamic>?> getPricing(String recordId) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_keyPricingPrefix$recordId';
    try {
      // API 2.0 path: GET /pricing/parking/{recordId}
      final resp = await http.get(
        Uri.parse('$baseUrl/pricing/parking/$recordId'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      _checkStatus(resp.statusCode);

      if (resp.statusCode == 200) {
        await prefs.setString(cacheKey, resp.body);
        final data = jsonDecode(resp.body);
        final inner = data['data'] ?? data['pricing'] ?? data['rates'] ?? data['result'] ?? data;
        if (inner is Map<String, dynamic>) return inner;
        return data;
      }
    } catch (_) {}

    // Offline fallback
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached);
      final inner = data['data'] ?? data['pricing'] ?? data['rates'] ?? data['result'] ?? data;
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return null;
  }

  // ── Get All Tariffs / Full Price List ─────────────────────────
  static Future<List<dynamic>> getTariffs() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/pricing'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final val = data['tariffs'] ?? data['data'] ?? data['pricing'] ?? data['rates'] ?? data;
        if (val is List) return val;
      }
    } catch (_) {}
    return [];
  }

  // ── Get Pricing (typed) ──────────────────────────────────────
  static Future<PricingData?> getPricingData(String recordId) async {
    final raw = await getPricing(recordId);
    if (raw == null) return null;
    return PricingData.fromJson(raw);
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
        final val = data['categories'] ?? data['data'] ?? data['result'] ?? [];
        return (val is List) ? val : [];
      }
    } catch (_) {}

    // Offline fallback
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final data = jsonDecode(cached);
      final val = data['categories'] ?? data['data'] ?? data['result'] ?? [];
      return (val is List) ? val : [];
    }
    return [];
  }

  // ── Get Car Categories (typed) ────────────────────────────────
  static Future<List<CarCategory>> getCarCategoryList(int dbId) async {
    final raw = await getCarCategories(dbId);
    return raw.map((e) {
      if (e is Map<String, dynamic>) return CarCategory.fromJson(e);
      return CarCategory(id: 0, name: e?.toString() ?? '', rateMultiplier: 1.0);
    }).toList();
  }

  // ── Database Admin: Get All ───────────────────────────────────
  static Future<List<Map<String, dynamic>>> getDatabases() async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/databases'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final val = data['databases'] ?? data['data'] ?? [];
        return (val is List) ? val.cast<Map<String, dynamic>>() : [];
      }
    } catch (_) {}
    return [];
  }

  // ── Database Admin: Get By ID ─────────────────────────────────
  static Future<Map<String, dynamic>?> getDatabaseById(int id) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/databases/$id'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['database'] ?? data['data'];
      }
    } catch (_) {}
    return null;
  }

  // ── Database Admin: Test Connection ──────────────────────────
  static Future<Map<String, dynamic>> testDatabaseConnection(int id) async {
    try {
      final resp = await http.get(
        Uri.parse('$baseUrl/databases/test/$id'),
        headers: AuthService.authHeaders,
      ).timeout(timeout);

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        return {'success': true, ...data};
      }
      return {
        'success': false,
        'message': AppUtils.friendlyHttpError(resp.statusCode,
            serverMessage: data['message']?.toString()),
      };
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Database Admin: Execute Query ────────────────────────────
  static Future<Map<String, dynamic>> executeQuery(int dbId, String query) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/databases/query/$dbId'),
        headers: AuthService.authHeaders,
        body: jsonEncode({'query': query}),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(resp.body);
      if (resp.statusCode == 200) {
        return {'success': true, ...data};
      }
      return {
        'success': false,
        'message': AppUtils.friendlyHttpError(resp.statusCode,
            serverMessage: data['message']?.toString()),
      };
    } catch (e) {
      return {'success': false, 'message': AppUtils.friendlyNetworkError()};
    }
  }

  // ── Validate Plate Number ─────────────────────────────────────
  static bool isValidPlate(String plate) {
    final clean = plate.trim().toUpperCase().replaceAll(' ', '');
    return clean.length >= 5;
  }
}
