import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';

class DatabaseAdminScreen extends StatefulWidget {
  const DatabaseAdminScreen({super.key});
  @override State<DatabaseAdminScreen> createState() => _DatabaseAdminScreenState();
}

class _DatabaseAdminScreenState extends State<DatabaseAdminScreen> {
  bool get _isAdmin => AuthService.user?.role == 'admin' || AuthService.user?.role == 'superadmin';
  List<DatabaseConfig> _databases = [];
  bool _isLoading = true;

  @override void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isAdmin) return;
    setState(() => _isLoading = true);
    final dbs = await ApiService.getDatabases();
    if (!mounted) return;
    setState(() {
      _databases = dbs.map((e) => DatabaseConfig.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _testConnection(int id) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final result = await ApiService.testDatabaseConnection(id);
    if (mounted) Navigator.pop(context);
    _showResult(result['success'] == true, result['message'] ?? 'Test completed');
  }

  Future<void> _runQuery(int dbId) async {
    final ctrl = TextEditingController(text: 'SELECT * FROM park_in');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Query'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Execute a custom SQL query? This action may modify data.'),
            const SizedBox(height: 12),
            TextField(controller: ctrl, maxLines: 5, decoration: const InputDecoration(hintText: 'Enter SQL query')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('RUN')),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final query = ctrl.text.trim();
    final result = await ApiService.executeQuery(dbId, query);
    if (mounted) Navigator.pop(context);

    if (result['success'] == true) {
      final data = result['data'] ?? result['results'] ?? [];
      _showResultDialog('Query Result', data.toString());
    } else {
      _showResult(false, result['message'] ?? 'Query failed');
    }
  }

  void _showResult(bool success, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(children: [
          Icon(success ? Icons.check_circle : Icons.error, color: success ? AppTheme.success : AppTheme.danger),
          const SizedBox(width: 8),
          Text(success ? 'Success' : 'Error'),
        ]),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE'))],
      ),
    );
  }

  @override Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(title: const Text('Database Admin')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 64, color: AppTheme.danger),
              SizedBox(height: 16),
              Text('Access Denied', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.danger)),
              SizedBox(height: 8),
              Text('Admin privileges required.', style: TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('Database Admin'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _databases.isEmpty
          ? const Center(child: Text('No databases configured', style: TextStyle(color: AppTheme.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _databases.length,
              itemBuilder: (_, i) {
                final db = _databases[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: db.isConnected ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.dns_rounded,
                              color: db.isConnected ? AppTheme.success : AppTheme.danger,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(db.name, style: AppTheme.heading4),
                                Text('${db.type.toUpperCase()} — ${db.host}:${db.port}', style: AppTheme.bodySmall),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: db.isConnected ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              db.isConnected ? 'Connected' : 'Disconnected',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: db.isConnected ? AppTheme.success : AppTheme.danger,
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Text('Database: ${db.databaseName}', style: AppTheme.bodySmall),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _testConnection(db.id),
                              icon: const Icon(Icons.wifi_tethering, size: 16),
                              label: const Text('Test'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _runQuery(db.id),
                              icon: const Icon(Icons.code, size: 16),
                              label: const Text('Query'),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
