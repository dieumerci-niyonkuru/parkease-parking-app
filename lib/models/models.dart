import '../utils/app_utils.dart';

// ── Parking Facility ──────────────────────────────────────────────
class ParkingFacility {
  final int parkingId;
  final String fullParkName;
  final String address;
  final int parkingLots;
  final int dbId;
  final String dbName;
  final String recordId;
  final double ratePerHour; // Added explicitly

  const ParkingFacility({
    required this.parkingId,
    required this.fullParkName,
    required this.address,
    required this.parkingLots,
    required this.dbId,
    required this.dbName,
    required this.recordId,
    required this.ratePerHour,
  });

  factory ParkingFacility.fromJson(Map<String, dynamic> j) => ParkingFacility(
    parkingId:    j['parking_id']     ?? j['id'] ?? 0,
    fullParkName: j['full_park_name'] ?? j['name'] ?? '',
    address:      j['address']        ?? j['location'] ?? '',
    parkingLots:  j['parking_lots']   ?? j['total_slots'] ?? 0,
    dbId:         int.tryParse(j['db_id']?.toString() ?? '1') ?? 1,
    dbName:       j['db_name']        ?? '',
    recordId:     j['record_id']      ?? '',
    ratePerHour:  double.tryParse(j['rate_per_hour']?.toString() ?? j['hourly_rate']?.toString() ?? j['price_per_hour']?.toString() ?? j['correctPrice']?.toString() ?? j['correctprice']?.toString() ?? j['correct_price']?.toString() ?? j['price']?.toString() ?? j['amount']?.toString() ?? j['cost']?.toString() ?? j['fee']?.toString() ?? j['tariff']?.toString() ?? j['unit_price']?.toString() ?? j['parking_fee']?.toString() ?? '200') ?? 200,
  );

  static List<ParkingFacility> get mockList => [
    const ParkingFacility(parkingId:101, fullParkName:'Downtown Garage',     address:'123 KN 3 Ave, Kigali',       parkingLots:250, dbId:1, dbName:'Central DB', recordId:'1-101', ratePerHour: 200),
    const ParkingFacility(parkingId:102, fullParkName:'Kigali Airport Park', address:'500 Airport Road, Kanombe',   parkingLots:500, dbId:1, dbName:'Central DB', recordId:'1-102', ratePerHour: 500),
    const ParkingFacility(parkingId:103, fullParkName:'City Mall Parking',   address:'KG 11 Ave, Nyarugenge',       parkingLots:180, dbId:1, dbName:'Central DB', recordId:'1-103', ratePerHour: 200),
    const ParkingFacility(parkingId:104, fullParkName:'Remera Business Hub', address:'KG 9 Road, Remera',           parkingLots:120, dbId:2, dbName:'East DB',    recordId:'2-104', ratePerHour: 200),
    const ParkingFacility(parkingId:105, fullParkName:'Kimihurura Plaza',    address:'KG 622 St, Kimihurura',       parkingLots:80,  dbId:2, dbName:'East DB',    recordId:'2-105', ratePerHour: 300),
    const ParkingFacility(parkingId:106, fullParkName:'Nyamirambo Centre',   address:'KN 47 St, Nyamirambo',        parkingLots:95,  dbId:3, dbName:'West DB',    recordId:'3-106', ratePerHour: 200),
  ];
}

// ── Vehicle Record ─────────────────────────────────────────────────
class VehicleRecord {
  final String slotId;
  final String plateNumber;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String spotNumber;
  final String parkingName;
  final String parkingAddress;
  final String vehicleType;
  final String vehicleColor;
  final String vehicleMake;
  final VehicleStatus status;
  final double ratePerHour;
  final double? amountPaid;
  final String? receiptNumber;

  // ── Real payment fields (from POST /payment/lookup) ──────────────
  final int? dbId;             // tenant database id
  final String? pInId;         // park-in session id, needed to initiate payment
  final String? paymentType;   // 'checkout' or 'credit'
  final bool payable;          // false for postpaid/company accounts
  final String? blockMessage;  // shown when payable == false
  final double? amountOwed;    // server-computed amount due

  VehicleRecord({
    required this.slotId,
    required this.plateNumber,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.entryTime,
    this.exitTime,
    required this.spotNumber,
    required this.parkingName,
    required this.parkingAddress,
    required this.vehicleType,
    required this.vehicleColor,
    required this.vehicleMake,
    required this.status,
    required this.ratePerHour,
    this.amountPaid,
    this.receiptNumber,
    this.dbId,
    this.pInId,
    this.paymentType,
    this.payable = true,
    this.blockMessage,
    this.amountOwed,
  });

