import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;

import '../../../core/services/places_service.dart';
import '../../../data/models/post_model.dart';
import '../../../repository/post_repository.dart';

class MapAiResponse {
  const MapAiResponse({
    required this.assistantText,
    this.posts = const [],
    this.resolvedLabel,
    this.lat,
    this.lng,
    this.radiusMeters,
    this.usedTool = false,
  });

  final String assistantText;
  final List<PostModel> posts;
  final String? resolvedLabel;
  final double? lat;
  final double? lng;
  final int? radiusMeters;
  final bool usedTool;
}

class CurrentLocationContext {
  const CurrentLocationContext({
    required this.lat,
    required this.lng,
    this.label,
  });

  final double lat;
  final double lng;
  final String? label;
}

class MapAiService {
  MapAiService({
    required PlacesService placesService,
    required PostRepository postRepository,
  }) : _placesService = placesService,
       _postRepository = postRepository {
    _apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    _modelName = dotenv.env['GEMINI_MODEL']?.trim().isNotEmpty == true
        ? dotenv.env['GEMINI_MODEL']!.trim()
        : 'gemini-3.1-flash-lite-preview';

    if (_apiKey.isNotEmpty) {
      _model = _createModel();
    }
  }

  final PlacesService _placesService;
  final PostRepository _postRepository;

  late final String _apiKey;
  late final String _modelName;
  genai.GenerativeModel? _model;
  final List<genai.Content> _history = [];

  bool get isConfigured => _model != null;

  void resetConversation() {
    if (!isConfigured) return;
    _history.clear();
  }

  Future<MapAiResponse> sendPrompt(
    String prompt, {
    required Future<LatLng?> Function() resolveCurrentLocation,
    CurrentLocationContext? currentLocationContext,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'GEMINI_API_KEY is not configured. Add it to .env to enable AI mode.',
      );
    }

    final userMessage = genai.Content.text(
      _buildPromptWithLocationContext(prompt, currentLocationContext),
    );
    final shouldForceTool = _shouldUseNearbyTool(prompt);
    final initialResponse = await _model!.generateContent([
      ..._history,
      userMessage,
    ], toolConfig: shouldForceTool ? _forcedToolConfig : null);
    final initialCall =
        _firstFunctionCall(initialResponse) ??
        (shouldForceTool ? _buildFallbackFunctionCall(prompt) : null);

    if (initialCall == null) {
      _appendHistory(userMessage, _firstCandidateContent(initialResponse));
      return MapAiResponse(
        assistantText:
            _extractText(initialResponse) ??
            'I could not find anything useful for that request.',
      );
    }

    final toolResult = await _executeToolCall(
      initialCall,
      resolveCurrentLocation: resolveCurrentLocation,
    );

    String assistantText;
    genai.Content? assistantContent;

    if (_firstFunctionCall(initialResponse) != null) {
      final followUp = await _model!.generateContent([
        ..._history,
        genai.Content.text(_buildToolSummaryPrompt(prompt, toolResult)),
      ], toolConfig: _disabledToolConfig);
      assistantText =
          _extractText(followUp) ??
          _fallbackSummary(toolResult.posts, toolResult.resolvedLabel);
      assistantContent = _firstCandidateContent(followUp);
    } else {
      assistantText = _fallbackSummary(
        toolResult.posts,
        toolResult.resolvedLabel,
      );
    }

    _appendHistory(
      userMessage,
      assistantContent ?? genai.Content.model([genai.TextPart(assistantText)]),
    );

