import 'package:cloud_firestore/cloud_firestore.dart';

class SparkActivityModel {
  final String id;
  final bool isSpark; // Flag to identify spark activities
  final String category; // Event, Craft, Free
  final String actionButtonText; // Book, Get Supplies, Directions

  // Core details
  final String activityName;
  final String suggestion;
  final String mood;
  final String location;

  // Place details
  final String placeName;
  final String? vicinity;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  // Ratings & Reviews
  final double? rating;
  final int? userRatingsTotal;
  final List<Review>? reviews;

  // Pricing & Hours
  final String? priceLevel;
  final bool? openNow;

  // Links
  final String? websiteUrl;
  final String? googleMapsUrl;

  // Photo
  final String? photoReference;

  // Types/Tags
  final List<String> types;

  // Metadata
  final DateTime createdAt;
  final String threadId;
  final List<String> assignedTo;
  final String priority;
  final bool isCompleted;
  final String createdBy; // NEW: Added createdBy field

  SparkActivityModel({
    required this.id,
    this.isSpark = true,
    required this.category,
    required this.actionButtonText,
    required this.activityName,
    required this.suggestion,
    required this.mood,
    required this.location,
    required this.placeName,
    this.vicinity,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.rating,
    this.userRatingsTotal,
    this.reviews,
    this.priceLevel,
    this.openNow,
    this.websiteUrl,
    this.googleMapsUrl,
    this.photoReference,
    required this.types,
    required this.createdAt,
    required this.threadId,
    required this.assignedTo,
    this.priority = 'medium',
    this.isCompleted = false,
    required this.createdBy, // NEW: Required parameter
  });

  // Convert to Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'isSpark': isSpark,
      'category': category,
      'actionButtonText': actionButtonText,
      'activityName': activityName,
      'suggestion': suggestion,
      'mood': mood,
      'location': location,
      'placeName': placeName,
      'vicinity': vicinity,
      'formattedAddress': formattedAddress,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'reviews': reviews?.map((r) => r.toMap()).toList(),
      'priceLevel': priceLevel,
      'openNow': openNow,
      'websiteUrl': websiteUrl,
      'googleMapsUrl': googleMapsUrl,
      'photoReference': photoReference,
      'types': types,
      'createdAt': Timestamp.fromDate(createdAt),
      'threadId': threadId,
      'assignedTo': assignedTo,
      'priority': priority,
      'isCompleted': isCompleted,
      'createdBy': createdBy, // NEW: Include in Firestore
    };
  }

  // Create from Firestore
  factory SparkActivityModel.fromFirestore(Map<String, dynamic> data) {
    return SparkActivityModel(
      id: data['id'] ?? '',
      isSpark: data['isSpark'] ?? true,
      category: data['category'] ?? 'Event',
      actionButtonText: data['actionButtonText'] ?? 'Book',
      activityName: data['activityName'] ?? '',
      suggestion: data['suggestion'] ?? '',
      mood: data['mood'] ?? '',
      location: data['location'] ?? '',
      placeName: data['placeName'] ?? '',
      vicinity: data['vicinity'],
      formattedAddress: data['formattedAddress'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      rating: data['rating']?.toDouble(),
      userRatingsTotal: data['userRatingsTotal'],
      reviews: data['reviews'] != null
          ? (data['reviews'] as List)
                .map((r) => Review.fromMap(r as Map<String, dynamic>))
                .toList()
          : null,
      priceLevel: data['priceLevel'],
      openNow: data['openNow'],
      websiteUrl: data['websiteUrl'],
      googleMapsUrl: data['googleMapsUrl'],
      photoReference: data['photoReference'],
      types: List<String>.from(data['types'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      threadId: data['threadId'] ?? '',
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      priority: data['priority'] ?? 'medium',
      isCompleted: data['isCompleted'] ?? false,
      createdBy: data['createdBy'] ?? '', // NEW: Parse from Firestore
    );
  }

  // Create from GeneratedSparkResult
  factory SparkActivityModel.fromSparkResult({
    required String id,
    required String threadId,
    required List<String> assignedTo,
    required String category,
    required String actionButtonText,
    required String activityName,
    required String suggestion,
    required String mood,
    required String location,
    required String placeName,
    String? vicinity,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    double? rating,
    int? userRatingsTotal,
    List<Review>? reviews,
    String? priceLevel,
    bool? openNow,
    String? websiteUrl,
    String? googleMapsUrl,
    String? photoReference,
    required List<String> types,
    String priority = 'medium',
    required String createdBy, // NEW: Required parameter
  }) {
    return SparkActivityModel(
      id: id,
      isSpark: true,
      category: category,
      actionButtonText: actionButtonText,
      activityName: activityName,
      suggestion: suggestion,
      mood: mood,
      location: location,
      placeName: placeName,
      vicinity: vicinity,
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      reviews: reviews,
      priceLevel: priceLevel,
      openNow: openNow,
      websiteUrl: websiteUrl,
      googleMapsUrl: googleMapsUrl,
      photoReference: photoReference,
      types: types,
      createdAt: DateTime.now(),
      threadId: threadId,
      assignedTo: assignedTo,
      priority: priority,
      isCompleted: false,
      createdBy: createdBy, // NEW: Set createdBy
    );
  }

  String getPriceLevelDisplay() {
    if (priceLevel == null || priceLevel!.isEmpty) return '';
    try {
      return '\$' * int.parse(priceLevel!);
    } catch (e) {
      return priceLevel!;
    }
  }

  String getCategoryTag() {
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

  bool hasLocation() {
    return latitude != null && longitude != null;
  }

  SparkActivityModel copyWith({
    bool? isCompleted,
    String? priority,
    List<String>? assignedTo,
  }) {
    return SparkActivityModel(
      id: id,
      isSpark: isSpark,
      category: category,
      actionButtonText: actionButtonText,
      activityName: activityName,
      suggestion: suggestion,
      mood: mood,
      location: location,
      placeName: placeName,
      vicinity: vicinity,
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      reviews: reviews,
      priceLevel: priceLevel,
      openNow: openNow,
      websiteUrl: websiteUrl,
      googleMapsUrl: googleMapsUrl,
      photoReference: photoReference,
      types: types,
      createdAt: createdAt,
      threadId: threadId,
      assignedTo: assignedTo ?? this.assignedTo,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdBy: createdBy,
    );
  }
}

// Review Model
class Review {
  final String authorName;
  final double rating;
  final String text;
  final String? relativeTimeDescription;
  final int? time;

  Review({
    required this.authorName,
    required this.rating,
    required this.text,
    this.relativeTimeDescription,
    this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorName': authorName,
      'rating': rating,
      'text': text,
      'relativeTimeDescription': relativeTimeDescription,
      'time': time,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      authorName: map['author_name'] ?? map['authorName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      text: map['text'] ?? '',
      relativeTimeDescription:
          map['relative_time_description'] ?? map['relativeTimeDescription'],
      time: map['time'],
    );
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      authorName: json['author_name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      text: json['text'] ?? '',
      relativeTimeDescription: json['relative_time_description'],
      time: json['time'],
    );
  }
}
