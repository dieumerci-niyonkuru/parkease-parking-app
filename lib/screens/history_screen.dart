import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/history_service.dart';
import '../services/api_service.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';
import 'receipt_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _all      = [];
  List<HistoryEntry> _filtered = [];
  bool _loading    = true;
  bool _tableView  = false;

  DateTime? _from;
  DateTime? _to;

  static final _dateFmt  = DateFormat('dd MMM yyyy');
  static final _timeFmt  = DateFormat('HH:mm');
  static final _moneyFmt = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    
    final fmt = DateFormat('yyyy-MM-dd');
    final startDate = _from != null ? fmt.format(_from!) : null;
    final endDate   = _to != null ? fmt.format(_to!) : null;

    final user = AuthService.user;
    // Fallback to names if phone is empty, as the username (phone) is often stored there
    final phone = (user?.phone.isNotEmpty == true) ? user!.phone : user?.names;

    // Strictly retrieve receipts from API only with server-side filtering
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
          colorScheme: ColorScheme.light(
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
    final query = context.watch<AppProvider>().searchQuery;

    var displayRecords = query.isEmpty 
      ? _filtered 
      : _filtered.where((e) => 
          e.plateNumber.toLowerCase().contains(query) || 
          e.parkingName.toLowerCase().contains(query)).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── FIXED TOP HEADER (Controls & Info) ────────────────────
          Container(
            color: AppTheme.bgCard,
            child: Column(
              children: [
                if (!ApiService.lastFetchSuccessful)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: AppTheme.warning.withOpacity(0.1),
                    child: Row(children: [
                      const Icon(Icons.cloud_off_rounded, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Internet connection lost. Showing your saved receipt history.', style: AppTheme.label.copyWith(color: AppTheme.warning, fontWeight: FontWeight.bold))),
                    ]),
                  ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      _SummaryChip(
                        icon: Icons.receipt_long_rounded,
                        label: '${displayRecords.length} records',
                        color: AppTheme.primary,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(() => _tableView = !_tableView),
                        icon: Icon(
                          _tableView ? Icons.view_list_rounded : Icons.table_chart_rounded,
                          color: _tableView ? AppTheme.primary : AppTheme.textMuted,
                          size: 22,
                        ),
                      ),
                      IconButton(
                        onPressed: _pickRange,
                        icon: Icon(Icons.date_range_rounded,
                            color: hasFilter ? AppTheme.primary : AppTheme.textMuted,
                            size: 22),
                      ),
                      IconButton(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppTheme.textMuted, size: 22),
                      ),
                    ],
                  ),
                ),

                if (!hasFilter)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickRange,
                        icon: const Icon(Icons.date_range_rounded, size: 18),
                        label: const Text('FILTER BY DATE', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bgDeep,
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                
                if (hasFilter)
                  Container(
                    color: AppTheme.primary.withOpacity(0.07),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(children: [
                      const Icon(Icons.filter_alt_rounded, color: AppTheme.primary, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        '${_dateFmt.format(_from!)} → ${_dateFmt.format(_to!)}',
                        style: AppTheme.label.copyWith(color: AppTheme.primary, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _clearFilter,
                        child: const Icon(Icons.close_rounded, size: 18, color: AppTheme.primary),
                      ),
                    ]),
                  ),
                
                Container(height: 1, color: AppTheme.border.withOpacity(0.5)),
              ],
            ),
          ),

          // ── SCROLLABLE CONTENT ──────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  if (_loading)
                    const SliverFillRemaining(
                      child: BrandedLoader(message: 'Retrieving your history...'),
                    )
                  else if (displayRecords.isEmpty)
                    SliverFillRemaining(
                      child: _EmptyState(hasFilter: hasFilter || query.isNotEmpty),
                    )
                  else if (_tableView)
                    SliverToBoxAdapter(
                      child: _TableView(entries: displayRecords),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final e = displayRecords[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  'receipt_detail',
                                  arguments: e,
                                );
                              },
                              child: _ReceiptCard(
                                entry: e,
                                dur: _durationStr(e),
                                dtFmt: DateFormat('dd MMM yyyy, HH:mm'),
                                moneyFmt: _moneyFmt,
                              ).animate().fadeIn(delay: Duration(milliseconds: i * 40)).slideY(begin: 0.08),
                            );
                          },
                          childCount: displayRecords.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  TABLE VIEW
// ═══════════════════════════════════════════════════════════════
class _TableView extends StatelessWidget {
  final List<HistoryEntry> entries;
  const _TableView({required this.entries});

  static final _dateFmt  = DateFormat('dd/MM/yy');
  static final _timeFmt  = DateFormat('HH:mm');
  static final _moneyFmt = NumberFormat('#,###');