  // Build a record from a /payment/lookup match. The server computes the
  // amount owed and whether the vehicle can be self-paid, so we trust those
  // directly rather than recalculating locally.
  factory VehicleRecord.fromPaymentMatch(Map<String, dynamic> m, {String? fallbackPlate}) {
    final payable = m['payable'] != false; // default true unless explicitly false
    final hours = double.tryParse(m['hours']?.toString() ?? '0') ?? 0.0;
    final entry = DateTime.tryParse((m['entre_time'] ?? '').toString())
        ?? DateTime.now().subtract(Duration(minutes: (hours * 60).round()));
    final owed = double.tryParse(m['amount_owed']?.toString() ?? '');
    return VehicleRecord(
      slotId:         '${m['db_id'] ?? ''}-${m['p_in_id'] ?? m['parking_id'] ?? ''}',
      plateNumber:    (m['plate_no'] ?? fallbackPlate ?? '').toString().toUpperCase(),
      ownerName:      'Driver',
      ownerPhone:     '',
      ownerEmail:     '',
      entryTime:      entry,
      spotNumber:     m['parking_id']?.toString() ?? '—',
      parkingName:    m['db_name']?.toString() ?? 'Parking Site',
      parkingAddress: '',
      vehicleType:    'Vehicle',
      vehicleColor:   '—',
      vehicleMake:    '—',
      status:         VehicleStatus.parked,
      ratePerHour:    hours > 0 && owed != null ? owed / hours : 0,
      dbId:           int.tryParse(m['db_id']?.toString() ?? ''),
      pInId:          m['p_in_id']?.toString(),
      paymentType:    m['payment_type']?.toString(),
      payable:        payable,
      blockMessage:   m['message']?.toString(),
      amountOwed:     owed,
    );
  }

  Duration get duration {
    final end = exitTime ?? DateTime.now();
    return end.difference(entryTime);
  }

  // Prefer the server-computed amount owed; fall back to a local calc only
  // for demo/offline records that never went through /payment/lookup.
  double get totalAmount {
    return amountOwed ?? AppUtils.calcAmount(duration, ratePerHour);
  }

  String get durationDisplay {
    final d = duration;
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '$h hr${h > 1 ? "s" : ""}' : '$h hr${h > 1 ? "s" : ""} $m min';
  }

  VehicleRecord copyWith({
    DateTime? exitTime,
    VehicleStatus? status,
    double? amountPaid,
    String? receiptNumber,
  }) => VehicleRecord(
    slotId:         slotId,
    plateNumber:    plateNumber,
    ownerName:      ownerName,
    ownerPhone:     ownerPhone,
    ownerEmail:     ownerEmail,
    entryTime:      entryTime,
    exitTime:       exitTime      ?? this.exitTime,
    spotNumber:     spotNumber,
    parkingName:    parkingName,
    parkingAddress: parkingAddress,
    vehicleType:    vehicleType,
    vehicleColor:   vehicleColor,
    vehicleMake:    vehicleMake,
    status:         status        ?? this.status,
    ratePerHour:    ratePerHour,
    amountPaid:     amountPaid    ?? this.amountPaid,
    receiptNumber:  receiptNumber ?? this.receiptNumber,
    dbId:           dbId,
    pInId:          pInId,
    paymentType:    paymentType,
    payable:        payable,
    blockMessage:   blockMessage,
    amountOwed:     amountOwed,
  );

