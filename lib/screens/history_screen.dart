import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<HistoryEntry> _all      = [];
  List<HistoryEntry> _filtered = [];
  bool _loading    = true;
  bool _tableView  = true; // default to table view; users can switch to cards

  DateTime? _from;
  DateTime? _to;

  late final TabController _tabController;

  static final _dateFmt  = DateFormat('dd MMM yyyy');
  static final _moneyFmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    // Default to Today
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day);
    _to   = DateTime(now.year, now.month, now.day);
    _load();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _applyTabFilter();
    }
  }

  void _applyTabFilter() {
    final now = DateTime.now();
    setState(() {
      switch (_tabController.index) {
        case 0: // Today
          _from = DateTime(now.year, now.month, now.day);
          _to   = DateTime(now.year, now.month, now.day);
          break;
        case 1: // Week
          _from = now.subtract(Duration(days: now.weekday - 1));
          _from = DateTime(_from!.year, _from!.month, _from!.day);
          _to   = now;
          break;
        case 2: // Month
          _from = DateTime(now.year, now.month, 1);
          _to   = now;
          break;
        case 3: // All
          _from = null;
          _to   = null;
          break;
      }
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    
    final fmt = DateFormat('yyyy-MM-dd');
    final startDate = _from != null ? fmt.format(_from!) : null;
    final endDate   = _to != null ? fmt.format(_to!) : null;

    final phone = AuthService.user?.phone;

    List<HistoryEntry> list = await ApiService.getReceipts(
      startDate: startDate,
      endDate: endDate,
      phone: phone,
    );

    if (!mounted) return;
    setState(() {
      _all      = list;
      _loading  = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_from == null && _to == null) {
      _filtered = List.from(_all);
    } else {
      final from = _from ?? DateTime(2000);
      final to   = (_to ?? DateTime.now()).add(const Duration(days: 1));
      _filtered  = _all.where((e) =>
        e.entryTime.isAfter(from) && e.entryTime.isBefore(to)).toList();
    }
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: (_from != null && _to != null)
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.bgCard,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (range == null) return;
    setState(() {
      _from = range.start;
      _to   = range.end;
    });
    _load();
  }

  void _clearFilter() => setState(() {
    _from = null; _to = null; _applyFilter();
  });

  String _durationStr(HistoryEntry e) {
    final end = e.exitTime ?? DateTime.now();
    final d   = end.difference(e.entryTime);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    final h = d.inHours; final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = _from != null || _to != null;
    final query = context.watch<AppProvider>().searchQuery.toLowerCase().trim();

    var displayRecords = query.isEmpty
      ? _filtered
      : _filtered.where((e) =>
          e.plateNumber.toLowerCase().contains(query) ||
          e.parkingName.toLowerCase().contains(query) ||
          (e.receiptNumber?.toLowerCase().contains(query) ?? false)).toList();

    final totalPaid = displayRecords.fold<double>(0, (s, e) => s + (e.amountPaid ?? 0));
    final count = displayRecords.length;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── HEADER ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
            color: Colors.white,
            child: Column(
              children: [
                const Text('RECEIPT HISTORY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF212529), letterSpacing: 1)),
                const SizedBox(height: 4),
                Text('Official Parking Records'.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 2)),

                // ── SPEND SUMMARY (always visible) ──────────────
                if (!_loading && count > 0) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 5))],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('TOTAL PAID', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          const SizedBox(height: 2),
                          Text('RWF ${_moneyFmt.format(totalPaid.toInt())}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        Text(count == 1 ? 'RECEIPT' : 'RECEIPTS', style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      ]),
                    ]),
                  ).animate().fadeIn().slideY(begin: 0.1),
                ],
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textMuted,
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 3,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  tabs: const [
                    Tab(text: 'TODAY'),
                    Tab(text: 'WEEK'),
                    Tab(text: 'MONTH'),
                    Tab(text: 'ALL'),
                  ],
                ),
              ],
            ),
          ),

          Container(
            color: AppTheme.bgCard,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(_tableView ? 'TABLE VIEW' : 'CARD VIEW', 
                  style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _tableView = !_tableView),
                  icon: Icon(_tableView ? Icons.grid_view_rounded : Icons.table_chart_outlined, color: AppTheme.primary, size: 20),
                  tooltip: 'Switch View',
                ),
                IconButton(
                  onPressed: _pickRange,
                  icon: Icon(Icons.calendar_month_rounded, color: hasFilter ? AppTheme.primary : AppTheme.textMuted, size: 20),
                  tooltip: 'Filter Date',
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.sync_rounded, color: AppTheme.textMuted, size: 20),
                  tooltip: 'Sync History',
                ),
              ],
            ),
          ),
          
          if (hasFilter)
            Container(
              color: AppTheme.primary.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(children: [
                const Icon(Icons.filter_list_rounded, color: AppTheme.primary, size: 14),
                const SizedBox(width: 8),
                Text('${_dateFmt.format(_from!)} - ${_dateFmt.format(_to!)}', style: AppTheme.label.copyWith(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                const Spacer(),
                GestureDetector(onTap: _clearFilter, child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.primary)),
              ]),
            ),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _load,
              child: _loading
                  ? const BrandedLoader(message: 'Loading your receipts...')
                  : displayRecords.isEmpty
                      ? _EmptyState(hasFilter: hasFilter || query.isNotEmpty)
                      : _tableView
                          ? _TableView(entries: displayRecords)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                              itemCount: displayRecords.length,
                              itemBuilder: (ctx, i) {
                                final e = displayRecords[i];
                                return GestureDetector(
                                  onTap: () => Navigator.of(context).pushNamed('receipt_detail', arguments: e),
                                  child: _ReceiptCard(
                                    entry: e,
                                    dur: _durationStr(e),
                                    dtFmt: DateFormat('dd MMM yyyy, HH:mm'),
                                    moneyFmt: _moneyFmt,
                                  ).animate().fadeIn(delay: Duration(milliseconds: i * 30)).slideY(begin: 0.05),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableView extends StatelessWidget {
  final List<HistoryEntry> entries;
  const _TableView({required this.entries});

  static final _dateFmt  = DateFormat('dd/MM/yy');
  static final _timeFmt  = DateFormat('HH:mm');

  String _dur(HistoryEntry e) {
    final d = (e.exitTime ?? DateTime.now()).difference(e.entryTime);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    final h = d.inHours; final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppTheme.bgCard,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(children: [
          _TH('PLATE',       flex: 2),
          _TH('ENTRY',       flex: 3),
          _TH('EXIT',        flex: 3),
          _TH('DUR',         flex: 2),
          _TH('ACTION',      flex: 2, right: true),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: entries.length,
          itemBuilder: (ctx, i) {
            final e   = entries[i];
            final odd = i % 2 == 1;
            return Container(
              color: odd ? AppTheme.bgDeep.withValues(alpha: 0.3) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Expanded(
                  flex: 2,
                  child: Text(e.plateNumber, style: AppTheme.mono.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                ),
                Expanded(
                  flex: 3,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_dateFmt.format(e.entryTime), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    Text(_timeFmt.format(e.entryTime), style: AppTheme.label.copyWith(fontSize: 9)),
                  ]),
                ),
                Expanded(
                  flex: 3,
                  child: e.exitTime != null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_dateFmt.format(e.exitTime!), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        Text(_timeFmt.format(e.exitTime!), style: AppTheme.label.copyWith(fontSize: 9)),
                      ])
                    : const Text('Still Parked', style: TextStyle(fontSize: 9, color: AppTheme.warning, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_dur(e), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('receipt_detail', arguments: e),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('VIEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                      ),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

class _TH extends StatelessWidget {
  final String text;
  final int flex;
  final bool right;
  const _TH(this.text, {this.flex = 1, this.right = false});
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: AppTheme.label.copyWith(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.8)),
  );
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SummaryChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 6),
      Text(label, style: AppTheme.label.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    ]),
  );
}

class _ReceiptCard extends StatelessWidget {
  final HistoryEntry entry;
  final String dur;
  final DateFormat dtFmt;
  final NumberFormat moneyFmt;
  const _ReceiptCard({required this.entry, required this.dur, required this.dtFmt, required this.moneyFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.verified_rounded, color: AppTheme.success, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.parkingName, style: AppTheme.heading4.copyWith(fontSize: 14, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(entry.plateNumber, style: AppTheme.mono.copyWith(fontSize: 13, letterSpacing: 1.5, color: AppTheme.primary)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(entry.amountPaid != null ? 'RWF ${moneyFmt.format(entry.amountPaid!.toInt())}' : '—', style: AppTheme.heading4.copyWith(color: AppTheme.success, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(dur, style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 10)),
              ),
            ]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(color: AppTheme.bgDeep.withValues(alpha: 0.5), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
          child: Row(children: [
            Expanded(child: _TimeCell(label: 'ENTRY', time: entry.entryTime, icon: Icons.login_rounded, color: AppTheme.primary)),
            Container(width: 1, height: 32, color: AppTheme.border),
            Expanded(
              child: entry.exitTime != null
                ? _TimeCell(label: 'EXIT', time: entry.exitTime!, icon: Icons.logout_rounded, color: AppTheme.danger)
                : Padding(padding: const EdgeInsets.only(left: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('EXIT', style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text('Still parked', style: AppTheme.bodySmall.copyWith(color: AppTheme.warning, fontWeight: FontWeight.w600)),
                  ])),
            ),
            if (entry.receiptNumber != null)
              GestureDetector(
                onTap: entry.receiptUrl != null && entry.receiptUrl!.isNotEmpty
                    ? () async {
                        try {
                          final opened = await launchUrl(Uri.parse(entry.receiptUrl!), mode: LaunchMode.externalApplication);
                          if (!opened && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No app found to open this receipt.'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Couldn\'t open the receipt. Please try again.'), behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.success.withValues(alpha: 0.3))),
                  child: Text('EBM #${entry.receiptNumber}', style: AppTheme.label.copyWith(color: AppTheme.success, fontWeight: FontWeight.w800, fontSize: 9)),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _TimeCell extends StatelessWidget {
  final String label;
  final DateTime time;
  final IconData icon;
  final Color color;
  const _TimeCell({required this.label, required this.time, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 0, right: 12),
    child: Row(children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 8),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTheme.label.copyWith(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(DateFormat('dd MMM').format(time), style: AppTheme.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
        Text(DateFormat('HH:mm').format(time), style: AppTheme.label.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 10)),
      ]),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(hasFilter ? Icons.filter_list_off_rounded : Icons.receipt_long_rounded, color: AppTheme.textHint.withValues(alpha: 0.3), size: 80),
        const SizedBox(height: 20),
        Text(hasFilter ? 'No records in this date range' : 'No transaction history', style: AppTheme.heading3.copyWith(color: AppTheme.textMuted), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(hasFilter ? 'Try selecting a wider date range or clear the filter.' : 'Your official parking receipts will appear here after your first payment.', style: AppTheme.bodySmall, textAlign: TextAlign.center),
      ]),
    ),
  );
}