  String _dur(HistoryEntry e) {
    final d = (e.exitTime ?? DateTime.now()).difference(e.entryTime);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    final h = d.inHours; final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Summary row ────────────────────────────────────────
      Container(
        color: AppTheme.bgCard,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          _SummaryChip(
            icon: Icons.payments_rounded,
            label: 'RWF ${_moneyFmt.format(entries.fold<double>(0, (s, e) => s + (e.amountPaid ?? 0)).toInt())} total',
            color: AppTheme.success,
          ),
        ]),
      ),
      const Divider(height: 1),

      // ── Table header ───────────────────────────────────────
      Container(
        color: AppTheme.bgCard,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(children: [
          _TH('PLATE',       flex: 3),
          _TH('ENTRY',       flex: 3),
          _TH('EXIT',        flex: 3),
          _TH('DUR',         flex: 2),
          _TH('AMOUNT',      flex: 3, right: true),
        ]),
      ),
      const Divider(height: 1),

      // ── Table rows ─────────────────────────────────────────
      Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: List.generate(entries.length, (i) {
              final e   = entries[i];
              final odd = i % 2 == 1;
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptDetailScreen(entry: e))),
                child: Container(
                  color: odd
                      ? AppTheme.bgDeep.withOpacity(0.5)
                      : AppTheme.bgCard,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  child: Row(children: [
                    // Plate
                    Expanded(
                      flex: 3,
                      child: Text(
                        e.plateNumber,
                        style: AppTheme.mono.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            letterSpacing: 1),
                      ),
                    ),
                    // Entry time
                    Expanded(
                      flex: 3,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_dateFmt.format(e.entryTime),
                            style: AppTheme.bodySmall
                                .copyWith(fontSize: 11)),
                        Text(_timeFmt.format(e.entryTime),
                            style: AppTheme.label.copyWith(
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    // Exit time
                    Expanded(
                      flex: 3,
                      child: e.exitTime != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text(_dateFmt.format(e.exitTime!),
                                  style: AppTheme.bodySmall
                                      .copyWith(fontSize: 11)),
                              Text(_timeFmt.format(e.exitTime!),
                                  style: AppTheme.label.copyWith(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w700)),
                            ])
                          : Text('—',
                              style: AppTheme.bodySmall
                                  .copyWith(color: AppTheme.textHint)),
                    ),
                    // Duration
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_dur(e),
                            style: AppTheme.label.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 10)),
                      ),
                    ),
                    // Amount
                    Expanded(
                      flex: 3,
                      child: Text(
                        e.amountPaid != null
                            ? 'RWF ${_moneyFmt.format(e.amountPaid!.toInt())}'
                            : '—',
                        textAlign: TextAlign.right,
                        style: AppTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: e.amountPaid != null
                                ? AppTheme.success
                                : AppTheme.textHint,
                            fontSize: 12),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
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
            style: AppTheme.label.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppTheme.textMuted,
                letterSpacing: 0.8)),
      );
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SummaryChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: AppTheme.label.copyWith(
                  color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════
//  CARD LIST VIEW
// ═══════════════════════════════════════════════════════════════
class _CardListView extends StatelessWidget {
  final List<HistoryEntry> entries;
  final String Function(HistoryEntry) durationStr;
  const _CardListView(
      {required this.entries, required this.durationStr});

  static final _dtFmt    = DateFormat('dd MMM yyyy, HH:mm');
  static final _moneyFmt = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i];
        return GestureDetector(
          onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ReceiptDetailScreen(entry: e))),
          child: _ReceiptCard(
            entry: e,
            dur: durationStr(e),
            dtFmt: _dtFmt,
            moneyFmt: _moneyFmt,
          ).animate().fadeIn(delay: Duration(milliseconds: i * 40)).slideY(begin: 0.08),
        );
      },
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final HistoryEntry entry;
  final String dur;
  final DateFormat dtFmt;
  final NumberFormat moneyFmt;
  const _ReceiptCard(
      {required this.entry,
      required this.dur,
      required this.dtFmt,
      required this.moneyFmt});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.border.withOpacity(0.5), width: 0.8),
        boxShadow: AppTheme.subtleShadow,
      ),
      child: Column(children: [
        // ── Top section ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppTheme.success, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(e.parkingName,
                    style: AppTheme.heading4
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(e.plateNumber,
                    style: AppTheme.mono.copyWith(
                        fontSize: 13,
                        letterSpacing: 1.5,
                        color: AppTheme.primary)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                e.amountPaid != null
                    ? 'RWF ${moneyFmt.format(e.amountPaid!.toInt())}'
                    : '—',
                style: AppTheme.heading4.copyWith(
                    color: AppTheme.success, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(dur,
                    style: AppTheme.label.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10)),
              ),
            ]),
          ]),
        ),

        // ── Time row ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgDeep.withOpacity(0.5),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(children: [
            // Entry
            Expanded(
              child: _TimeCell(
                label: 'ENTRY',
                time: e.entryTime,
                icon: Icons.login_rounded,
                color: AppTheme.primary,
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: AppTheme.border,
            ),
            // Exit
            Expanded(
              child: e.exitTime != null
                  ? _TimeCell(
                      label: 'EXIT',
                      time: e.exitTime!,
                      icon: Icons.logout_rounded,
                      color: AppTheme.danger,
                    )
                  : Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('EXIT',
                            style: AppTheme.label.copyWith(
                                fontSize: 9,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 3),
                        Text('Still parked',
                            style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
            ),
            // Receipt badge
            if (e.receiptNumber != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Text(
                  'EBM #${e.receiptNumber}',
                  style: AppTheme.label.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w800,
                      fontSize: 9),
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
  const _TimeCell(
      {required this.label,
      required this.time,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 0, right: 12),
        child: Row(children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: AppTheme.label.copyWith(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(DateFormat('dd MMM').format(time),
                style: AppTheme.bodySmall
                    .copyWith(fontSize: 11, fontWeight: FontWeight.w600)),
            Text(DateFormat('HH:mm').format(time),
                style: AppTheme.label.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 10)),
          ]),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool hasFilter;
  const _EmptyState({required this.hasFilter});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              hasFilter
                  ? Icons.filter_list_off_rounded
                  : Icons.receipt_long_rounded,
              color: AppTheme.textHint.withOpacity(0.3),
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              hasFilter
                  ? 'No records in this date range'
                  : 'No transaction history',
              style: AppTheme.heading3
                  .copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              hasFilter
                  ? 'Try selecting a wider date range or clear the filter.'
                  : 'Your official parking receipts will appear here after your first payment.',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
}