  static final Map<String, Map<String, dynamic>> _mockData = {
    '1-101': {'plate':'RAC 001 A','owner':'Jean Bosco Habimana',  'phone':'+250 788 123 456','email':'jeanbosco@gmail.com',   'hours':2.3,'spot':'A-12','type':'Sedan',    'color':'Silver','make':'Toyota Corolla'},
    '1-102': {'plate':'RAD 222 B','owner':'Marie Claire Uwase',   'phone':'+250 722 987 654','email':'mariecl@yahoo.com',     'hours':5.1,'spot':'B-05','type':'SUV',      'color':'Black', 'make':'Toyota RAV4'},
    '1-103': {'plate':'RAF 881 C','owner':'Patrick Niyonzima',    'phone':'+250 735 456 789','email':'patrickn@gmail.com',    'hours':1.2,'spot':'C-33','type':'Hatchback', 'color':'White', 'make':'VW Golf'},
    '2-104': {'plate':'RAB 445 D','owner':'Diane Mukamana',       'phone':'+250 788 234 567','email':'dianem@gmail.com',      'hours':7.5,'spot':'D-07','type':'Sedan',    'color':'Blue',  'make':'Honda Fit'},
    '2-105': {'plate':'RAE 730 E','owner':'Eric Mutabazi',        'phone':'+250 722 345 678','email':'ericm@gmail.com',       'hours':3.8,'spot':'E-02','type':'Pickup',   'color':'Grey',  'make':'Nissan Navara'},
    '3-106': {'plate':'RAG 112 F','owner':'Chantal Uwimana',      'phone':'+250 735 567 890','email':'chantaluw@yahoo.com',   'hours':0.8,'spot':'F-14','type':'Minivan',  'color':'Red',   'make':'Toyota Hiace'},
    '1-107': {'plate':'RAH 300 G','owner':'Robert Habimana',      'phone':'+250 788 678 901','email':'robh@gmail.com',        'hours':4.2,'spot':'G-22','type':'Sedan',    'color':'Brown', 'make':'Subaru Impreza'},
    '1-108': {'plate':'RAI 550 H','owner':'Solange Ingabire',     'phone':'+250 722 789 012','email':'solangei@gmail.com',    'hours':1.7,'spot':'H-08','type':'SUV',      'color':'White', 'make':'Toyota Fortuner'},
    '2-109': {'plate':'RAJ 770 I','owner':'Claude Nzeyimana',     'phone':'+250 735 890 123','email':'claudenz@gmail.com',    'hours':6.0,'spot':'I-19','type':'Sedan',    'color':'Black', 'make':'Mercedes C200'},
    '3-110': {'plate':'RAK 990 J','owner':'Amina Kayitesi',       'phone':'+250 788 901 234','email':'aminak@yahoo.com',      'hours':2.9,'spot':'J-03','type':'Hatchback','color':'Green', 'make':'Kia Picanto'},
  };

  factory VehicleRecord.fromMock(String slotId, ParkingFacility facility) {
    final d = _mockData[slotId] ?? {
      'plate': 'RAX ${(slotId.hashCode.abs() % 999).toString().padLeft(3, "0")} Z',
      'owner': 'Vehicle Owner',
      'phone': '+250 700 000 000',
      'email': 'owner@example.com',
      'hours': 1.5,
      'spot':  'X-01',
      'type':  'Sedan',
      'color': 'White',
      'make':  'Unknown',
    };
    final hours = (d['hours'] as num).toDouble();
    final entry = DateTime.now().subtract(
      Duration(minutes: (hours * 60).round()),
    );
    return VehicleRecord(
      slotId:         slotId,
      plateNumber:    d['plate']  as String,
      ownerName:      d['owner']  as String,
      ownerPhone:     d['phone']  as String,
      ownerEmail:     d['email']  as String,
      entryTime:      entry,
      spotNumber:     d['spot']   as String,
      parkingName:    facility.fullParkName,
      parkingAddress: facility.address,
      vehicleType:    d['type']   as String,
      vehicleColor:   d['color']  as String,
      vehicleMake:    d['make']   as String,
      status:         VehicleStatus.parked,
      ratePerHour:    facility.ratePerHour == 0 ? 200 : facility.ratePerHour,
    );
  }

  Map<String, dynamic> toJson() => {
    'slotId':         slotId,
    'plateNumber':    plateNumber,
    'ownerName':      ownerName,
    'ownerPhone':     ownerPhone,
    'ownerEmail':     ownerEmail,
    'entryTime':      entryTime.toIso8601String(),
    'exitTime':       exitTime?.toIso8601String(),
    'spotNumber':     spotNumber,
    'parkingName':    parkingName,
    'parkingAddress': parkingAddress,
    'vehicleType':    vehicleType,
    'vehicleColor':   vehicleColor,
    'vehicleMake':    vehicleMake,
    'status':         status.name,
    'ratePerHour':    ratePerHour,
    'amountPaid':     amountPaid,
    'receiptNumber':  receiptNumber,
  };
}

// ── Status Enum ────────────────────────────────────────────────────
enum VehicleStatus { parked, paid, exited }

