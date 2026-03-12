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

    // Get current user details to pass
    final authState = context.read<AuthBloc>().state;
    String uid = 'unknown';
    if (authState is Authenticated) {
      uid = authState.user.uid;
    }

    final returnUri = kIsWeb ? Uri.base.origin : 'traksapp://payment';
    final tierParam = tierName == 'premium' ? 'premium' : 'reporter';
    final baseUrl = dotenv.get('PAYMENT_UI_BASE_URL', fallback: 'https://traks-payment-ui.vercel.app/');

    final paymentUrl =
        '${baseUrl}?userId=$uid&return_url=$returnUri&tier=$tierParam';

    _launchPaymentUrl(paymentUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Modern Deep Black/Dark Mode aesthetics backbone
    final backgroundColor = theme.brightness == Brightness.dark
        ? const Color(0xFF0F0F13) // Deep AMOLED style background
        : const Color(0xFFF7F7F9);

    final textMain = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textMain,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Plans & Upgrades",
          style: TextStyle(
            color: textMain,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    "Choose Your Experience",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textMain,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Unlock premium features, exclusive identity marks, and priority tools tailored for you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textMain.withValues(alpha: 0.6),
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
                itemCount: _subscriptionTiers.length,
                itemBuilder: (context, index) {
                  final tier = _subscriptionTiers[index];
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
              children: List.generate(_subscriptionTiers.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isActive ? 24 : 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _subscriptionTiers[index].primaryColor
                        : Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required BuildContext context,
    required _TierModel tier,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scale = isActive ? 1.0 : 0.92;
    final opacity = isActive ? 1.0 : 0.6;

    // Glassmorphism card background
    final cardBgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      child: AnimatedOpacity(
        opacity: opacity,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardBgColor, cardBgColor.withValues(alpha: 0.01)],
            ),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: tier.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Stack(
                children: [
                  // Abstract decorative gradient orb
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            tier.primaryColor.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and Name
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tier.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            tier.icon,
                            color: tier.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          tier.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            foreground: Paint()
                              ..shader =
                                  LinearGradient(
                                    colors: tier.gradientColors,
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 200, 70),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              tier.price == 0 ? "Free" : "₦${tier.price}",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -1.0,
                              ),
                            ),
                            if (tier.price > 0)
                              Text(
                                " / lifetime",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      (isDark ? Colors.white : Colors.black87)
                                          .withValues(alpha: 0.5),
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
                                      color: tier.primaryColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: tier.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tier.features[index],
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
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
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: tier.gradientColors,
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: tier.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _onTierSelected(tier.id, context),
                              child: Center(
                                child: Text(
                                  tier.buttonText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
  final Color primaryColor;
  final List<Color> gradientColors;
  final IconData icon;

  _TierModel({
    required this.id,
    required this.name,
    required this.price,
    required this.buttonText,
    required this.features,
    required this.primaryColor,
    required this.gradientColors,
    required this.icon,
  });
}

final List<_TierModel> _subscriptionTiers = [
  _TierModel(
    id: 'freemium',
    name: 'Freemium',
    price: 0,
    buttonText: 'Current Plan',
    primaryColor: Colors.grey.shade500,
    gradientColors: [Colors.grey.shade400, Colors.grey.shade600],
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
    primaryColor: const Color(0xFFFFB300), // Amber/Gold
    gradientColors: [const Color(0xFFFFD54F), const Color(0xFFFF8F00)],
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
    primaryColor: const Color(0xFF6C63FF), // Indigo/Purple
    gradientColors: [const Color(0xFF8C9EFF), const Color(0xFF3D5AFE)],
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
