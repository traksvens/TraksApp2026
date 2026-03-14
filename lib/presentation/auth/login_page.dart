import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracks_app/core/theme/app_colors.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';

class LoginPage extends StatefulWidget {
  final bool isSignUp;
  const LoginPage({super.key, this.isSignUp = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late bool _isSignUp;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_isSignUp) {
        context.read<AuthBloc>().add(
              SignUpRequested(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
                displayName: _nameController.text.trim(),
              ),
            );
      } else {
        context.read<AuthBloc>().add(
              SignInRequested(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: GoogleFonts.inter(color: theme.colorScheme.onSurface),
              ),
              backgroundColor: AppColors.alertHigh,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme
            .scaffoldBackgroundColor, // Very dark, slightly greenish background
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: Stack(
          children: [
            // Background ambient gradient 1
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary
                      .withOpacity(0.5), // Greenish glow
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // Background ambient gradient 2
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.2,
              left: -100,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo mimicking the small 'cp' logo
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.0),
                        ),
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: const Icon(
                          Icons.cloud_circle_outlined,
                          color: theme.colorScheme.onSurface,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isSignUp ? 'Create\nAccount' : 'Welcome\nBack',
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.0,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isSignUp
                            ? 'Get started by creating your account below.'
                            : 'Log in to continue sharing and discovering.',
                        style: GoogleFonts.inter(
                          color: theme.hintColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 48),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.fastOutSlowIn,
                        child: _isSignUp
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 24),
                                child: _buildTextField(
                                  controller: _nameController,
                                  label: 'DISPLAY NAME',
                                  hint: 'Enter your display name',
                                  icon: Icons.person_outline,
                                  keyboardType: TextInputType.name,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'EMAIL',
                        hint: 'Enter your email',
                        icon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'PASSWORD',
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 40),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.onSurface,
                                strokeWidth: 3,
                              ),
                            );
                          }
                          return Column(
                            children: [
                              _PrimaryButton(
                                text: _isSignUp ? 'SIGN UP' : 'LOG IN',
                                onPressed: _submit,
                                backgroundColor: theme.colorScheme.onSurface,
                                textColor: theme.colorScheme.surface,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.inter(
                                        color: theme.hintColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: theme.colorScheme.onSurface.withOpacity(0.1),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _SecondaryButton(
                                text: 'Continue with Google',
                                icon: Icons.g_mobiledata,
                                onPressed: () {
                                  context.read<AuthBloc>().add(
                                        GoogleSignInRequested(),
                                      );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: _isSignUp
                                  ? "Already have an account? "
                                  : "Don't have an account? ",
                              style: GoogleFonts.inter(
                                color: theme.hintColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                              children: [
                                TextSpan(
                                  text: _isSignUp ? 'Log In' : 'Sign Up',
                                  style: GoogleFonts.inter(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: theme.hintColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500),
          cursorColor: theme.colorScheme.onSurface,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                fontSize: 16,
                fontWeight: FontWeight.w500),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest
                .withOpacity(0.6), // Dark squircle specific to the canopi card
            prefixIcon:
                Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6), size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.05), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  const BorderSide(color: AppColors.alertHigh, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide:
                  const BorderSide(color: AppColors.alertHigh, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 22, // Thick padding for tall inputs
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 64, // Exact height to match the thick pill shape
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.backgroundColor.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: GoogleFonts.inter(
                color: widget.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 64, // Exact height to match the thick pill shape
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surfaceContainerHighest, // True black button
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: theme.colorScheme.onSurface, size: 28),
              const SizedBox(width: 8),
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  color: theme.colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
