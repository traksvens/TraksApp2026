import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';

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
    _pageController = PageController(viewportFraction: 0.85, initialPage: 1);
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
      fallback: 'https://traks-payment-ui.vercel.app/',
    );

    final paymentUrl =
        '$baseUrl?userId=$uid&return_url=$returnUri&tier=$tierParam';

    _launchPaymentUrl(paymentUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Premium Navy & White Theme Colors replaced with Canopi Dark Theme
    const Color canopiBg = theme.scaffoldBackgroundColor;
    const Color canopiText = theme.colorScheme.onSurface;
    const Color canopiSubtitle = Color(0xFFA0A0A0);
    const Color canopiGreen = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: canopiBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: canopiText,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Plans & Upgrades",
          style: TextStyle(
            fontFamily: 'Inter',
            color: canopiText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Radial Glow Backdrop Settings
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    canopiGreen.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        "Choose Your Experience",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: canopiText,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Unlock premium features and professional reporting tools built for clarity and impact.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: canopiSubtitle,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Carousel
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _getSubscriptionTiers(theme).length,
                    itemBuilder: (context, index) {
                      final tier = _getSubscriptionTiers(theme)[index];
                      final isActive = _currentPage == index;

                      return _buildTierCard(
                        context: context,
                        tier: tier,
                        isActive: isActive,
                      );
                    },
                  ),
                ),

                // Indicators
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_getSubscriptionTiers(theme).length, (index) {
                    final isActive = _currentPage == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isActive ? 24 : 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? canopiGreen
                            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required BuildContext context,
    required _TierModel tier,
    required bool isActive,
  }) {
    const Color canopiText = theme.colorScheme.onSurface;
    const Color canopiSubtitle = Color(0xFFA0A0A0);

    final scale = isActive ? 1.0 : 0.92;
    final opacity = isActive ? 1.0 : 0.6;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32), // Squircle matching home
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF1A1D1C,
                ).withValues(alpha: 0.6), // Frosted glass dark
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isActive
                      ? tier.gradientColors.last.withValues(alpha: 0.5)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: tier.gradientColors.first.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 25,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  // Top Accent Line
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        gradient: LinearGradient(colors: tier.gradientColors),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Icon and Name
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(tier.icon, color: canopiText, size: 28),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          tier.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: canopiText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              tier.price == 0 ? "Free" : "₦${tier.price}",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: canopiText,
                                letterSpacing: -1.0,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            if (tier.price > 0)
                              const Text(
                                " / lifetime",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: canopiSubtitle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Features List
                        Expanded(
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: tier.features.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF22C55E,
                                      ).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tier.features[index],
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                        color: canopiSubtitle,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Action Button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              32,
                            ), // Pill shape 32px
                            color: isActive
                                ? (tier.id == 'freemium'
                                    ? theme.colorScheme.surfaceContainerHighest
                                    : theme.colorScheme.primary)
                                : const Color(
                                    0xFF232325,
                                  ).withValues(alpha: 0.5),
                            boxShadow: isActive && tier.id != 'freemium'
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF22C55E,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(32),
                              onTap: () => _onTierSelected(tier.id, context),
                              child: Center(
                                child: Text(
                                  tier.buttonText,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: isActive && tier.id != 'freemium'
                                        ? theme.scaffoldBackgroundColor
                                        : theme.colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
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
  final List<Color> gradientColors;
  final IconData icon;

  _TierModel({
    required this.id,
    required this.name,
    required this.price,
    required this.buttonText,
    required this.features,
    required this.gradientColors,
    required this.icon,
  });
}

List<_TierModel> _getSubscriptionTiers(ThemeData theme) {
  return [
    _TierModel(
      id: 'freemium',
      name: 'Freemium',
      price: 0,
      buttonText: 'Current Plan',
      gradientColors: [const Color(0xFF94A3B8), const Color(0xFF64748B)],
      icon: Icons.person_outline_rounded,
      features: [
        'Basic profile features',
        'Standard access to Traks resources',
        'Limited community interaction',
        'Standard support',
      ],
    ),
    _TierModel(
      id: 'premium',
      name: 'Premium',
      price: 3000,
      buttonText: 'Get Premium',
      gradientColors: [theme.colorScheme.primary, const Color(0xFF16A34A)],
      icon: Icons.workspace_premium_rounded,
      features: [
        'Blue Verified Checkmark',
        'Ad-Free Experience',
        'Priority Customer Support',
        'Enhanced Profile Visibility',
        'Exclusive Access to Premium Content',
      ],
    ),
    _TierModel(
      id: 'reporter',
      name: 'Reporter',
      price: 7000,
      buttonText: 'Become a Reporter',
      gradientColors: [theme.colorScheme.tertiary, const Color(0xFFCA8A04)],
      icon: Icons.campaign_rounded,
      features: [
        'Everything in Premium',
        'Official Reporter Identity Status',
        'Direct Data Export Capabilities',
        'Post Verified News and Alerts',
        'Access to Advanced Analytics',
      ],
    ),
  ];
}
