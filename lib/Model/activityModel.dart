import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final String activityDetails;
  final List<String> assignTo;
  final String createdBy;
  final String status;
  final bool isMemory;
  final String memoryDetails;
  final List<String> imagesURL;
  final Timestamp? completedAt;
  final String? completedBy;
  final Timestamp createdAt;
  final DateTime? activityDate;

  // NEW: Spark activity fields
  final bool isSpark;
  final String? sparkCategory; // Event, Craft, Free
  final String? sparkMood;
  final String? sparkSuggestion;
  final String? sparkLocation;
  final double? sparkLatitude;
  final double? sparkLongitude;
  final String? sparkPlaceName;
  final String? sparkVicinity;
  final double? sparkRating;
  final int? sparkUserRatingsTotal;
  final String? sparkWebsiteUrl;
  final String? sparkGoogleMapsUrl;
  final String? sparkActionButtonText;

  Activity({
    required this.id,
    required this.name,
    required this.activityDetails,
    required this.assignTo,
    required this.createdBy,
    required this.status,
    required this.isMemory,
    required this.memoryDetails,
    required this.imagesURL,
    this.completedAt,
    this.completedBy,
    required this.createdAt,
    this.activityDate,
    this.isSpark = false,
    this.sparkCategory,
    this.sparkMood,
    this.sparkSuggestion,
    this.sparkLocation,
    this.sparkLatitude,
    this.sparkLongitude,
    this.sparkPlaceName,
    this.sparkVicinity,
    this.sparkRating,
    this.sparkUserRatingsTotal,
    this.sparkWebsiteUrl,
    this.sparkGoogleMapsUrl,
    this.sparkActionButtonText,
  });

  // Getter for isSpark
  bool get getIsSpark => isSpark;

  // Getter for sparkCategory
  String? get getSparkCategory => sparkCategory;

  // Getter for sparkMood
  String? get getSparkMood => sparkMood;

  // Getter for sparkSuggestion
  String? get getSparkSuggestion => sparkSuggestion;

  // Getter for sparkLocation
  String? get getSparkLocation => sparkLocation;

  // Getter for sparkLatitude
  double? get getSparkLatitude => sparkLatitude;

  // Getter for sparkLongitude
  double? get getSparkLongitude => sparkLongitude;

  // Getter for sparkPlaceName
  String? get getSparkPlaceName => sparkPlaceName;

  // Getter for sparkVicinity
  String? get getSparkVicinity => sparkVicinity;

  // Getter for sparkRating
  double? get getSparkRating => sparkRating;

  // Getter for sparkUserRatingsTotal
  int? get getSparkUserRatingsTotal => sparkUserRatingsTotal;

  // Getter for sparkWebsiteUrl
  String? get getSparkWebsiteUrl => sparkWebsiteUrl;

  // Getter for sparkGoogleMapsUrl
  String? get getSparkGoogleMapsUrl => sparkGoogleMapsUrl;

  // Getter for sparkActionButtonText
  String? get getSparkActionButtonText => sparkActionButtonText;

  bool get isCompleted => status == 'completed';

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Check if this is a spark activity
    bool isSpark = data['isSpark'] ?? false;

    if (isSpark) {
      // Parse as spark activity
      return Activity(
        id: doc.id,
        name: data['activityName'] ?? data['placeName'] ?? 'Spark Activity',
        activityDetails: data['suggestion'] ?? '',
        assignTo: List<String>.from(data['assignedTo'] ?? []),
        createdBy: data['createdBy'] ?? '',
        status: data['isCompleted'] == true ? 'completed' : 'pending',
        isMemory: data['isMemory'] ?? false,
        memoryDetails: data['memoryDetails'] ?? '',
        imagesURL: List<String>.from(data['imagesURL'] ?? []),
        completedAt: data['completedAt'],
        completedBy: data['completedBy'],
        createdAt: data['createdAt'] ?? Timestamp.now(),
        activityDate: data['ActivityDate'] != null
            ? (data['ActivityDate'] as Timestamp).toDate()
            : null,
        isSpark: true,
        sparkCategory: data['category'],
        sparkMood: data['mood'],
        sparkSuggestion: data['suggestion'],
        sparkLocation: data['location'],
        sparkLatitude: data['latitude']?.toDouble(),
        sparkLongitude: data['longitude']?.toDouble(),
        sparkPlaceName: data['placeName'],
        sparkVicinity: data['vicinity'] ?? data['formattedAddress'],
        sparkRating: data['rating']?.toDouble(),
        sparkUserRatingsTotal: data['userRatingsTotal'],
        sparkWebsiteUrl: data['websiteUrl'],
        sparkGoogleMapsUrl: data['googleMapsUrl'],
        sparkActionButtonText: data['actionButtonText'],
      );
    } else {
      // Parse as regular activity
      return Activity(
        id: doc.id,
        name: data['name'] ?? '',
        activityDetails: data['activityDetails'] ?? '',
        assignTo: List<String>.from(data['assignTo'] ?? []),
        createdBy: data['createdBy'] ?? '',
        status: data['status'] ?? 'pending',
        isMemory: data['isMemory'] ?? false,
        memoryDetails: data['memoryDetails'] ?? '',
        imagesURL: List<String>.from(data['imagesURL'] ?? []),
        completedAt: data['completedAt'],
        completedBy: data['completedBy'],
        createdAt: data['createdAt'] ?? Timestamp.now(),
        activityDate: data['ActivityDate'] != null
            ? (data['ActivityDate'] as Timestamp).toDate()
            : null,
        isSpark: false,
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    if (isSpark) {
      // Convert spark activity to Firestore format
      return {
        'activityName': name,
        'placeName': sparkPlaceName ?? name,
        'suggestion': sparkSuggestion ?? activityDetails,
        'assignedTo': assignTo,
        'createdBy': createdBy,
        'isCompleted': status == 'completed',
        'status': status,
        'isMemory': isMemory,
        'memoryDetails': memoryDetails,
        'imagesURL': imagesURL,
        'completedAt': completedAt,
        'completedBy': completedBy,
        'createdAt': createdAt,
        'ActivityDate': activityDate != null
            ? Timestamp.fromDate(activityDate!)
            : null,
        'isSpark': true,
        'category': sparkCategory,
        'mood': sparkMood,
        'location': sparkLocation,
        'latitude': sparkLatitude,
        'longitude': sparkLongitude,
        'vicinity': sparkVicinity,
        'formattedAddress': sparkVicinity,
        'rating': sparkRating,
        'userRatingsTotal': sparkUserRatingsTotal,
        'websiteUrl': sparkWebsiteUrl,
        'googleMapsUrl': sparkGoogleMapsUrl,
        'actionButtonText': sparkActionButtonText,
      };
    } else {
      // Convert regular activity to Firestore format
      return {
        'name': name,
        'activityDetails': activityDetails,
        'assignTo': assignTo,
        'createdBy': createdBy,
        'status': status,
        'isMemory': isMemory,
        'memoryDetails': memoryDetails,
        'imagesURL': imagesURL,
        'completedAt': completedAt,
        'completedBy': completedBy,
        'createdAt': createdAt,
        'ActivityDate': activityDate != null
            ? Timestamp.fromDate(activityDate!)
            : null,
        'isSpark': false,
      };
    }
  }
}
