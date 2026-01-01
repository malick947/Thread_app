class PlaceModel {
  final String placeId;
  final String name;
  final String? vicinity;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types;
  final double? lat;
  final double? lng;
  final String? photoReference;
  final bool? openNow;
  final String? priceLevel;
  final String? website; // NEW: Website/URL field
  final String? googleMapsUrl; // NEW: Google Maps URL

  PlaceModel({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.rating,
    this.userRatingsTotal,
    required this.types,
    this.lat,
    this.lng,
    this.photoReference,
    this.openNow,
    this.priceLevel,
    this.website,
    this.googleMapsUrl,
  });

  // Update existing fromJson to handle website
  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    String? photoRef;
    if (json['photos'] != null && (json['photos'] as List).isNotEmpty) {
      photoRef = json['photos'][0]['photo_reference'];
    }

    return PlaceModel(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      vicinity: json['vicinity'] ?? json['formatted_address'],
      rating: json['rating']?.toDouble(),
      userRatingsTotal: json['user_ratings_total'],
      types: List<String>.from(json['types'] ?? []),
      lat: json['geometry']?['location']?['lat']?.toDouble(),
      lng: json['geometry']?['location']?['lng']?.toDouble(),
      photoReference: photoRef,
      openNow: json['opening_hours']?['open_now'],
      priceLevel: json['price_level']?.toString(),
      website: json['website'],
      googleMapsUrl: json['url'],
    );
  }

  // NEW: Factory constructor with website
  factory PlaceModel.fromJsonWithWebsite(Map<String, dynamic> json) {
    final place = PlaceModel.fromJson(json);
    return PlaceModel(
      placeId: place.placeId,
      name: place.name,
      vicinity: place.vicinity,
      rating: place.rating,
      userRatingsTotal: place.userRatingsTotal,
      types: place.types,
      lat: place.lat,
      lng: place.lng,
      photoReference: place.photoReference,
      openNow: place.openNow,
      priceLevel: place.priceLevel,
      website: json['website'],
      googleMapsUrl: json['url'],
    );
  }

  String getPhotoUrl(String apiKey) {
    if (photoReference == null) return '';
    return 'https://maps.googleapis.com/maps/api/place/photo?'
        'maxwidth=400&photo_reference=$photoReference&key=$apiKey';
  }

  String getPriceLevelDisplay() {
    if (priceLevel == null) return '';
    return '\$' * int.parse(priceLevel!);
  }

  String getCategoryTag() {
    // Simple logic to determine primary category
    if (types.contains('restaurant') ||
        types.contains('cafe') ||
        types.contains('food')) {
      return 'Food';
    } else if (types.contains('park') || types.contains('campground')) {
      return 'Outdoors';
    } else if (types.contains('museum') || types.contains('art_gallery')) {
      return 'Culture';
    } else if (types.contains('gym') || types.contains('spa')) {
      return 'Wellness';
    } else if (types.contains('amusement_park') ||
        types.contains('night_club')) {
      return 'Thrill';
    } else if (types.contains('movie_theater') || types.contains('bar')) {
      return 'Date';
    }
    return 'Adventure';
  }
}
