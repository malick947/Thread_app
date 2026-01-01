import 'package:cloud_firestore/cloud_firestore.dart';

class Watchlist {
  final String id;
  final String name;
  final String creatorId;
  final List<String> members;
  final DateTime createdAt;
  final String? description;
  final bool isPrivate;

  Watchlist({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.members,
    required this.createdAt,
    this.description,
    this.isPrivate = true,
  });

  factory Watchlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Watchlist(
      id: doc.id,
      name: data['name'] ?? '',
      creatorId: data['creatorId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      description: data['description'],
      isPrivate: data['isPrivate'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'creatorId': creatorId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPrivate': isPrivate,
      if (description != null) 'description': description,
    };
  }
}

class Movie {
  final String id;
  final String watchlistId;
  final String title;
  final String year;
  final String posterUrl;
  final String imdbId;
  final String type;
  final String genre;
  final String plot;
  final String rating;
  final DateTime? watchDate;
  final DateTime addedAt;
  final List<String> votedBy;
  final List<String> whereToWatch;

  Movie({
    required this.id,
    required this.watchlistId,
    required this.title,
    required this.year,
    required this.posterUrl,
    required this.imdbId,
    required this.type,
    this.genre = '',
    this.plot = '',
    this.rating = 'N/A',
    this.watchDate,
    required this.addedAt,
    required this.votedBy,
    this.whereToWatch = const [],
  });

  factory Movie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Movie(
      id: doc.id,
      watchlistId: data['watchlistId'] ?? '',
      title: data['title'] ?? '',
      year: data['year'] ?? '',
      posterUrl: data['posterUrl'] ?? '',
      imdbId: data['imdbId'] ?? '',
      type: data['type'] ?? '',
      genre: data['genre'] ?? '',
      plot: data['plot'] ?? '',
      rating: data['rating'] ?? 'N/A',
      watchDate: (data['watchDate'] as Timestamp?)?.toDate(),
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      votedBy: List<String>.from(data['votedBy'] ?? []),
      whereToWatch: List<String>.from(data['whereToWatch'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'watchlistId': watchlistId,
      'title': title,
      'year': year,
      'posterUrl': posterUrl,
      'imdbId': imdbId,
      'type': type,
      'genre': genre,
      'plot': plot,
      'rating': rating,
      'watchDate': watchDate != null ? Timestamp.fromDate(watchDate!) : null,
      'addedAt': Timestamp.fromDate(addedAt),
      'votedBy': votedBy,
      'whereToWatch': whereToWatch,
    };
  }

  bool get isCompleted => watchDate != null;
}

// OMDb Movie Search Result
class OMDbMovie {
  final String title;
  final String year;
  final String imdbId;
  final String type;
  final String poster;

  OMDbMovie({
    required this.title,
    required this.year,
    required this.imdbId,
    required this.type,
    required this.poster,
  });

  factory OMDbMovie.fromJson(Map<String, dynamic> json) {
    return OMDbMovie(
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      imdbId: json['imdbID'] ?? '',
      type: json['Type'] ?? '',
      poster: json['Poster'] ?? '',
    );
  }
}

// OMDb Movie Details
class OMDbMovieDetails {
  final String title;
  final String year;
  final String genre;
  final String plot;
  final String poster;
  final String imdbRating;
  final String imdbId;
  final String type;

  OMDbMovieDetails({
    required this.title,
    required this.year,
    required this.genre,
    required this.plot,
    required this.poster,
    required this.imdbRating,
    required this.imdbId,
    required this.type,
  });

  factory OMDbMovieDetails.fromJson(Map<String, dynamic> json) {
    return OMDbMovieDetails(
      title: json['Title'] ?? '',
      year: json['Year'] ?? '',
      genre: json['Genre'] ?? '',
      plot: json['Plot'] ?? '',
      poster: json['Poster'] ?? '',
      imdbRating: json['imdbRating'] ?? 'N/A',
      imdbId: json['imdbID'] ?? '',
      type: json['Type'] ?? '',
    );
  }
}
