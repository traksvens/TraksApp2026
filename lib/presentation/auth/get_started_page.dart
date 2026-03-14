import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme
          .scaffoldBackgroundColor, // Very dark, slightly greenish background
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    theme.colorScheme.primary.withOpacity(0.5), // Greenish glow
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.3,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary
                    .withOpacity(0.4), // Yellow-green glow
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Logo section mimicking the small 'cp' logo
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface
                          .withOpacity(0.0), // Transparent to match image
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons
                          .cloud_circle_outlined, // Cloud looks somewhat like the 'cp' shape
                      color: theme.colorScheme.onSurface,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Welcome Text
                Text(
                  'Welcome to',
                  style: GoogleFonts.inter(
                    color: theme.hintColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'NasBombs',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurface,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                    height: 1.1,
                  ),
                ),

                const SizedBox(height: 24),

                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'Share Real-Time Incident Reports\nwith your Community.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: theme.hintColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                const Spacer(),

                // Feature Cards Carousel exactly like Canopi
                SizedBox(
                  height: 150,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Card 1 (far left, cut off)
                      Positioned(
                        left: -40,
                        child: Transform.rotate(
                          angle: -0.05,
                          child: _buildFeatureCard(
                            child: _buildIconCardContent(
                                Icons.map_outlined, 'Map'),
                          ),
                        ),
                      ),

                      // Card 2 (Tasks/Report)
                      Positioned(
                        left: 90,
                        top: 10,
                        child: Transform.rotate(
                          angle: 0.08, // rotated right
                          child: _buildFeatureCard(
                            child: _buildIconCardContent(
                                Icons.fact_check_outlined, 'Logs'),
                          ),
                        ),
                      ),

                      // Card 3 (Photo)
                      Positioned(
                        left: 215,
                        top: -5,
                        child: Transform.rotate(
                          angle: -0.06, // rotated left
                          child: _buildFeatureCard(
                            isImage: true,
                            child: const Align(
                              alignment: Alignment.bottomCenter,
                              child: Text(
                                'Photo',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Card 4 (Website/Alerts)
                      Positioned(
                        left: 345,
                        top: 5,
                        child: Transform.rotate(
                          angle: 0.05, // rotated right
                          child: _buildFeatureCard(
                            child: _buildIconCardContent(
                                Icons.manage_search, 'Explore'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Buttons at the bottom
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    children: [
                      _buildBottomButton(
                        context: context,
                        text: 'Create Account',
                        icon: Icons.person_add,
                        isSignUp: true,
                      ),
                      const SizedBox(height: 16),
                      _buildBottomButton(
                        context: context,
                        text: 'Sign In',
                        icon: Icons.login,
                        isSignUp: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required bool isSignUp,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 64, // Exact height to match the thick pill shape
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginPage(isSignUp: isSignUp),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              theme.colorScheme.surfaceContainerHighest, // True black button
          foregroundColor: theme.colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSignUp ? Icons.apple : Icons.email,
                size: 24,
                color: Colors
                    .white), // Using Apple icon visually just to keep up aesthetic
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({required Widget child, bool isImage = false}) {
    return Container(
      width: 115,
      height: 115,
      decoration: BoxDecoration(
        color: isImage
            ? Colors.grey[800]
            : theme.colorScheme
                .surfaceContainerHighest, // Dark squircle specific to the canopi card
        borderRadius:
            BorderRadius.circular(32), // Extremely rounded squircle shape
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.surface.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
        image: isImage
            ? const DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1541701494587-cb58502866ab?q=80&w=2670&auto=format&fit=crop'), // Example black and white architecture image
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(theme.colorScheme.surface38, BlendMode.darken),
              )
            : null,
      ),
      padding: isImage
          ? const EdgeInsets.only(bottom: 12)
          : const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _buildIconCardContent(IconData icon, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
          size: 28,
        ),
        Text(
          title,
          style: GoogleFonts.inter(
            color: theme.colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
