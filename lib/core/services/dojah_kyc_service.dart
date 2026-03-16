import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dojah_kyc_sdk_flutter/dojah_kyc_sdk_flutter.dart';
import 'package:flutter/foundation.dart';

class DojahKycService {
  static Future<String?> launchNationalIdVerification({
    required String userId,
    required String email,
  }) async {
    final widgetId = dotenv.get('DOJAH_WIDGET_ID', fallback: '');
    
    if (widgetId.isEmpty) {
      debugPrint('Dojah Widget ID is not configured.');
      return null; // Graceful fallback if not configured
    }

    // Generate a reference ID for the backend to track this verification attempt
    final referenceId = 'NIN-$userId-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final result = await DojahKyc.launch(
        widgetId,
        referenceId: referenceId,
        email: email,
      );
      
      return result;
    } catch (e) {
      debugPrint('Error launching Dojah KYC: $e');
      return null;
    }
  }
}
