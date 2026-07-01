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
    ratePerHour:  double.tryParse(j['rate_per_hour']?.toString() ?? j['hourly_rate']?.toString() ?? j['price_per_hour']?.toString() ?? '200') ?? 200,
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
  });

  Duration get duration {
    final end = exitTime ?? DateTime.now();
    return end.difference(entryTime);
  }

  double get totalAmount {
    final hours = duration.inMinutes / 60.0;
    return (hours * ratePerHour).ceilToDouble();
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
    final hours = duration.inMinutes / 60.0;
    return (hours * ratePerHour).ceilToDouble();
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

