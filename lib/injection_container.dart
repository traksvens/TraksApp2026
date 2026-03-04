import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../core/services/location_service.dart';
import '../../core/services/places_service.dart';
import '../../core/services/post_service.dart';
import '../../repository/post_repository.dart';
import '../../repository/post_repository_impl.dart';
import '../../repository/auth_repository.dart';
import '../../repository/auth_repository_impl.dart';
import '../../presentation/blocs/post/post_bloc.dart';
import '../../presentation/blocs/search/search_bloc.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/location/location_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Blocs
  sl.registerFactory(() => PostBloc(repository: sl()));
  sl.registerFactory(() => SearchBloc(repository: sl()));
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => LocationCubit());

  // Repositories
  sl.registerLazySingleton<PostRepository>(() => PostRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );

  // Services
  sl.registerLazySingleton(() => PostService(dio: sl()));
  sl.registerLazySingleton(() => PlacesService(sl()));
  sl.registerLazySingleton(() => LocationService());

  // External
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
}
