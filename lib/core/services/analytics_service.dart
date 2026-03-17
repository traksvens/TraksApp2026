import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;

  FirebaseAnalytics get analytics {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  Future<void> setUserId(String? userId) async {
    if (userId != null) {
      await analytics.setUserId(id: userId);
    } else {
      await analytics.setUserId(id: null);
    }
  }

  Future<void> setUserProperties({
    String? userType,
    String? subscriptionTier,
  }) async {
    if (userType != null) {
      await analytics.setUserProperty(name: 'user_type', value: userType);
    }
    if (subscriptionTier != null) {
      await analytics.setUserProperty(
        name: 'subscription_tier',
        value: subscriptionTier,
      );
    }
  }

  Future<void> logPageView({
    required String pageName,
    String? screenClass,
  }) async {
    await analytics.logScreenView(
      screenName: pageName,
      screenClass: screenClass,
    );
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> logSosSent({
    required String incidentId,
    required String alertType,
    double? latitude,
    double? longitude,
  }) async {
    await analytics.logEvent(
      name: 'sos_sent',
      parameters: {
        'incident_id': incidentId,
        'alert_type': alertType,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    );
  }

  Future<void> logSosResolved({
    required String incidentId,
    String? resolution,
  }) async {
    await analytics.logEvent(
      name: 'sos_resolved',
      parameters: {
        'incident_id': incidentId,
        if (resolution != null) 'resolution': resolution,
      },
    );
  }

  Future<void> logLocationPermissionGranted() async {
    await analytics.logEvent(
      name: 'location_permission_granted',
      parameters: {},
    );
  }

  Future<void> logLocationPermissionDenied() async {
    await analytics.logEvent(
      name: 'location_permission_denied',
      parameters: {},
    );
  }

  Future<void> logLocationServiceEnabled() async {
    await analytics.logEvent(name: 'location_service_enabled', parameters: {});
  }

  Future<void> logLocationServiceDisabled() async {
    await analytics.logEvent(name: 'location_service_disabled', parameters: {});
  }

  Future<void> logLocationFetched({
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    await analytics.logEvent(
      name: 'location_fetched',
      parameters: {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      },
    );
  }

  Future<void> logAppOpen() async {
    await analytics.logAppOpen();
  }

  Future<void> logLogin({required String method}) async {
    await analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({required String method}) async {
    await analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await analytics.logEvent(name: 'logout', parameters: {});
  }

  Future<void> logPostCreated({
    required String postId,
    String? severity,
    String? category,
  }) async {
    await analytics.logEvent(
      name: 'post_created',
      parameters: {
        'post_id': postId,
        if (severity != null) 'severity': severity,
        if (category != null) 'category': category,
      },
    );
  }

  Future<void> logPostViewed({required String postId, String? authorId}) async {
    await analytics.logEvent(
      name: 'post_viewed',
      parameters: {
        'post_id': postId,
        if (authorId != null) 'author_id': authorId,
      },
    );
  }

  Future<void> logSearchPerformed({
    required String query,
    int? resultCount,
  }) async {
    await analytics.logEvent(
      name: 'search_performed',
      parameters: {
        'query': query,
        if (resultCount != null) 'result_count': resultCount,
      },
    );
  }

  Future<void> logSubscriptionStarted({required String tier}) async {
    await analytics.logEvent(
      name: 'subscription_started',
      parameters: {'tier': tier},
    );
  }

  Future<void> logSubscriptionUpgraded({
    required String fromTier,
    required String toTier,
  }) async {
    await analytics.logEvent(
      name: 'subscription_upgraded',
      parameters: {'from_tier': fromTier, 'to_tier': toTier},
    );
  }

  Future<void> logKycStarted() async {
    await analytics.logEvent(name: 'kyc_started', parameters: {});
  }

  Future<void> logKycCompleted({required String status}) async {
    await analytics.logEvent(
      name: 'kyc_completed',
      parameters: {'status': status},
    );
  }

  Future<void> logEmergencyContactAdded({required int contactCount}) async {
    await analytics.logEvent(
      name: 'emergency_contact_added',
      parameters: {'contact_count': contactCount},
    );
  }

  Future<void> logMapInteraction({
    required String interactionType,
    String? selectedIncidentId,
  }) async {
    await analytics.logEvent(
      name: 'map_interaction',
      parameters: {
        'interaction_type': interactionType,
        if (selectedIncidentId != null) 'incident_id': selectedIncidentId,
      },
    );
  }

  Future<void> logShareContent({
    required String contentType,
    String? contentId,
  }) async {
    await analytics.logEvent(
      name: 'share_content',
      parameters: {
        'content_type': contentType,
        if (contentId != null) 'content_id': contentId,
      },
    );
  }
}

class AnalyticsHelper {
  static final AnalyticsService _analytics = AnalyticsService();

  static AnalyticsService get analytics => _analytics;

  static Future<void> logAppOpen() async {
    if (kDebugMode) {
      debugPrint('[Analytics] App Open');
    }
    await _analytics.logAppOpen();
  }

  static Future<void> trackPageView(
    String pageName, {
    String? screenClass,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Page View: $pageName');
    }
    await _analytics.logPageView(pageName: pageName, screenClass: screenClass);
  }

  static Future<void> trackSosSent({
    required String incidentId,
    required String alertType,
    double? latitude,
    double? longitude,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] SOS Sent: $incidentId, type: $alertType');
    }
    await _analytics.logSosSent(
      incidentId: incidentId,
      alertType: alertType,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static Future<void> trackSosResolved(
    String incidentId, {
    String? resolution,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] SOS Resolved: $incidentId');
    }
    await _analytics.logSosResolved(
      incidentId: incidentId,
      resolution: resolution,
    );
  }

  static Future<void> trackLocationPermissionGranted() async {
    if (kDebugMode) {
      debugPrint('[Analytics] Location Permission Granted');
    }
    await _analytics.logLocationPermissionGranted();
  }

  static Future<void> trackLocationPermissionDenied() async {
    if (kDebugMode) {
      debugPrint('[Analytics] Location Permission Denied');
    }
    await _analytics.logLocationPermissionDenied();
  }

  static Future<void> trackLocationFetched(
    double lat,
    double lng, {
    double? accuracy,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Location Fetched: $lat, $lng');
    }
    await _analytics.logLocationFetched(
      latitude: lat,
      longitude: lng,
      accuracy: accuracy,
    );
  }

  static Future<void> trackLogin(String method) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Login: $method');
    }
    await _analytics.logLogin(method: method);
  }

  static Future<void> trackSignUp(String method) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Sign Up: $method');
    }
    await _analytics.logSignUp(method: method);
  }

  static Future<void> trackLogout() async {
    if (kDebugMode) {
      debugPrint('[Analytics] Logout');
    }
    await _analytics.logLogout();
  }

  static Future<void> trackPostCreated(
    String postId, {
    String? severity,
    String? category,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Post Created: $postId');
    }
    await _analytics.logPostCreated(
      postId: postId,
      severity: severity,
      category: category,
    );
  }

  static Future<void> trackPostViewed(String postId, {String? authorId}) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Post Viewed: $postId');
    }
    await _analytics.logPostViewed(postId: postId, authorId: authorId);
  }

  static Future<void> trackSearch(String query, {int? resultCount}) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Search: $query');
    }
    await _analytics.logSearchPerformed(query: query, resultCount: resultCount);
  }

  static Future<void> trackSubscriptionStarted(String tier) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Subscription Started: $tier');
    }
    await _analytics.logSubscriptionStarted(tier: tier);
  }

  static Future<void> trackKycStarted() async {
    if (kDebugMode) {
      debugPrint('[Analytics] KYC Started');
    }
    await _analytics.logKycStarted();
  }

  static Future<void> trackKycCompleted(String status) async {
    if (kDebugMode) {
      debugPrint('[Analytics] KYC Completed: $status');
    }
    await _analytics.logKycCompleted(status: status);
  }

  static Future<void> trackEmergencyContactAdded(int contactCount) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Emergency Contact Added: count=$contactCount');
    }
    await _analytics.logEmergencyContactAdded(contactCount: contactCount);
  }

  static Future<void> trackMapInteraction(
    String interactionType, {
    String? incidentId,
  }) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Map Interaction: $interactionType');
    }
    await _analytics.logMapInteraction(
      interactionType: interactionType,
      selectedIncidentId: incidentId,
    );
  }

  static Future<void> setUserId(String? userId) async {
    if (kDebugMode) {
      debugPrint('[Analytics] Set User ID: $userId');
    }
    await _analytics.setUserId(userId);
  }

  static Future<void> setUserProperties({
    String? userType,
    String? subscriptionTier,
  }) async {
    if (kDebugMode) {
      debugPrint(
        '[Analytics] Set User Properties: type=$userType, tier=$subscriptionTier',
      );
    }
    await _analytics.setUserProperties(
      userType: userType,
      subscriptionTier: subscriptionTier,
    );
  }
}
