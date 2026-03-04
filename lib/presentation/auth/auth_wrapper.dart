import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_state.dart';
import 'package:tracks_app/presentation/home/home_page.dart';
import 'package:tracks_app/presentation/auth/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return const HomePage();
        } else if (state is Unauthenticated || state is AuthFailure) {
          return const LoginPage();
        }

        // Show loading indicator for AuthInitial or AuthLoading
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
