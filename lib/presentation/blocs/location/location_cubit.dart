import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'location_state.dart';

class LocationCubit extends HydratedCubit<LocationState> {
  LocationCubit() : super(const LocationState());

  void updateLocation(double lat, double lng) {
    emit(state.copyWith(lastKnownLat: lat, lastKnownLng: lng));
  }

  @override
  LocationState? fromJson(Map<String, dynamic> json) {
    return LocationState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(LocationState state) {
    return state.toJson();
  }
}