    return MapAiResponse(
      assistantText: assistantText,
      posts: toolResult.posts,
      resolvedLabel: toolResult.resolvedLabel,
      lat: toolResult.lat,
      lng: toolResult.lng,
      radiusMeters: toolResult.radiusMeters,
      usedTool: true,
    );
  }

  genai.GenerativeModel _createModel() {
    return genai.GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      tools: [
        genai.Tool(
          functionDeclarations: [
            genai.FunctionDeclaration(
              'findPostsNearLocation',
              'Resolve a location and find nearby incident posts for that area.',
              genai.Schema.object(
                properties: {
                  'locationQuery': genai.Schema.string(
                    description:
                        'A user-supplied place name, address, city, or area if the user explicitly specifies a remote location. Leave empty only when the user explicitly asks for nearby results relative to their current location (e.g., "near me", "here"). Do NOT use "your current location" as a string here.',
                    nullable: true,
                  ),
                  'useCurrentLocation': genai.Schema.boolean(
                    description:
                        'Set to true ONLY when the user asks for incidents "near me", "around me", "my location", "here", or asks something without specifying a distinct city/place. Default to false if a specific place is mentioned.',
                    nullable: true,
                  ),
                  'radiusMeters': genai.Schema.integer(
                    description:
                        'Search radius in meters. Use a number between 300 and 20000. Default 10000. If the user asks for a large city, use a larger radius (like 15000 or 20000).',
                    nullable: true,
                  ),
                  'incidentType': genai.Schema.string(
                    description: 'Optional. Filter by type (e.g., "Fire", "Flood", "Accident").',
                    nullable: true,
                  ),
                  'severity': genai.Schema.string(
                    description: 'Optional. Filter by severity level (e.g., "low", "medium", "high", "critical").',
                    nullable: true,
                  ),
                },
              ),
            ),
          ],
        ),
      ],
      systemInstruction: genai.Content.system(_systemInstruction),
      toolConfig: _defaultToolConfig,
    );
  }

  genai.FunctionCall? _firstFunctionCall(
    genai.GenerateContentResponse response,
  ) {
    if (response.candidates.isEmpty) return null;

    for (final part in response.candidates.first.content.parts) {
      if (part is genai.FunctionCall) {
        return part;
      }
    }

    return null;
  }

  genai.Content? _firstCandidateContent(
    genai.GenerateContentResponse response,
  ) {
    if (response.candidates.isEmpty) return null;

    final content = response.candidates.first.content;
    return content.role == null ? genai.Content.model(content.parts) : content;
  }

  void _appendHistory(
    genai.Content userMessage,
    genai.Content? assistantMessage,
  ) {
    _history.add(userMessage);
    if (assistantMessage != null) {
      _history.add(assistantMessage);
    }
  }

  String? _extractText(genai.GenerateContentResponse response) {
    if (response.candidates.isEmpty) return null;

    final buffer = StringBuffer();
    for (final part in response.candidates.first.content.parts) {
      if (part is genai.TextPart && part.text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(part.text.trim());
      }
    }

    final text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _buildPromptWithLocationContext(
    String prompt,
    CurrentLocationContext? currentLocationContext,
  ) {
    if (currentLocationContext == null) {
      return prompt;
    }

    final label = currentLocationContext.label?.trim();
    return '''
User request: $prompt

Current user location context:
- label: ${label?.isNotEmpty == true ? label : 'Unavailable'}
- latitude: ${currentLocationContext.lat}
- longitude: ${currentLocationContext.lng}

Use this location context ONLY when it is relevant to the request.
If the user refers to "my location", "near me", "here", or does not specify a location, use `useCurrentLocation`: true.
If the user specifies a distinct city, neighborhood, or landmark (e.g., "in New York", "around Central Park"), extract THAT location into `locationQuery` and set `useCurrentLocation`: false.
Do not map distinct locations to the current location coordinates.
''';
  }

  String _buildToolSummaryPrompt(
    String userPrompt,
    _ToolExecutionResult toolResult,
  ) {
    final posts = toolResult.posts.take(5).map((post) {
      return {
        'incidentType': post.incidentType,
        'severity': post.severity,
        'content': post.content,
        'address': post.address.formattedAddress ?? '',
        'timestamp': post.timestamp,
        'confirmCount': post.confirmCount,
        'replyCount': post.replyCount,
      };
    }).toList();

    return '''
User request: $userPrompt

Tool result:
- resolved location: ${toolResult.resolvedLabel}
- latitude: ${toolResult.lat}
- longitude: ${toolResult.lng}
- radius meters: ${toolResult.radiusMeters}
- post count: ${toolResult.posts.length}
- top posts: $posts

Respond in 2 short sentences max.
Mention the resolved location and the number of posts found.
If posts exist, briefly mention the most notable patterns from the returned posts.
Do not invent details that are not present in the tool result.
''';
  }

  bool _shouldUseNearbyTool(String prompt) {
    final normalized = prompt.toLowerCase();
    
    // Looser matching strategy - if they ask for something in a specific area, or locally, we use the tool.
    final hasSearchIntent =
        normalized.contains('incident') ||
        normalized.contains('post') ||
        normalized.contains('report') ||
        normalized.contains('crime') ||
        normalized.contains('accident') ||
        normalized.contains('safety') ||
        normalized.contains('happening') ||
        normalized.startsWith('show me') ||
        normalized.startsWith('find') ||
        normalized.startsWith('search') ||
        normalized.startsWith('look up') ||
        normalized.startsWith('what happened') ||
        normalized.startsWith('are there');

    // To prevent the tool from being completely ignored on short queries like "crimes in New York"
    final hasLocationPreposition = RegExp(r'\b(?:in|at|near|around|for)\s+[a-z]+').hasMatch(normalized);
    final hasCurrentLocationIntent = normalized.contains('near me') || 
                                     normalized.contains('around me') || 
                                     normalized.contains('here') ||
                                     normalized.contains('current location');

    return hasSearchIntent && (hasLocationPreposition || hasCurrentLocationIntent);
  }

  genai.FunctionCall? _buildFallbackFunctionCall(String prompt) {
    final radius = _extractRadius(prompt);
    final useCurrentLocation = _usesCurrentLocation(prompt);
    final locationQuery = useCurrentLocation
        ? ''
        : _extractLocationQuery(prompt);

    if (!useCurrentLocation && locationQuery.isEmpty) {
      return null;
    }

    return genai.FunctionCall('findPostsNearLocation', {
      if (locationQuery.isNotEmpty) 'locationQuery': locationQuery,
      'useCurrentLocation': useCurrentLocation,
      if (radius != null) 'radiusMeters': radius,
    });
  }

  bool _usesCurrentLocation(String prompt) {
    final normalized = prompt.toLowerCase();
    return normalized.contains('near me') ||
        normalized.contains('around me') ||
        normalized.contains('by me') ||
        normalized.contains('my location') ||
        normalized.contains('current location');
  }

  String _extractLocationQuery(String prompt) {
    final cleanedPrompt = prompt
        .replaceAll(RegExp(r'[?.!,]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Look for prepositional phrases targeting a place
    final anchoredMatch = RegExp(
      r'\b(?:near|around|in|at|for)\b\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(cleanedPrompt);
    
    if (anchoredMatch != null) {
      final candidate = anchoredMatch.group(1)?.trim() ?? '';
      if (candidate.isNotEmpty) {
        // Strip out trailing stuff we don't need
        return candidate
            .replaceAll(
              RegExp(
                r'\b(?:within|radius|incidents|incident|posts|post|reports|report|please)\b.*$',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
      }
    }

    // Ultimate fallback: strip common intent verbs
    return cleanedPrompt
        .replaceAll(
          RegExp(
            r'\b(?:show me|find|search|look up|lookup|get|are there|what happened|whats happening|incidents|incident|posts|post|reports|report|around|near|in|at|for|please)\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int? _extractRadius(String prompt) {
    final kmMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*km\b',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (kmMatch != null) {
      final km = double.tryParse(kmMatch.group(1)!);
      if (km != null) {
        return (km * 1000).round();
      }
    }

    final meterMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*m(?:eters?)?\b',
      caseSensitive: false,
    ).firstMatch(prompt);
    if (meterMatch != null) {
      final meters = double.tryParse(meterMatch.group(1)!);
      if (meters != null) {
        return meters.round();
      }
    }

    return null;
  }

  Future<_ToolExecutionResult> _executeToolCall(
    genai.FunctionCall call, {
    required Future<LatLng?> Function() resolveCurrentLocation,
  }) async {
    final args = Map<String, Object?>.from(call.args);
    final query = (args['locationQuery'] as String? ?? '').trim();
    final useCurrentLocation = args['useCurrentLocation'] == true;
    final radiusMeters = _sanitizeRadius(args['radiusMeters']);
    final incidentType = args['incidentType'] as String?;
    final severity = args['severity'] as String?;

    double? lat;
    double? lng;
    String resolvedLabel;

    if (useCurrentLocation || query.isEmpty) {
      final current = await resolveCurrentLocation();
      if (current == null) {
        throw StateError('Current location is unavailable.');
      }

      lat = current.latitude;
      lng = current.longitude;
      resolvedLabel = 'your current location';
    } else {
      final resolved = await _placesService.resolveTextLocation(query);
      if (resolved == null) {
        throw StateError('I could not resolve "$query" to a location.');
      }

      lat = resolved['lat'] as double?;
      lng = resolved['lng'] as double?;
      resolvedLabel = resolved['label'] as String? ?? query;
    }

    if (lat == null || lng == null) {
      throw StateError('Location resolution returned invalid coordinates.');
    }

    final posts = await _postRepository.getPostsByProximity(
      lat: lat,
      lng: lng,
      radius: radiusMeters,
      incidentType: incidentType,
      severity: severity,
    );

    return _ToolExecutionResult(
      posts: posts,
      resolvedLabel: resolvedLabel,
      lat: lat,
      lng: lng,
      radiusMeters: radiusMeters,
    );
  }

  int _sanitizeRadius(Object? rawRadius) {
    final parsed = switch (rawRadius) {
      int value => value,
      double value => value.round(),
      String value => int.tryParse(value),
      _ => null,
    };

    return (parsed ?? 10000).clamp(300, 20000);
  }

  String _fallbackSummary(List<PostModel> posts, String label) {
    if (posts.isEmpty) {
      return 'I did not find any nearby posts around $label.';
    }

    if (posts.length == 1) {
      return 'I found 1 nearby post around $label.';
    }

    return 'I found ${posts.length} nearby posts around $label.';
  }

static const String _systemInstruction = '''
You are the map assistant for a safety incident app.

Your job:
- Help the user find safety posts for a place, a city, or nearby area.
- CRITICAL: When the user asks about incidents in a SPECIFIC CITY or PLACE (e.g. "crimes in New York", "posts in Chicago"), ALWAYS call the tool `findPostsNearLocation` and place that city/place name in the `locationQuery` argument. Do NOT use their current location if they ask for somewhere else.
- When the user asks about incidents near their current location (e.g. "near me", "here"), call the tool with `useCurrentLocation`: true.
- After receiving tool results, answer briefly and clearly.
- Keep answers mobile-friendly, engaging, and concise (under 3 sentences).
- Do not invent incidents, counts, or places. Only use tool output.
- If the user asks a general conversational question not related to searching posts, answer briefly without the tool.
''';

  static final genai.ToolConfig _defaultToolConfig = genai.ToolConfig(
    functionCallingConfig: genai.FunctionCallingConfig(
      mode: genai.FunctionCallingMode.auto,
    ),
  );

  static final genai.ToolConfig _forcedToolConfig = genai.ToolConfig(
    functionCallingConfig: genai.FunctionCallingConfig(
      mode: genai.FunctionCallingMode.any,
      allowedFunctionNames: {'findPostsNearLocation'},
    ),
  );

  static final genai.ToolConfig _disabledToolConfig = genai.ToolConfig(
    functionCallingConfig: genai.FunctionCallingConfig(
      mode: genai.FunctionCallingMode.none,
    ),
  );
}

class _ToolExecutionResult {
  const _ToolExecutionResult({
    required this.posts,
    required this.resolvedLabel,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  final List<PostModel> posts;
  final String resolvedLabel;
  final double lat;
  final double lng;
  final int radiusMeters;

  Map<String, Object?> get modelPayload => {
    'resolvedLocation': resolvedLabel,
    'lat': lat,
    'lng': lng,
    'radiusMeters': radiusMeters,
    'count': posts.length,
    'posts': posts.map(_serializePost).toList(),
  };

  static Map<String, Object?> _serializePost(PostModel post) {
    // Robust lat/lng extraction
    double? lat;
    double? lng;

    if (post.location != null) {
      lat = (post.location!['lat'] as num?)?.toDouble() ??
          (post.location!['latitude'] as num?)?.toDouble();
      lng = (post.location!['lng'] as num?)?.toDouble() ??
          (post.location!['long'] as num?)?.toDouble() ??
          (post.location!['longitude'] as num?)?.toDouble();
    }

    return {
      'id': post.id,
      'incidentType': post.incidentType,
      'content': post.content,
      'severity': post.severity,
      'timestamp': post.timestamp,
      'address': post.address.formattedAddress ?? '',
      'imageUrl': post.absoluteImageUrl,
      'confirmCount': post.confirmCount,
      'refuteCount': post.refuteCount,
      'replyCount': post.replyCount,
      'userName': post.isAnonymous ? 'Anonymous' : (post.userName ?? 'User'),
      'userAvatarUrl': post.isAnonymous ? null : post.userAvatarUrl,
      'isAnonymous': post.isAnonymous,
      if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
    };
  }
}
