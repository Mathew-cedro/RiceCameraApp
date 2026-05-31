import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scan_record.dart';
 
class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();
 
  final _client = Supabase.instance.client;
  static const _table = 'scan_history';
 
  /// Insert a new scan record and return the saved record.
  Future<ScanRecord?> saveScan(ScanRecord record) async {
    try {
      final response = await _client
          .from(_table)
          .insert(record.toMap())
          .select()
          .single();
      return ScanRecord.fromMap(response);
    } catch (e) {
      // Log but don't crash — history saving is non-critical
      print('SupabaseService.saveScan error: $e');
      return null;
    }
  }
 
  /// Fetch all scan records, newest first.
  Future<List<ScanRecord>> fetchHistory() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => ScanRecord.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('SupabaseService.fetchHistory error: $e');
      return [];
    }
  }
 
  /// Delete a scan record by id.
  Future<void> deleteScan(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      print('SupabaseService.deleteScan error: $e');
    }
  }
}