import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracks_app/core/theme/app_theme.dart';
import 'package:tracks_app/core/theme/theme_controller.dart';
import 'package:tracks_app/injection_container.dart' as di;
import 'package:tracks_app/presentation/blocs/post/post_bloc.dart';
import 'package:tracks_app/presentation/blocs/post/post_event.dart';
import 'package:tracks_app/presentation/blocs/search/search_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_bloc.dart';
import 'package:tracks_app/presentation/blocs/auth/auth_event.dart';
import 'package:tracks_app/presentation/blocs/location/location_cubit.dart';
import 'package:tracks_app/presentation/splash/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tracks_app/firebase_options.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppMain extends StatefulWidget {
  const AppMain({super.key});

  @override
  State<AppMain> createState() => _AppMainState();
}

class _AppMainState extends State<AppMain> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handlePaymentRedirect(uri);
    });

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handlePaymentRedirect(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial link: $e");
    }
  }

  void _handlePaymentRedirect(Uri uri) async {
    if (uri.scheme == 'traksapp' &&
        uri.queryParameters['status'] == 'success') {
      final userId = uri.queryParameters['userId'];
      if (userId != null && userId.isNotEmpty) {
        // Verification is now handled securely by the React frontend
        // before the redirect occurs.
        debugPrint("Payment success redirect received for user: $userId");
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(AuthCheckRequested()),
        ),
        BlocProvider(create: (_) => di.sl<LocationCubit>()),
        BlocProvider(create: (_) => di.sl<PostBloc>()..add(const FetchPosts())),
        BlocProvider(create: (_) => di.sl<SearchBloc>()),
      ],
      child: ValueListenableBuilder<ThemeState>(
        valueListenable: ThemeController.instance,
        builder: (context, themeState, child) {
          return MaterialApp(
            title: 'TRAKS',
            theme: AppTheme.getLightTheme(themeState.colorTheme),
            darkTheme: AppTheme.getDarkTheme(themeState.colorTheme),
            themeMode: themeState.mode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );

  runApp(const AppMain());
}
