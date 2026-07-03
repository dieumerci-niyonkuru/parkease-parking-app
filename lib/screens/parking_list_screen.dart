import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../widgets/branded_loader.dart';

class ParkingListScreen extends StatefulWidget {
  const ParkingListScreen({super.key});
  @override State<ParkingListScreen> createState() => _ParkingListScreenState();
}

class _ParkingListScreenState extends State<ParkingListScreen> {
  List<ParkingFacility> _all      = [];
  bool _loading = true;
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 5;

  @override void initState()  { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getAllParking();
    if (!mounted) return;
    setState(() { 
      _all = list; 
      _loading = false; 
    });
  }

  @override Widget build(BuildContext context) {
    final query = context.watch<AppProvider>().searchQuery.toLowerCase().trim();
    
    final filtered = query.isEmpty
        ? _all
        : _all.where((f) =>
            f.fullParkName.toLowerCase().contains(query) ||
            f.address.toLowerCase().contains(query)).toList();

    final totalPages = (filtered.length / _pageSize).ceil();
    
    // Safety check for current page
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }

    final start = _currentPage * _pageSize;
    final end = (start + _pageSize) > filtered.length ? filtered.length : (start + _pageSize);
    final items = (start < filtered.length) ? filtered.sublist(start, end) : [];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Column(
        children: [
          // ── SEARCH HEADER ──────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PARKING SITE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Trigger search globally via provider
                      context.read<AppProvider>().updateSearchQuery('');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Use the search bar in the top header for quick lookups!'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    label: const Text('QUICKLY SEARCH SITE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_loading)
            const Expanded(child: BrandedLoader(message: 'Syncing facilities...'))
          else if (filtered.isEmpty)
            const Expanded(child: _EmptySearch())
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: AppTheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final f = items[i];
                    return _ParkingSiteCard(
                      facility: f,
                      onTap: () => Navigator.of(context).pushNamed('parking_detail', arguments: f),
                    ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideX(begin: 0.05);
                  },
                ),
              ),
            ),

          // ── PAGINATION CONTROLS ──────────────────────────────────
          if (!_loading && filtered.isNotEmpty && totalPages > 1)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PageButton(
                      label: 'BACK',
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    ),
                    Text('PAGE ${_currentPage + 1} OF $totalPages', 
                      style: AppTheme.label.copyWith(fontWeight: FontWeight.w900, color: AppTheme.primary)),
                    _PageButton(
                      label: 'NEXT',
                      icon: Icons.arrow_forward_ios_rounded,
                      isReverse: true,
                      onPressed: (_currentPage + 1) < totalPages ? () => setState(() => _currentPage++) : null,
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

class _ParkingSiteCard extends StatelessWidget {
  final ParkingFacility facility;
  final VoidCallback onTap;
  const _ParkingSiteCard({required this.facility, required this.onTap});

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.location_city_rounded, color: AppTheme.primary, size: 24),
                const SizedBox(width: 14),
                Expanded(child: Text(facility.fullParkName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF212529)))),
                Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary.withOpacity(0.5), size: 14),
              ],
            ),
            const Divider(height: 24, thickness: 0.5),
            _Row('LOCATION', facility.address),
            _Row('AVAILABLE', '${facility.parkingLots} SPOTS', isLast: true),
          ],
        ),
      ),
    );
  }

  Widget _Row(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF212529))),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isReverse;

  const _PageButton({required this.label, required this.icon, this.onPressed, this.isReverse = false});

  @override Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: isReverse ? Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)) : Icon(icon, size: 14),
      label: isReverse ? Icon(icon, size: 14) : Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
      style: TextButton.styleFrom(
        foregroundColor: onPressed != null ? AppTheme.primary : Colors.grey.shade400,
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, color: AppTheme.textHint.withOpacity(0.3), size: 64),
      const SizedBox(height: 16),
      Text('No sites found.', style: AppTheme.heading4.copyWith(color: AppTheme.textMuted)),
    ]),
  );
}
