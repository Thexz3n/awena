// Translation history model — mirrors the FastAPI HistoryRead schema.

enum TranslationType {
  signToText('sign_to_text'),
  textToSign('text_to_sign'),
  voiceToSign('voice_to_sign');

  final String apiValue;
  const TranslationType(this.apiValue);

  static TranslationType fromApi(String value) {
    return TranslationType.values.firstWhere(
      (t) => t.apiValue == value,
      orElse: () => TranslationType.signToText,
    );
  }
}

class HistoryItem {
  final int id;
  final TranslationType type;
  final String translatedText;
  final String? sourceText;
  final String? sourceLanguage;
  final String? targetLanguage;
  final double? confidence;
  final DateTime createdAt;

  const HistoryItem({
    required this.id,
    required this.type,
    required this.translatedText,
    this.sourceText,
    this.sourceLanguage,
    this.targetLanguage,
    this.confidence,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as int,
      type: TranslationType.fromApi(json['type'] as String),
      translatedText: json['translated_text'] as String,
      sourceText: json['source_text'] as String?,
      sourceLanguage: json['source_language'] as String?,
      targetLanguage: json['target_language'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] as String)
              ?.toLocal() ??
          DateTime.now(),
    );
  }
}

class HistoryStats {
  final int total;
  final int signToText;
  final int textToSign;
  final int voiceToSign;
  final int last7Days;
  final int sessionsThisMonth;

  const HistoryStats({
    required this.total,
    required this.signToText,
    required this.textToSign,
    required this.voiceToSign,
    required this.last7Days,
    required this.sessionsThisMonth,
  });

  factory HistoryStats.fromJson(Map<String, dynamic> json) {
    return HistoryStats(
      total: json['total'] as int? ?? 0,
      signToText: json['sign_to_text'] as int? ?? 0,
      textToSign: json['text_to_sign'] as int? ?? 0,
      voiceToSign: json['voice_to_sign'] as int? ?? 0,
      last7Days: json['last_7_days'] as int? ?? 0,
      sessionsThisMonth: json['sessions_this_month'] as int? ?? 0,
    );
  }

  static const empty = HistoryStats(
    total: 0,
    signToText: 0,
    textToSign: 0,
    voiceToSign: 0,
    last7Days: 0,
    sessionsThisMonth: 0,
  );
}
