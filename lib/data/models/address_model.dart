class AddressModel {
  final String? city;
  final String? state;
  final String? zipcode;
  final String? country;
  final String? road;
  final String? houseNumber;
  final String? shop;
  final String? neighbourhood;
  final String? countryCode;
  final String? formattedAddress;

  const AddressModel({
    this.city,
    this.state,
    this.zipcode,
    this.road,
    this.houseNumber,
    this.shop,
    this.neighbourhood,
    this.countryCode,
    this.country,
    this.formattedAddress,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      city: json['city'] as String?,
      state: json['state'] as String?,
      zipcode: json['zipcode'] as String?,
      country: json['country'] as String?,
      road: json['road'] as String?,
      houseNumber: json['house_number'] as String?,
      shop: json['shop'] as String?,
      neighbourhood: json['neighbourhood'] as String?,
      countryCode: json['country_code'] as String?,
      formattedAddress: json['formatted_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'state': state,
      'zipcode': zipcode,
      'country': country,
      'road': road,
      'house_number': houseNumber,
      'shop': shop,
      'neighbourhood': neighbourhood,
      'country_code': countryCode,
      'formatted_address': formattedAddress,
    };
  }

  AddressModel copyWith({
    String? city,
    String? state,
    String? zipcode,
    String? country,
    String? road,
    String? houseNumber,
    String? shop,
    String? neighbourhood,
    String? countryCode,
    String? formattedAddress,
  }) {
    return AddressModel(
      city: city ?? this.city,
      state: state ?? this.state,
      zipcode: zipcode ?? this.zipcode,
      country: country ?? this.country,
      road: road ?? this.road,
      houseNumber: houseNumber ?? this.houseNumber,
      shop: shop ?? this.shop,
      neighbourhood: neighbourhood ?? this.neighbourhood,
      countryCode: countryCode ?? this.countryCode,
      formattedAddress: formattedAddress ?? this.formattedAddress,
    );
  }
}