// ── History Entry ──────────────────────────────────────────────────
class HistoryEntry {
  String slotId;
  String plateNumber;
  String ownerName;
  String ownerPhone;
  String ownerEmail;
  DateTime entryTime;
  DateTime? exitTime;
  String spotNumber;
  String parkingName;
  String parkingAddress;
  String vehicleType;
  String vehicleColor;
  String vehicleMake;
  String status;
  double ratePerHour;
  double? amountPaid;
  String? receiptNumber;
  String? receiptUrl;
  DateTime searchedAt;

  HistoryEntry({
    required this.slotId,
    required this.plateNumber,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.entryTime,
    this.exitTime,
    required this.spotNumber,
    required this.parkingName,
    required this.parkingAddress,
    required this.vehicleType,
    required this.vehicleColor,
    required this.vehicleMake,
    required this.status,
    required this.ratePerHour,
    this.amountPaid,
    this.receiptNumber,
    this.receiptUrl,
    required this.searchedAt,
  });

  factory HistoryEntry.fromRecord(VehicleRecord r) => HistoryEntry(
    slotId:         r.slotId,
    plateNumber:    r.plateNumber,
    ownerName:      r.ownerName,
    ownerPhone:     r.ownerPhone,
    ownerEmail:     r.ownerEmail,
    entryTime:      r.entryTime,
    exitTime:       r.exitTime,
    spotNumber:     r.spotNumber,
    parkingName:    r.parkingName,
    parkingAddress: r.parkingAddress,
    vehicleType:    r.vehicleType,
    vehicleColor:   r.vehicleColor,
    vehicleMake:    r.vehicleMake,
    status:         r.status.name,
    ratePerHour:    r.ratePerHour,
    amountPaid:     r.amountPaid,
    receiptNumber:  r.receiptNumber,
    searchedAt:     DateTime.now(),
  );

  Duration get duration {
    final end = exitTime ?? DateTime.now();
    return end.difference(entryTime);
  }

  double get totalAmount {
    if (amountPaid != null) return amountPaid!;
    return AppUtils.calcAmount(duration, ratePerHour);
  }

  String get durationDisplay {
    final d = duration;
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '$h hr${h > 1 ? "s" : ""}' : '$h hr${h > 1 ? "s" : ""} $m min';
  }
}

// ── Notification Model ─────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id, title: title, body: body,
    type: type, time: time,
    isRead: isRead ?? this.isRead, data: data,
  );
}

enum NotificationType { payment, reminder, system, alert }

// ── Status Extension ───────────────────────────────────────────────
// NOTE: statusLabel, statusColor, statusIcon are in lib/widgets/widgets.dart
//       as `extension VehicleStatusExt on String`.
extension StatusStringExt on String {
  String get statusLabelShort {
    switch (toLowerCase()) {
      case 'parked': return 'Parked';
      case 'paid':   return 'Paid';
      case 'exited': return 'Exited';
      default:       return 'Unknown';
    }
  }
}

// ── Pricing Data ─────────────────────────────────────────────────
// Real API shape (GET /pricing/parking/{record_id}):
// {
//   "categories": [
//     { "category": {"id":1,"name":"Small Car","symbol":"S"},
//       "prices": [ {"hours":0,"price":200,...}, {"hours":1,"price":200,...}, ... ] }
//   ],
//   "currency": "Frw", "has_categories": false,
//   "parking_id": "6", "db_id": "1", "record_id": "1-6"
// }
// Prices are a real per-hour lookup table, not a flat rate to multiply.

class PriceTier {
  final int hours;
  final double price;
  const PriceTier({required this.hours, required this.price});

  factory PriceTier.fromJson(Map<String, dynamic> j) => PriceTier(
    hours: int.tryParse(j['hours']?.toString() ?? '0') ?? 0,
    price: double.tryParse(j['price']?.toString() ?? '0') ?? 0,
  );
}

class PriceCategory {
  final int id;
  final String name;
  final String? symbol;
  final List<PriceTier> tiers;

  const PriceCategory({
    required this.id,
    required this.name,
    this.symbol,
    required this.tiers,
  });

