# Dojah National ID Setup Guide

This guide explains how to complete the Dojah KYC integration once you have access to the Dojah dashboard and your Widget ID.

Currently, the app has a scaffolded flow:
1. User pays for a premium/reporter tier.
2. The backend records their new `tier` but does not automatically mark them as `isVerified`.
3. The app prompts the paid user to verify their identity via the `NationalIdVerificationPage`.
4. If `DOJAH_WIDGET_ID` is missing, the app shows a graceful fallback message.
5. If the SDK completes, the user is marked as `kycStatus: 'pending'` in Firestore.

## 1. Get Your Widget ID

1. Log in to your [Dojah Dashboard](https://dojah.io/).
2. Navigate to **EasyOnboard**.
3. Click **Create a Flow**.
4. Name your flow (e.g., "Traks National ID Verification").
5. Customize your widget with your brand logo and colors.
6. Configure the flow:
   - **Country:** Nigeria
   - **Verification Pages:** Add the **National ID (NIN)** verification step.
   - **Preview Process:** Choose automatic or manual verification based on your preference.
7. Publish the widget and copy the generated **Widget ID**.

## 2. Update Environment Variables

Add the Widget ID to your local `.env` file in the `TraksApp2026` directory:

```env
DOJAH_WIDGET_ID=your_actual_widget_id_here
```

Also, remember to add this environment variable to your production deployment/CI pipeline.

## 3. Test on Android

1. Run the app on an Android emulator or physical device.
2. Complete the payment flow to become a paid user.
3. Tap **Verify Identity** on the Profile page or navigate to the Premium tab.
4. The Dojah SDK should launch and guide you through the National ID verification process.
5. Verify that completing the flow updates your Firestore document with `kycStatus: 'pending'`.

## 4. Backend Webhook (Next Steps)

Currently, the app marks the user as `pending` when the SDK closes. To fully verify the user, you must implement a Dojah Webhook on your FastAPI backend:

1. In the Dojah Dashboard, configure a webhook URL pointing to your backend (e.g., `https://api.traks.com/webhooks/dojah`).
2. Create a new route in `TraksApi` to receive the webhook payload.
3. When the webhook confirms a successful verification, find the user by the `referenceId` (which the app passes as `NIN-{userId}-{timestamp}`) and update their Firestore document:
   - `isVerified: true`
   - `kycStatus: 'completed'`

## 5. iOS Setup (If Supporting iOS Later)

The current implementation is Android-first. If you decide to build for iOS, you will need to:

1. Update `ios/Podfile`:
   ```ruby
   pod 'Realm', '~> 10.52.2', :modular_headers => true
   pod 'DojahWidget', :git => 'https://github.com/dojah-inc/sdk-swift.git', :branch => 'pod-package'
   ```
2. Run `pod install` in the `ios/` directory.
3. Add camera, microphone, and location permissions to `ios/Runner/Info.plist`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need access to your camera for identity verification.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>We need access to your microphone for video verification.</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location for address verification.</string>
   ```
