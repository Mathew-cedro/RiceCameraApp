
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';
import '../services/supabase_service.dart';
 
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
 
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}
 
class _HistoryScreenState extends State<HistoryScreen> {
  final _service = SupabaseService();
  List<ScanRecord> _records = [];
  bool _loading = true;
  String? _error;
 
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
 
  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await _service.fetchHistory();
      if (mounted) setState(() => _records = records);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load history.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  Future<void> _deleteRecord(ScanRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete scan?'),
        content: const Text('This record will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFF44336)))),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteScan(record.id);
      setState(() => _records.removeWhere((r) => r.id == record.id));
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }
 
  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }
 
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _loadHistory);
    }
 
    if (_records.isEmpty) {
      return _EmptyView(theme: theme);
    }
 
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: theme.colorScheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        itemCount: _records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final record = _records[index];
          return _HistoryCard(
            record: record,
            onDelete: () => _deleteRecord(record),
          );
        },
      ),
    );
  }
}
 
// ─── History card ───────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final ScanRecord record;
  final VoidCallback onDelete;
 
  const _HistoryCard({required this.record, required this.onDelete});
 
  Color _statusColor(String status) {
    return switch (status) {
      'Fully Ripe' => const Color(0xFF4CAF50),
      'Nearly Harvestable' => const Color(0xFF8BC34A),
      'Barely Harvestable' => const Color(0xFFFF9800),
      _ => const Color(0xFFF44336),
    };
  }
 
  IconData _statusIcon(String status) {
    return switch (status) {
      'Fully Ripe' => Icons.check_circle_rounded,
      'Nearly Harvestable' => Icons.timelapse_rounded,
      'Barely Harvestable' => Icons.hourglass_bottom_rounded,
      _ => Icons.cancel_rounded,
    };
  }
 
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(record.resultStatus);
    final dateStr =
        DateFormat('MMM d, yyyy — h:mm a').format(record.createdAt.toLocal());
 
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: status + delete ──
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(record.resultStatus),
                        color: color, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      record.resultStatus,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                    size: 20),
              ),
            ],
          ),
 
          const SizedBox(height: 12),
 
          // ── Ripe percentage bar ──
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (record.ripePercent / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${record.ripePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
 
          const SizedBox(height: 10),
 
          // ── Detail row ──
          Row(
            children: [
              _Chip(
                label: '🟡 ${record.yellowPercent.toStringAsFixed(1)}% yellow',
                theme: theme,
              ),
              const SizedBox(width: 6),
              _Chip(
                label: '🟤 ${record.brownPercent.toStringAsFixed(1)}% brown',
                theme: theme,
              ),
            ],
          ),
 
          if (record.imageName != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.image_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurface.withOpacity(0.35)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    record.imageName!,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
 
          const SizedBox(height: 8),
 
          // ── Date ──
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.35)),
              const SizedBox(width: 4),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
class _Chip extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _Chip({required this.label, required this.theme});
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          )),
    );
  }
}
 
// ─── Empty & error states ────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final ThemeData theme;
  const _EmptyView({required this.theme});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No scans yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your scan history will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
 
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}