  factory PriceCategory.fromJson(Map<String, dynamic> j) {
    final cat = (j['category'] as Map?)?.cast<String, dynamic>() ?? const {};
    final pricesRaw = (j['prices'] as List?) ?? const [];
    final tiers = pricesRaw
        .whereType<Map>()
        .map((p) => PriceTier.fromJson(p.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => a.hours.compareTo(b.hours));
    return PriceCategory(
      id: int.tryParse(cat['id']?.toString() ?? '0') ?? 0,
      name: cat['name']?.toString() ?? 'General',
      symbol: cat['symbol']?.toString(),
      tiers: tiers,
    );
  }

  /// Real price for the given whole-hour duration, looked up from the
  /// backend's actual (possibly non-linear) price table. Falls back to the
  /// nearest lower tier, or the highest tier if [hours] exceeds the table.
  double? priceForHours(int hours) {
    if (tiers.isEmpty) return null;
    PriceTier? exact;
    PriceTier? nearestBelow;
    for (final t in tiers) {
      if (t.hours == hours) exact = t;
      if (t.hours <= hours && (nearestBelow == null || t.hours > nearestBelow.hours)) {
        nearestBelow = t;
      }
    }
    return (exact ?? nearestBelow ?? tiers.last).price;
  }
}

class PricingData {
  final List<PriceCategory> categories;
  final String currency;
  final bool hasCategories;

  const PricingData({
    required this.categories,
    required this.currency,
    required this.hasCategories,
  });

  factory PricingData.fromJson(Map<String, dynamic> j) {
    final catsRaw = (j['categories'] as List?) ?? const [];
    final categories = catsRaw
        .whereType<Map>()
        .map((c) => PriceCategory.fromJson(c.cast<String, dynamic>()))
        .toList();
    return PricingData(
      categories: categories,
      currency: j['currency']?.toString() ?? 'RWF',
      hasCategories: j['has_categories'] == true,
    );
  }

  PriceCategory? get general => categories.isEmpty ? null : categories.first;

  /// The real 1-hour price for the general category — used where a single
  /// comparable rate is needed (e.g. facility list sorting/display).
  double get ratePerHour => general?.priceForHours(1) ?? 200;

  /// The real 24-hour price, if the backend defines a day tier.
  double? get ratePerDay => general?.priceForHours(24);
}

// ── Car Category ─────────────────────────────────────────────────
class CarCategory {
  final int id;
  final String name;
  final double rateMultiplier;
  final double? rate;
  final String? description;

  const CarCategory({
    required this.id,
    required this.name,
    required this.rateMultiplier,
    this.rate,
    this.description,
  });

  factory CarCategory.fromJson(Map<String, dynamic> j) => CarCategory(
    id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
    name: j['name'] ?? j['category_name'] ?? j['type'] ?? '',
    rateMultiplier: double.tryParse(
      j['rate_multiplier']?.toString() ??
      j['multiplier']?.toString() ??
      '1.0'
    ) ?? 1.0,
    rate: double.tryParse(
      j['rate']?.toString() ??
      j['price']?.toString() ??
      j['amount']?.toString() ??
      j['cost']?.toString() ??
      j['fee']?.toString() ??
      j['rate_per_hour']?.toString() ??
      j['hourly_rate']?.toString() ??
      '',
    ),
    description: j['description']?.toString(),
  );
}

// ── Database Config (Admin) ─────────────────────────────────────
class DatabaseConfig {
  final int id;
  final String name;
  final String type;
  final String host;
  final int port;
  final String databaseName;
  final String username;
  final bool isConnected;
  final String? status;
  final DateTime? createdAt;

  const DatabaseConfig({
    required this.id,
    required this.name,
    required this.type,
    required this.host,
    required this.port,
    required this.databaseName,
    required this.username,
    this.isConnected = false,
    this.status,
    this.createdAt,
  });

  factory DatabaseConfig.fromJson(Map<String, dynamic> j) => DatabaseConfig(
    id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
    name: j['name'] ?? j['db_name'] ?? '',
    type: j['type'] ?? j['db_type'] ?? 'mysql',
    host: j['host'] ?? j['db_host'] ?? '',
    port: int.tryParse(j['port']?.toString() ?? j['db_port']?.toString() ?? '3306') ?? 3306,
    databaseName: j['database_name'] ?? j['db_database'] ?? '',
    username: j['username'] ?? j['db_username'] ?? '',
    isConnected: j['is_connected'] ?? j['connected'] ?? false,
    status: j['status']?.toString(),
    createdAt: DateTime.tryParse(j['created_at'] ?? j['createdAt'] ?? ''),
  );
}

