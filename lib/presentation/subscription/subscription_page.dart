import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracks_app/core/services/analytics_service.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';
import 'package:tracks_app/core/theme/app_colors.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late PageController _pageController;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82, initialPage: 1);
    AnalyticsHelper.trackPageView('/subscription');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchPaymentUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch $url");
    }
  }

  void _onTierSelected(String tierName, BuildContext context) {
    if (tierName == 'freemium') {
      Navigator.of(context).pop();
      return;
    }

    final authState = context.read<AuthBloc>().state;
    String uid = 'unknown';
    if (authState is Authenticated) {
      uid = authState.user.uid;
    }

    final returnUri = kIsWeb ? Uri.base.origin : 'traksapp://payment';
    final tierParam = tierName == 'premium' ? 'premium' : 'reporter';
    final baseUrl = dotenv.get(
      'PAYMENT_UI_BASE_URL',
      fallback: 'https://billing.traksvens.name.ng/',
    );

    final paymentUrl =
        '$baseUrl?userId=$uid&return_url=$returnUri&tier=$tierParam';

    _launchPaymentUrl(paymentUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "Membership",
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            left: -100,
            child: _GlowCircle(color: colorScheme.primary.withValues(alpha: 0.08), size: 400),
          ),
          Positioned(
            bottom: -100,
            right: -50,
            child: _GlowCircle(color: colorScheme.secondary.withValues(alpha: 0.05), size: 350),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Hero Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      Text(
                        "Elevate Your Impact",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Choose the level of influence you want within the Tracks community.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Subscription Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _getTiers(theme).length,
                    itemBuilder: (context, index) {
                      final tier = _getTiers(theme)[index];
                      final isCurrent = _currentPage == index;
                      return _SubscriptionCard(
                        tier: tier,
                        isCurrent: isCurrent,
                        onTap: () => _onTierSelected(tier.id, context),
                      );
                    },
                  ),
                ),

                // Indicators
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_getTiers(theme).length, (index) {
                      final active = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 4,
                        width: active ? 20 : 4,
                        decoration: BoxDecoration(
                          color: active ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final _TierModel tier;
  final bool isCurrent;
  final VoidCallback onTap;

  const _SubscriptionCard({
    required this.tier,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scale = isCurrent ? 1.0 : 0.9;
    final opacity = isCurrent ? 1.0 : 0.4;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutExpo,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 500),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isCurrent ? colorScheme.onSurface.withValues(alpha: 0.1) : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              if (isCurrent)
                BoxShadow(
                  color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.5 : 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                if (isCurrent)
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tier.accentColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(tier.icon, color: tier.accentColor, size: 32),
                          if (tier.id == 'premium')
                            _Badge(text: "Popular", color: tier.accentColor),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        tier.name,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            tier.price == 0 ? "Free" : "₦${tier.price}",
                            style: GoogleFonts.inter(
                              color: colorScheme.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          if (tier.price > 0)
                            Text(
                              " / life",
                              style: GoogleFonts.inter(
                                color: colorScheme.onSurface.withValues(alpha: 0.4),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Features
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tier.features.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, i) {
                            return Row(
                              children: [
                                Icon(Icons.done_rounded, color: tier.accentColor, size: 18),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tier.features[i],
                                    style: GoogleFonts.inter(
                                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      
                      // CTA
                      const SizedBox(height: 24),
                      if (tier.id != 'freemium')
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCurrent ? tier.accentColor : colorScheme.onSurface.withValues(alpha: 0.1),
                              foregroundColor: isCurrent ? (tier.accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white) : colorScheme.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              tier.buttonText,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TierModel {
  final String id;
  final String name;
  final int price;
  final String buttonText;
  final List<String> features;
  final Color accentColor;
  final IconData icon;

  _TierModel({
    required this.id,
    required this.name,
    required this.price,
    required this.buttonText,
    required this.features,
    required this.accentColor,
    required this.icon,
  });
}

List<_TierModel> _getTiers(ThemeData theme) {
  final colorScheme = theme.colorScheme;
  return [
    _TierModel(
      id: 'freemium',
      name: 'Freemium',
      price: 0,
      buttonText: 'Current Plan',
      accentColor: colorScheme.onSurface.withValues(alpha: 0.3),
      icon: Icons.person_outline_rounded,
      features: [
        'Standard incident access',
        'Basic reporting tools',
        'Community participation',
      ],
    ),
    _TierModel(
      id: 'premium',
      name: 'Premium',
      price: 3000,
      buttonText: 'Upgrade Now',
      accentColor: AppColors.success,
      icon: Icons.workspace_premium_rounded,
      features: [
        'Verified checkmark',
        'Ad-free experience',
        'Priority support',
        'Enhanced visibility',
      ],
    ),
    _TierModel(
      id: 'reporter',
      name: 'Reporter',
      price: 7000,
      buttonText: 'Go Pro',
      accentColor: const Color(0xFFEAB308), // Gold
      icon: Icons.campaign_rounded,
      features: [
        'Official Reporter status',
        'Verified News alerts',
        'Advanced analytics',
        'Everything in Premium',
      ],
    ),
  ];
}
