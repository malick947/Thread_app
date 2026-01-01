import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

import 'package:the_read_thread/Model/placeModel.dart';
import 'package:the_read_thread/Model/sparkActivityModel.dart';

class SparkController extends GetxController {
  var isLoading = true.obs;
  var currentLocation = Rxn<Position>();
  var locationEnabled = false.obs;

  // For Gemini AI Spark Generator
  var isGeneratingSpark = false.obs;
  var generatedSpark = Rxn<GeneratedSparkResult>();
  var showSparkResult = false.obs;

  final String googleApiKey = 'AIzaSyCVCCiFROINgU_erA-fZjpEIwux-dTtwPo';
  final String geminiApiKey = 'AIzaSyBVnswBhO68H4L7RAw_5ylVeGf8aF6oqcE';

  // Track previous suggestions to avoid repetition
  final List<String> previousSuggestions = [];

  @override
  void onInit() {
    super.onInit();
    initializeLocation();
  }

  Future<void> initializeLocation() async {
    try {
      isLoading(true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'Location Disabled',
          'Please enable location services',
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
        isLoading(false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Permission Denied',
            'Location permission is required',
            backgroundColor: Color(0xFFAE1B25),
            colorText: Colors.white,
          );
          isLoading(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied',
          'Please enable location permission in settings',
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
        );
        isLoading(false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLocation.value = position;
      locationEnabled(true);
    } catch (e) {
      print('Error getting location: $e');
      Get.snackbar(
        'Error',
        'Failed to get location: $e',
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Generate AI Spark with updated prompt and logic
  Future<void> generateAISpark(String location, String mood) async {
    try {
      isGeneratingSpark(true);
      showSparkResult(false);

      // If location is empty, use current location
      String searchLocation = location.trim();
      if (searchLocation.isEmpty) {
        if (currentLocation.value != null) {
          searchLocation =
              '${currentLocation.value!.latitude},${currentLocation.value!.longitude}';
        } else {
          Get.snackbar(
            'Location Required',
            'Please enter a location or enable location services',
            backgroundColor: Color(0xFFAE1B25),
            colorText: Colors.white,
          );
          return;
        }
      }

      // Get current season and weather context
      final seasonContext = _getSeasonContext();

      // Call Gemini API with the new system prompt
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$geminiApiKey',
      );

      // Build the prompt with previous suggestions to avoid repetition
      String previousSuggestionsText = '';
      if (previousSuggestions.isNotEmpty) {
        previousSuggestionsText =
            '\n\nPREVIOUS SUGGESTIONS TO AVOID:\n${previousSuggestions.join('\n')}';
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''You are a spontaneous, slightly mischievous activity generator whose sole purpose is to inject fun, punchy, and highly specific chaos into the user's day. Your task is to generate exactly one unique, entertaining, and highly specific activity idea. The idea must be novel and never repeat. The idea MUST include a specific and actionable twist that elevates the core activity from mundane to memorable. If the user explicitly requests a simple mood (e.g., 'simple', 'chill', 'classic', etc.), the creativity directive enforces a twist-free, SIMPLE activity. For all other moods (neutral or complex), the activity will be twist-free 50% of the time, and a mandatory twist will be applied the other 50%.

SAFETY GUIDELINE: Under no circumstances must the generated activity suggest anything illegal, dangerous, morbid, harmful, or violate ethical boundaries. All suggestions must be safe, publicly accessible, and positive experiences.

PUNCHY & SPECIFIC: The voice should be funny, slightly challenging, and actionable. If the user inputs a specific keyword (e.g., 'Pokemon', 'Knitting', 'Jazz'), the activity MUST be highly specific to that theme (e.g., a location-based contest or a targeted commercial suggestion, etc…). All suggestions MUST be relevant to the current season ($seasonContext) and local weather conditions.

VENUE DIVERSITY: For repeated requests, you MUST ensure that specific named venues (especially coffee shops and restaurants) are diverse and different from previous suggestions.

HIGHLY SPECIFIC EVENTS: For 'Event' activities (restaurants, museums, coffee shops, indoor locations, etc.), if the user's location is a city, you must name a specific, real-world, geocodable venue in that city (e.g., "The British Museum," "The Palomar Restaurant," "Grindsmith Coffee"). The specific venue name must be included in the 'idea' text, as this is used to locate the activity on the map. For coffee shops, ensure the suggestion reflects a unique theme or atmosphere (e.g., Cat Cafe, Vintage Bookstore Cafe, Minimalist Nordic spot).

You MUST actively diversify the assigned categories ('Event', 'Craft', 'Free') and ensure the chosen category logically aligns with the user's input (e.g., if the user provides a city or mentions going out/indoor activities, prioritize 'Event' or 'Free').

You MUST assign the idea to one of three categories: 'Event', 'Craft', or 'Free'.
- Event: Activities that require leaving the home/current location to interact with a specific commercial or public venue (like a named coffee shop, restaurant, museum, concert, pop-up market, temporary exhibition, theater, shopping, karting, cinema, etc,… or any public venue for event or activity). If the generated idea specifies a commercial or public venue (e.g., "The British Museum" or "The Blue Door Cafe"), the category MUST be 'Event'. These are always "going out" activities and require a specific location name if possible.
- Craft: Creative activities, usually done at home or a fixed base location, requiring specific supplies or materials (making things, contests, DIY, building, fashion, etc...). These never require you to go to a specific commercial venue other than maybe a general supply store.
- Free: Activities requiring no money, focusing on physical location or movement (parks, running, walking, hiking, biking, etc...). This category covers a wide range of seasonally appropriate activities, including cycling, swimming/surfing in coastal areas, camping, window shopping contests, and quirky park challenges. For a 'Free' idea, if a specific landmark or path is not named, the activity MUST be phrased to explicitly utilize the user's local area (e.g., "your nearby park," "a local street," or "neighborhood green space") to ensure the idea is immediately applicable, suggesting activities 'around your location'.

The output MUST be a JSON object following this format:
{
  "category": "Event" | "Craft" | "Free",
  "idea": "precise, actionable sentence with specific venue name if Event",
  "actionButtonText": "Book" (for Event) | "Get Supplies" (for Craft) | "Directions" (for Free),
  "venueName": "exact specific venue/place name if Event or Free with specific location, otherwise null",
  "locationQuery": "search query for Google Places API (venue name + city) or null for Craft"
}

User's mood: $mood
User's location: $searchLocation
Current season: $seasonContext
$previousSuggestionsText

Generate ONE novel, categorized activity idea that is different from all previous suggestions.''',
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 1.2, // Higher temperature for more variety
            'topP': 0.95,
            'topK': 40,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        // Clean and parse JSON
        String cleanText = text.trim();
        if (cleanText.startsWith('```json')) {
          cleanText = cleanText.substring(7);
        }
        if (cleanText.endsWith('```')) {
          cleanText = cleanText.substring(0, cleanText.length - 3);
        }
        cleanText = cleanText.trim();

        final jsonResponse = json.decode(cleanText);
        final category = jsonResponse['category'];
        final idea = jsonResponse['idea'];
        final actionButtonText = jsonResponse['actionButtonText'];
        final venueName = jsonResponse['venueName'];
        final locationQuery = jsonResponse['locationQuery'];

        // Add to previous suggestions to avoid repetition
        previousSuggestions.add(idea);
        if (previousSuggestions.length > 10) {
          previousSuggestions.removeAt(0); // Keep only last 10
        }

        // For Event and Free categories, try to find the actual place
        PlaceModel? matchedPlace;
        List<Review>? reviews;

        if (category == 'Event' || (category == 'Free' && venueName != null)) {
          // Search for the venue
          if (locationQuery != null && locationQuery.isNotEmpty) {
            final places = await searchPlacesByText(locationQuery);
            if (places.isNotEmpty) {
              matchedPlace = places.first;
              // Get detailed information including reviews
              final detailedPlace = await getPlaceDetailsWithReviews(
                matchedPlace.placeId,
              );
              matchedPlace = detailedPlace['place'];
              reviews = detailedPlace['reviews'];
            }
          }
        }

        // If no place found for Event/Free, create a placeholder
        if (matchedPlace == null &&
            (category == 'Event' || category == 'Free')) {
          // Try reverse geocoding for current location or parse coordinates
          double? lat, lng;

          if (searchLocation.contains(',')) {
            // Coordinates provided
            final coords = searchLocation.split(',');
            lat = double.tryParse(coords[0].trim());
            lng = double.tryParse(coords[1].trim());
          } else if (currentLocation.value != null) {
            lat = currentLocation.value!.latitude;
            lng = currentLocation.value!.longitude;
          }

          matchedPlace = PlaceModel(
            placeId: 'spark_${DateTime.now().millisecondsSinceEpoch}',
            name: venueName ?? idea,
            vicinity: searchLocation,
            types: [category.toLowerCase()],
            lat: lat,
            lng: lng,
          );
        } else if (matchedPlace == null) {
          // For Craft activities, create a home-based placeholder
          matchedPlace = PlaceModel(
            placeId: 'spark_craft_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Craft Activity at Home',
            vicinity: 'At your location',
            types: ['craft', 'home_activity'],
            lat: currentLocation.value?.latitude,
            lng: currentLocation.value?.longitude,
          );
        }

        generatedSpark.value = GeneratedSparkResult(
          place: matchedPlace,
          suggestion: idea,
          mood: mood,
          location: searchLocation,
          category: category,
          actionButtonText: actionButtonText,
          websiteUrl: matchedPlace.website,
          reviews: reviews,
        );

        showSparkResult(true);

        Get.snackbar(
          'Spark Generated! 🔥',
          'Found the perfect match for your $mood mood',
          backgroundColor: Color(0xFFAE1B25),
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );
      } else {
        throw Exception('Failed to generate spark: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating spark: $e');
      Get.snackbar(
        'Error',
        'Failed to generate spark. Please try again.',
        backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
      );
    } finally {
      isGeneratingSpark(false);
    }
  }

  // Search places by text query
  Future<List<PlaceModel>> searchPlacesByText(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/textsearch/json?'
        'query=${Uri.encodeComponent(query)}'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          List<PlaceModel> places = [];

          for (var result in results) {
            places.add(PlaceModel.fromJson(result));
          }

          return places;
        }
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  // Get place details including website and reviews
  Future<Map<String, dynamic>> getPlaceDetailsWithReviews(
    String placeId,
  ) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=name,vicinity,formatted_address,geometry,rating,user_ratings_total,types,photos,opening_hours,price_level,website,url,reviews'
        '&key=$googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];

          // Parse reviews
          List<Review>? reviews;
          if (result['reviews'] != null) {
            reviews = (result['reviews'] as List)
                .map((r) => Review.fromJson(r as Map<String, dynamic>))
                .toList();
          }

          return {
            'place': PlaceModel.fromJsonWithWebsite(result),
            'reviews': reviews,
          };
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }

    return {'place': PlaceModel.fromJson({}), 'reviews': null};
  }

  // Get current season context
  String _getSeasonContext() {
    final now = DateTime.now();
    final month = now.month;

    if (month >= 3 && month <= 5) {
      return 'Spring';
    } else if (month >= 6 && month <= 8) {
      return 'Summer';
    } else if (month >= 9 && month <= 11) {
      return 'Autumn/Fall';
    } else {
      return 'Winter';
    }
  }

  // Reroll Spark (generate a new suggestion)
  Future<void> rerollSpark() async {
    if (generatedSpark.value != null) {
      await generateAISpark(
        generatedSpark.value!.location,
        generatedSpark.value!.mood,
      );
    }
  }

  // Clear spark result
  void clearSparkResult() {
    showSparkResult(false);
    generatedSpark.value = null;
  }

  // Create SparkActivityModel from current spark
  SparkActivityModel? createSparkActivityModel({
    required String activityId,
    required String threadId,
    required List<String> assignedTo,
    String priority = 'medium',
  }) {
    final spark = generatedSpark.value;
    if (spark == null) return null;

    final place = spark.place;

    // Get current user ID from Firebase Auth
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      print('Error: No user logged in');
      return null;
    }

    return SparkActivityModel.fromSparkResult(
      id: activityId,
      threadId: threadId,
      assignedTo: assignedTo,
      category: spark.category,
      actionButtonText: spark.actionButtonText,
      activityName: place.name,
      suggestion: spark.suggestion,
      mood: spark.mood,
      location: spark.location,
      placeName: place.name,
      vicinity: place.vicinity,
      formattedAddress: place.vicinity,
      latitude: place.lat,
      longitude: place.lng,
      rating: place.rating,
      userRatingsTotal: place.userRatingsTotal,
      reviews: spark.reviews,
      priceLevel: place.priceLevel,
      openNow: place.openNow,
      websiteUrl: place.website,
      googleMapsUrl: place.googleMapsUrl,
      photoReference: place.photoReference,
      types: place.types,
      priority: priority,
      createdBy: currentUserId, // NEW: Pass the current user ID
    );
  }
}

// Model for Generated Spark Result
class GeneratedSparkResult {
  final PlaceModel place;
  final String suggestion;
  final String mood;
  final String location;
  final String category; // Event, Craft, or Free
  final String actionButtonText; // Book, Get Supplies, or Directions
  final String? websiteUrl;
  final List<Review>? reviews;

  GeneratedSparkResult({
    required this.place,
    required this.suggestion,
    required this.mood,
    required this.location,
    required this.category,
    required this.actionButtonText,
    this.websiteUrl,
    this.reviews,
  });
}
