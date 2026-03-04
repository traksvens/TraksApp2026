import 'package:flutter/foundation.dart';

@immutable
class QueryRequest {
  final String text;
  final int topK;
  final bool returnMetadata;
  final Map<String, dynamic>? filters;
  final String? timestampStart;
  final String? timestampEnd;

  const QueryRequest({
    required this.text,
    this.topK = 5,
    this.returnMetadata = true,
    this.filters,
    this.timestampStart,
    this.timestampEnd,
  });

  factory QueryRequest.fromJson(Map<String, dynamic> json) {
    return QueryRequest(
      text: json['text'] as String,
      topK: json['top_k'] as int? ?? 5,
      returnMetadata: json['return_metadata'] as bool? ?? true,
      filters: json['filters'] as Map<String, dynamic>?,
      timestampStart: json['timestamp_start'] as String?,
      timestampEnd: json['timestamp_end'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'top_k': topK,
      'return_metadata': returnMetadata,
      if (filters != null) 'filter': filters, // API uses 'filter' not 'filters'
      if (timestampStart != null) 'timestamp_start': timestampStart,
      if (timestampEnd != null) 'timestamp_end': timestampEnd,
    };
  }
}
