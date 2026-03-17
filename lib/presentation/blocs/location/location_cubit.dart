import 'package:hydrated_bloc/hydrated_bloc.dart';
import '../../../core/services/analytics_service.dart';
import 'location_state.dart';

class LocationCubit extends HydratedCubit<LocationState> {
  LocationCubit() : super(const LocationState());

  void updateLocation(double lat, double lng, {double? accuracy}) {
    emit(state.copyWith(lastKnownLat: lat, lastKnownLng: lng));
    AnalyticsHelper.trackLocationFetched(lat, lng, accuracy: accuracy);
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
