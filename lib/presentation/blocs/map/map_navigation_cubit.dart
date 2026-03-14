import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/directions_service.dart';

// States
abstract class MapNavigationState extends Equatable {
  const MapNavigationState();

  @override
  List<Object?> get props => [];
}

class MapNavigationIdle extends MapNavigationState {}

class MapNavigationLoading extends MapNavigationState {}

class MapNavigationActive extends MapNavigationState {
  final List<LatLng> polylinePoints;
  final String distance;
  final String duration;
  final LatLng destination;
  final String destinationName;

  const MapNavigationActive({
    required this.polylinePoints,
    required this.distance,
    required this.duration,
    required this.destination,
    required this.destinationName,
  });

  @override
  List<Object?> get props =>
      [polylinePoints, distance, duration, destination, destinationName];
}

class MapNavigationError extends MapNavigationState {
  final String message;
  const MapNavigationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class MapNavigationCubit extends Cubit<MapNavigationState> {
  final DirectionsService _directionsService;

  MapNavigationCubit(this._directionsService) : super(MapNavigationIdle());

  Future<void> startNavigation({
    required LatLng origin,
    required LatLng destination,
    required String destinationName,
  }) async {
    emit(MapNavigationLoading());

    final data = await _directionsService.getDirections(
      origin: origin,
      destination: destination,
    );

    if (data != null && data['routes'].isNotEmpty) {
      final route = data['routes'][0];
      final leg = route['legs'][0];

      final points = _directionsService.decodePolyline(
        route['overview_polyline']['points'],
      );

      emit(MapNavigationActive(
        polylinePoints: points,
        distance: leg['distance']['text'],
        duration: leg['duration']['text'],
        destination: destination,
        destinationName: destinationName,
      ));
    } else {
      emit(const MapNavigationError(
          'Could not find a route to this destination.'));
    }
  }

  void cancelNavigation() {
    emit(MapNavigationIdle());
  }
}
