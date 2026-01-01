import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:the_read_thread/Model/moviesModel.dart';

class MovieController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  final String omdbApiKey = '87886a75';

  final RxBool isSearching = false.obs;
  final RxList<OMDbMovie> searchResults = <OMDbMovie>[].obs;
  var selectedTab = 0.obs; // 0 = Watchlists, 1 = Completed

  // ============ WATCHLIST CRUD ============

  // Create new watchlist with privacy and members
  Future<void> createWatchlist({
    required String name,
    String? description,
    required bool isPrivate,
    required List<String> members,
  }) async {
    if (currentUserId == null) return;

    try {
      // Build members list
      List<String> finalMembers = [currentUserId!];
      if (!isPrivate && members.isNotEmpty) {
        finalMembers.addAll(members);
      }
      finalMembers = finalMembers.toSet().toList(); // Remove duplicates

      final watchlist = Watchlist(
        id: '',
        name: name,
        creatorId: currentUserId!,
        members: finalMembers,
        createdAt: DateTime.now(),
        description: description,
        isPrivate: isPrivate,
      );

      final docRef = await _firestore
          .collection('watchlists')
          .add(watchlist.toFirestore());

      await docRef.update({'id': docRef.id});

      // Silent success - no snackbar
    } catch (e) {
      print('Error creating watchlist: $e');
    }
  }

  // Get user's watchlists
  Stream<List<Watchlist>> getUserWatchlists() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('watchlists')
        .where('members', arrayContains: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Watchlist.fromFirestore(doc))
              .toList();
        });
  }

  // Delete watchlist
  Future<void> deleteWatchlist(String watchlistId) async {
    try {
      final moviesSnapshot = await _firestore
          .collection('watchlists')
          .doc(watchlistId)
          .collection('Movies')
          .get();

      for (var doc in moviesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('watchlists').doc(watchlistId).delete();
    } catch (e) {
      print('Error deleting watchlist: $e');
    }
  }

  // Get watchlist movie count
  Future<int> getWatchlistMovieCount(String watchlistId) async {
    try {
      final snapshot = await _firestore
          .collection('watchlists')
          .doc(watchlistId)
          .collection('Movies')
          .where('watchDate', isNull: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Add/remove member from watchlist
  Future<void> toggleWatchlistMember(
    String watchlistId,
    String memberId,
  ) async {
    try {
      final doc = await _firestore
          .collection('watchlists')
          .doc(watchlistId)
          .get();
      final members = List<String>.from(doc['members']);

      if (members.contains(memberId)) {
        await _firestore.collection('watchlists').doc(watchlistId).update({
          'members': FieldValue.arrayRemove([memberId]),
        });
      } else {
        await _firestore.collection('watchlists').doc(watchlistId).update({
          'members': FieldValue.arrayUnion([memberId]),
        });
      }
    } catch (e) {
      print("Error toggling member: $e");
    }
  }

  // In MovieController class, add this method:
  Stream<Watchlist?> getWatchlistStream(String watchlistId) {
    return _firestore.collection('watchlists').doc(watchlistId).snapshots().map(
      (snapshot) {
        if (snapshot.exists) {
          return Watchlist.fromFirestore(snapshot);
        }
        return null;
      },
    );
  }

  // In MovieController class, add this method:
  Stream<List<Movie>> getWatchlistMoviesStream(String watchlistId) {
    return _firestore
        .collection('watchlists')
        .doc(watchlistId)
        .collection('Movies')
        .where('watchDate', isNull: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();
        });
  }

  // Update watchlist privacy
  Future<void> updateWatchlistPrivacy(
    String watchlistId,
    bool isPrivate,
  ) async {
    try {
      await _firestore.collection('watchlists').doc(watchlistId).update({
        'isPrivate': isPrivate,
      });
    } catch (e) {
      print("Error updating privacy: $e");
    }
  }

  // ============ MOVIE OPERATIONS ============

  // Search movies from OMDb API - NO SNACKBARS
  Future<void> searchMovies(String query) async {
    isSearching.value = true;
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    try {
      isSearching(true);
      final url = Uri.parse(
        'https://www.omdbapi.com/?apikey=$omdbApiKey&s=$query',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['Response'] == 'True') {
          final List<dynamic> results = data['Search'] ?? [];
          searchResults.value = results
              .map((movie) => OMDbMovie.fromJson(movie))
              .toList();
        } else {
          searchResults.clear();
          // NO SNACKBAR - silent behavior
        }
      }
    } catch (e) {
      print('Error searching movies: $e');
      // NO SNACKBAR
    } finally {
      isSearching(false);
    }
    isSearching.value = false;
  }

  // Get movie details from OMDb
  Future<OMDbMovieDetails?> getMovieDetails(String imdbId) async {
    try {
      final url = Uri.parse(
        'https://www.omdbapi.com/?apikey=$omdbApiKey&i=$imdbId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Response'] == 'True') {
          return OMDbMovieDetails.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error getting movie details: $e');
      return null;
    }
  }

  // Add movie to watchlist - NO SNACKBAR
  Future<void> addMovieToWatchlist({
    required String watchlistId,
    required OMDbMovie movie,
  }) async {
    if (currentUserId == null) return;

    try {
      final details = await getMovieDetails(movie.imdbId);

      final movieData = Movie(
        id: '',
        watchlistId: watchlistId,
        title: movie.title,
        year: movie.year,
        posterUrl: movie.poster != 'N/A' ? movie.poster : '',
        imdbId: movie.imdbId,
        type: movie.type,
        genre: details?.genre ?? '',
        plot: details?.plot ?? '',
        rating: details?.imdbRating ?? 'N/A',
        addedAt: DateTime.now(),
        votedBy: [],
        whereToWatch: _detectStreamingPlatforms(details?.title ?? movie.title),
      );

      await _firestore
          .collection('watchlists')
          .doc(watchlistId)
          .collection('Movies')
          .add(movieData.toFirestore());

      // NO SNACKBAR - silent success
    } catch (e) {
      print('Error adding movie: $e');
    }
  }

  // Get watchlist movies (not completed)
  Stream<List<Movie>> getWatchlistMovies(String watchlistId) {
    return _firestore
        .collection('watchlists')
        .doc(watchlistId)
        .collection('Movies')
        .where('watchDate', isNull: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Movie.fromFirestore(doc)).toList();
        });
  }

  // Get all completed movies (across all watchlists)
  Stream<List<Movie>> getAllCompletedMovies() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('watchlists')
        .where('members', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((watchlistsSnapshot) async {
          List<Movie> allMovies = [];

          for (var watchlistDoc in watchlistsSnapshot.docs) {
            final moviesSnapshot = await _firestore
                .collection('watchlists')
                .doc(watchlistDoc.id)
                .collection('Movies')
                .where('watchDate', isNull: false)
                .get();

            for (var movieDoc in moviesSnapshot.docs) {
              allMovies.add(Movie.fromFirestore(movieDoc));
            }
          }

          allMovies.sort(
            (a, b) => (b.watchDate ?? DateTime.now()).compareTo(
              a.watchDate ?? DateTime.now(),
            ),
          );

          return allMovies;
        });
  }

  // Set watch date (mark as completed)
  Future<void> setWatchDate({
    required String watchlistId,
    required String movieId,
    required DateTime date,
  }) async {
    try {
      await _firestore
          .collection('watchlists')
          .doc(watchlistId)
          .collection('Movies')
          .doc(movieId)
          .update({'watchDate': Timestamp.fromDate(date)});
    } catch (e) {
      print('Error setting watch date: $e');
    }
  }

  // Mark as watched (set to today's date)
  Future<void> markAsWatched({
    required String watchlistId,
    required String movieId,
  }) async {
    try {
      await _firestore
          .collection('watchlists')
          .doc(watchlistId)
          .collection('Movies')
          .doc(movieId)
          .update({'watchDate': Timestamp.fromDate(DateTime.now())});
    } catch (e) {
      print('Error marking as watched: $e');
    }
  }

  // Vote for a movie
  Future<void> toggleVote({
    required String watchlistId,
    required String movieId,
    required List<String> currentVotes,
  }) async {
    if (currentUserId == null) return;

    try {
      List<String> updatedVotes = List.from(currentVotes);

      if (updatedVotes.contains(currentUserId)) {
        updatedVotes.remove(currentUserId);
      } else {
        updatedVotes.add(currentUserId!);
      }

      await _firestore
          .collection('watchlists')
          .doc(watchlistId)
          .collection('Movies')
          .doc(movieId)
          .update({'votedBy': updatedVotes});
    } catch (e) {
      print('Error toggling vote: $e');
    }
  }

  // Helper: Detect streaming platforms
  List<String> _detectStreamingPlatforms(String title) {
    return ['Netflix', 'Hulu'];
  }

  void clearSearchResults() {
    searchResults.clear();
  }
}
