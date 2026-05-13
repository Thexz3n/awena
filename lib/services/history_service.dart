// Translation-history API.
import '../models/history_item.dart';
import 'api_client.dart';

class HistoryListResult {
  final int total;
  final int page;
  final int pageSize;
  final List<HistoryItem> items;

  const HistoryListResult({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.items,
  });

  bool get hasMore => page * pageSize < total;
}

class HistoryService {
  final ApiClient _api = ApiClient.instance;

  // ─── List with optional filters ─────────────────────────────────────────
  Future<HistoryListResult> list({
    int page = 1,
    int pageSize = 20,
    TranslationType? type,
    String? search,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (type != null) query['type'] = type.apiValue;
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final data = await _api.get('/history', query: query) as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => HistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return HistoryListResult(
      total: data['total'] as int,
      page: data['page'] as int,
      pageSize: data['page_size'] as int,
      items: items,
    );
  }

  // ─── Stats (for the history-screen mini cards) ──────────────────────────
  Future<HistoryStats> stats() async {
    final data = await _api.get('/history/stats') as Map<String, dynamic>;
    return HistoryStats.fromJson(data);
  }

  // ─── Save a new entry ──────────────────────────────────────────────────
  Future<HistoryItem> save({
    required TranslationType type,
    required String translatedText,
    String? sourceText,
    String? sourceLanguage,
    String? targetLanguage,
    double? confidence,
  }) async {
    final body = <String, dynamic>{
      'type': type.apiValue,
      'translated_text': translatedText,
      if (sourceText != null) 'source_text': sourceText,
      if (sourceLanguage != null) 'source_language': sourceLanguage,
      if (targetLanguage != null) 'target_language': targetLanguage,
      if (confidence != null) 'confidence': confidence,
    };
    final data = await _api.post('/history', body: body) as Map<String, dynamic>;
    return HistoryItem.fromJson(data);
  }

  Future<void> deleteOne(int id) async {
    await _api.delete('/history/$id');
  }

  Future<void> clearAll() async {
    await _api.delete('/history');
  }
}
