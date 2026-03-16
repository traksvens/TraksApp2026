import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';
import 'package:tracks_app/core/services/dojah_kyc_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NationalIdVerificationPage extends StatefulWidget {
  const NationalIdVerificationPage({super.key});

  @override
  State<NationalIdVerificationPage> createState() => _NationalIdVerificationPageState();
}

class _NationalIdVerificationPageState extends State<NationalIdVerificationPage> {
  bool _isLoading = false;

  Future<void> _startVerification() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final user = authState.user;
    final userId = user.uid;
    final email = user.email ?? '';

    setState(() {
      _isLoading = true;
    });

    final result = await DojahKycService.launchNationalIdVerification(
      userId: userId,
      email: email,
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      // The SDK completed. We mark the KYC status as pending review.
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'kycStatus': 'pending',
          'kycProvider': 'dojah',
          'kycDocumentType': 'national_id',
          'kycCountry': 'NG',
          'kycSubmittedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification submitted and is pending review.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving verification state: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification was cancelled or failed to launch. Please check if Dojah Widget ID is configured.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color canopiBg = theme.scaffoldBackgroundColor;
    final Color canopiText = theme.colorScheme.onSurface;
    const Color canopiSubtitle = Color(0xFFA0A0A0);

    return Scaffold(
      backgroundColor: canopiBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: canopiText,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Identity Verification",
          style: TextStyle(
            fontFamily: 'Inter',
            color: canopiText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.badge_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Nigerian National ID",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: canopiText,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "To unlock premium features and ensure community safety, we need to verify your identity using your National ID (NIN).",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: canopiSubtitle,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.scaffoldBackgroundColor,
                          ),
                        )
                      : const Text(
                          "Start Verification",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Secured by Dojah",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: canopiSubtitle.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
