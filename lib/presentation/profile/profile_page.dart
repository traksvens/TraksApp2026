import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_event.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';
import 'package:tracks_app/core/theme/theme_controller.dart';
import 'package:tracks_app/core/theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final user = (state is Authenticated) ? state.user : null;

        final displayName = user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : (user?.email?.isNotEmpty == true
                  ? user!.email!.split('@').first
                  : "Anonymous");

        final email = user?.email ?? "";
        final photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Immersive Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Blurred Background Container (Fallback for hero image)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primaryColor.withValues(alpha: 0.8),
                              theme.colorScheme.secondary.withValues(
                                alpha: 0.4,
                              ),
                              theme.scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: theme.scaffoldBackgroundColor.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      // Content
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  backgroundImage: photoUrl != null
                                      ? NetworkImage(photoUrl)
                                      : null,
                                  child: photoUrl == null
                                      ? Text(
                                          displayName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: theme.textTheme.headlineMedium
                                              ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                displayName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. SOS Button Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement SOS action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A0303),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "SOS",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Settings Section
              SliverToBoxAdapter(
                child: ValueListenableBuilder<ThemeState>(
                  valueListenable: ThemeController.instance,
                  builder: (context, themeState, child) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(theme, "APPEARANCE"),
                          const SizedBox(height: 12),
                          _buildThemeModeSegmentedControl(
                            theme,
                            themeState.mode,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle(theme, "COLOR THEME"),
                          const SizedBox(height: 12),
                          _buildColorSwatchList(theme, themeState),
                          const SizedBox(height: 32),
                          _buildSectionTitle(theme, "ACCOUNT"),
                          const SizedBox(height: 12),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.emergency_share_outlined,
                            title: "SOS Customization",
                            subtitle:
                                "Configure emergency contacts and message",
                            iconColor: const Color(0xFF8B0000),
                          ),
                          const SizedBox(height: 16),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.notifications_none,
                            title: "Notifications",
                            subtitle: "Manage alerts",
                          ),
                          const SizedBox(height: 16),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.shield_outlined,
                            title: "Privacy & Security",
                            subtitle: "Biometrics, Password",
                          ),
                          const SizedBox(height: 16),
                          _buildSettingTile(
                            theme: theme,
                            icon: Icons.logout,
                            title: "Log Out",
                            iconColor: Colors.redAccent,
                            textColor: Colors.redAccent,
                            showChevron: false,
                            onTap: () {
                              context.read<AuthBloc>().add(SignOutRequested());
                            },
                          ),
                          const SizedBox(height: 100), // Spacing for Navbar
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.disabledColor,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? theme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (showChevron)
              Icon(Icons.chevron_right, color: theme.dividerColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSwatchList(ThemeData theme, ThemeState themeState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildColorSwatch(
            theme,
            AppColorTheme.teal,
            AppColors.themeTeal,
            themeState,
          ),
          _buildColorSwatch(
            theme,
            AppColorTheme.red,
            AppColors.themeRed,
            themeState,
          ),
          _buildColorSwatch(
            theme,
            AppColorTheme.brown,
            AppColors.themeBrown,
            themeState,
          ),
          _buildColorSwatch(
            theme,
            AppColorTheme.pink,
            AppColors.themePink,
            themeState,
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(
    ThemeData theme,
    AppColorTheme colorTheme,
    Color displayColor,
    ThemeState themeState,
  ) {
    final isSelected = themeState.colorTheme == colorTheme;
    final isDark = themeState.mode == ThemeMode.dark;

    return GestureDetector(
      onTap: () {
        ThemeController.instance.setColorTheme(colorTheme);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: displayColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 3,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: displayColor.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSelected
            ? Icon(Icons.check, color: isDark ? Colors.white : Colors.white)
            : null,
      ),
    );
  }

  Widget _buildThemeModeSegmentedControl(
    ThemeData theme,
    ThemeMode currentMode,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.wb_sunny_rounded, size: 18),
            label: Text("Light"),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_rounded, size: 18),
            label: Text("Auto"),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.nights_stay_rounded, size: 18),
            label: Text("Dark"),
          ),
        ],
        selected: {currentMode},
        onSelectionChanged: (Set<ThemeMode> newSelection) {
          ThemeController.instance.setTheme(newSelection.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return theme.primaryColor.withValues(alpha: 0.15);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return theme.primaryColor;
            }
            return theme.colorScheme.onSurface;
          }),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
