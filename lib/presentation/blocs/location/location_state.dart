import 'package:equatable/equatable.dart';

class LocationState extends Equatable {
  final double? lastKnownLat;
  final double? lastKnownLng;

  const LocationState({this.lastKnownLat, this.lastKnownLng});

  LocationState copyWith({double? lastKnownLat, double? lastKnownLng}) {
    return LocationState(
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLng: lastKnownLng ?? this.lastKnownLng,
    );
  }

  factory LocationState.fromJson(Map<String, dynamic> json) {
    return LocationState(
      lastKnownLat: json['lat'] as double?,
      lastKnownLng: json['lng'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'lat': lastKnownLat, 'lng': lastKnownLng};
  }

  @override
  List<Object?> get props => [lastKnownLat, lastKnownLng];
}
