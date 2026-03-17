# Firebase Analytics Implementation

This document describes the analytics tracking implemented in the TRAKS app.

## Overview

The app uses Firebase Analytics to track user interactions, screen views, and custom events. Analytics are logged via the centralized `AnalyticsHelper` class in `lib/core/services/analytics_service.dart`.

## Files

- `lib/core/services/analytics_service.dart` - Main analytics service and helper class
- `lib/core/services/analytics_navigation_observer.dart` - Automatic page view tracking

## Events Tracked

### Page Views

| Screen | Event Name | Trigger |
|--------|-----------|---------|
| Splash | `/splash` | App launch |
| Login | `/login` | LoginPage initState |
| Signup | `/signup` | LoginPage initState (isSignUp mode) |
| Home | `/home` | Tab change to Home tab |
| Map | `/map` | Tab change to Map tab |
| Profile | `/profile` | Tab change to Profile tab |
| Subscription | `/subscription` | SubscriptionPage initState |
| KYC Verification | `/kyc_verification` | NationalIdVerificationPage initState |
| SOS Customization | `/sos_customization` | SosCustomizationPage initState |
| Post Detail | `/post_detail` | PostDetailPage initState |

### Authentication Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `login` | `method` (email/google) | Successful login |
| `sign_up` | `method` (email) | Successful signup |
| `logout` | - | User logs out |

### SOS Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `sos_sent` | `incident_id`, `alert_type`, `latitude`, `longitude` | SOS broadcast triggered |
| `sos_resolved` | `incident_id`, `resolution` | SOS resolved by user |

### Location Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `location_fetched` | `latitude`, `longitude`, `accuracy` | Location updated |
| `location_permission_granted` | - | Location permission granted |
| `location_permission_denied` | - | Location permission denied |
| `location_service_enabled` | - | Location services enabled |
| `location_service_disabled` | - | Location services disabled |

### Post Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `post_created` | `post_id`, `severity`, `category` | New post created |
| `post_viewed` | `post_id`, `author_id` | Post detail viewed |

### Subscription Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `subscription_started` | `tier` | Subscription initiated |
| `subscription_upgraded` | `from_tier`, `to_tier` | Subscription upgraded |

### KYC Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `kyc_started` | - | KYC verification started |
| `kyc_completed` | `status` | KYC verification completed |

### Emergency Contact Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `emergency_contact_added` | `contact_count` | New emergency contact added |

### Map Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `map_interaction` | `interaction_type`, `incident_id` | User interacts with map (navigation started) |

### App Events

| Event | Parameters | Trigger |
|-------|------------|---------|
| `app_open` | - | App opened/initialized |
| `screen_view` | `screen_name`, `screen_class` | Page viewed (via navigation observer) |

## User Properties

User properties are set when a user authenticates:

| Property | Value | Set When |
|----------|-------|----------|
| `user_type` | free/premium | User subscribes |
| `subscription_tier` | tier name | User subscribes |
| `user_id` | Firebase UID | User logs in |

## Usage

### Tracking a Page View

```dart
import 'package:tracks_app/core/services/analytics_service.dart';

AnalyticsHelper.trackPageView('/my_page');
```

### Tracking Custom Events

```dart
AnalyticsHelper.trackSosSent(
  incidentId: '123',
  alertType: 'MANUAL_TRIGGER',
  latitude: 40.7128,
  longitude: -74.0060,
);

AnalyticsHelper.trackPostCreated(
  postId: 'abc123',
  severity: 'high',
  category: 'traffic',
);
```

### Setting User Properties

```dart
AnalyticsHelper.setUserId(user.uid);
AnalyticsHelper.setUserProperties(
  userType: 'premium',
  subscriptionTier: 'reporter',
);
```

## Debug Mode

In debug mode (kDebugMode), all analytics events are also printed to console with `[Analytics]` prefix. This helps with testing and debugging.

## Navigation Observer

The `AnalyticsNavigationObserver` class automatically tracks page views when using Navigator.push/pop. It's registered in main.dart:

```dart
navigatorObservers: [navigationObserver],
```

Note: The app uses IndexedStack for bottom navigation, so manual page view tracking is added for tab changes in `HomePage._trackPageView()`.