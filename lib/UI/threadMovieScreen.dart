import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Controller/moviesController.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Model/moviesModel.dart';
import 'package:the_read_thread/Model/UserModel.dart';
import 'package:the_read_thread/UI/moviesScreen.dart';

class WatchlistMoviesScreen extends StatefulWidget {
  final Watchlist watchlist;

  const WatchlistMoviesScreen({Key? key, required this.watchlist})
    : super(key: key);

  @override
  State<WatchlistMoviesScreen> createState() => _WatchlistMoviesScreenState();
}

class _WatchlistMoviesScreenState extends State<WatchlistMoviesScreen> {
  final MovieController movieController = Get.find<MovieController>();
  final FriendsController friendsController = Get.put(FriendsController());
  final TextEditingController searchController = TextEditingController();
  final RxBool _isSearching = false.obs;

  // Stream for real-time watchlist updates
  late Stream<Watchlist?> _watchlistStream;
  late Rx<Watchlist> _currentWatchlist;

  @override
  void initState() {
    super.initState();
    _currentWatchlist = widget.watchlist.obs;

    // Create a stream that listens to watchlist updates
    _watchlistStream = movieController.getWatchlistStream(widget.watchlist.id);

    // Listen to watchlist stream updates
    _watchlistStream.listen((updatedWatchlist) {
      if (updatedWatchlist != null && mounted) {
        _currentWatchlist.value = updatedWatchlist;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentWatchlist.value.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_currentWatchlist.value.isPrivate)
                    Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                ],
              ),
              if (_currentWatchlist.value.description != null)
                Text(
                  _currentWatchlist.value.description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.people_outline, color: Colors.black),
            onPressed: () => _showManageMembersDialog(),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Obx(
                  () => Row(
                    children: [
                      Icon(
                        _currentWatchlist.value.isPrivate
                            ? Icons.lock_open
                            : Icons.lock,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _currentWatchlist.value.isPrivate
                            ? 'Make Public'
                            : 'Make Private',
                      ),
                    ],
                  ),
                ),
                value: 'privacy',
              ),
            ],
            onSelected: (value) {
              if (value == 'privacy') {
                movieController.updateWatchlistPrivacy(
                  _currentWatchlist.value.id,
                  !_currentWatchlist.value.isPrivate,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.transparent,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.ondemand_video_outlined, color: Colors.grey[600]),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Add Movie/Show...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _isSearching.value = true;
                        movieController.searchMovies(value);
                      } else {
                        _isSearching.value = false;
                        movieController.clearSearchResults();
                      }
                    },
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      searchController.clear();
                      _isSearching.value = false;
                      movieController.clearSearchResults();
                    },
                  ),
              ],
            ),
          ),

          // Search hint
          Obx(
            () => _isSearching.value
                ? Container()
                : Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Search fetches movie details from external database',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),

          // Content Area
          Expanded(
            child: Obx(() {
              if (_isSearching.value && movieController.isSearching.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (_isSearching.value &&
                  movieController.searchResults.isNotEmpty) {
                return _buildSearchResults();
              }

              if (_isSearching.value && movieController.searchResults.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                );
              }

              return _buildWatchlistMovies();
            }),
          ),
        ],
      ),
    );
  }

  void _showManageMembersDialog() {
    final TextEditingController friendSearchController =
        TextEditingController();
    final RxString searchQuery = ''.obs;
    final RxBool isLoading = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Obx(
          () => Container(
            constraints: BoxConstraints(maxHeight: 600, minHeight: 400),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage Members',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),

                SizedBox(height: 8),
                Text(
                  'Add or remove friends from this watchlist',
                  style: TextStyle(color: Colors.grey[600]),
                ),

                SizedBox(height: 20),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[500], size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: friendSearchController,
                            decoration: InputDecoration(
                              hintText: 'Search friends...',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              searchQuery.value = value.toLowerCase();
                            },
                          ),
                        ),
                        if (friendSearchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 18,
                              color: Colors.grey[500],
                            ),
                            onPressed: () {
                              friendSearchController.clear();
                              searchQuery.value = '';
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Members Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF374151),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFAE1B25).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentWatchlist.value.members.length}',
                        style: TextStyle(
                          color: Color(0xFFAE1B25),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Friends List
                Expanded(
                  child: Obx(() {
                    if (friendsController.friends.isEmpty && !isLoading.value) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No friends yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add friends to invite them',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filter friends based on search
                    final filteredFriends = friendsController.friends.where((
                      friend,
                    ) {
                      final name = friend.name?.toLowerCase() ?? '';
                      return name.contains(searchQuery.value);
                    }).toList();

                    if (filteredFriends.isEmpty && searchQuery.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No friends found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = filteredFriends[index];
                        final isMember = _currentWatchlist.value.members
                            .contains(friend.id);

                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: _getAvatarColor(friend.id),
                              radius: 22,
                              child: Text(
                                (friend.name ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              friend.name ?? 'Unknown',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isMember
                                    ? Color(0xFF10B981).withOpacity(0.1)
                                    : Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isMember
                                      ? Color(0xFF10B981).withOpacity(0.3)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isMember ? Icons.check : Icons.add,
                                    size: 16,
                                    color: isMember
                                        ? Color(0xFF10B981)
                                        : Color(0xFF6B7280),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isMember ? 'Member' : 'Add',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isMember
                                          ? Color(0xFF10B981)
                                          : Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              movieController.toggleWatchlistMember(
                                _currentWatchlist.value.id,
                                friend.id,
                              );
                              // Show snackbar feedback
                              Get.snackbar(
                                isMember ? 'Removed' : 'Added',
                                '${friend.name} ${isMember ? 'removed from' : 'added to'} watchlist',
                                backgroundColor: isMember
                                    ? Color(0xFFAE1B25)
                                    : Color(0xFFAE1B25),
                                colorText: Colors.white,
                                duration: Duration(seconds: 2),
                              );
                            },
                          ),
                        );
                      },
                    );
                  }),
                ),

                SizedBox(height: 16),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFAE1B25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String id) {
    final colors = [
      Color(0xFFAE1B25),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
    ];
    return colors[id.hashCode % colors.length];
  }

  Widget _buildSearchResults() {
    return Obx(
      () => ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: movieController.searchResults.length,
        itemBuilder: (context, index) {
          final movie = movieController.searchResults[index];
          return SearchResultCard(
            movie: movie,
            onAdd: () async {
              await movieController.addMovieToWatchlist(
                watchlistId: _currentWatchlist.value.id,
                movie: movie,
              );
              searchController.clear();
              _isSearching.value = false;
              movieController.clearSearchResults();
              // Show success feedback
              Get.snackbar(
                'Added',
                '${movie.title} added to watchlist',
                backgroundColor: Color(0xFFAE1B25),
        colorText: Colors.white,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWatchlistMovies() {
    return StreamBuilder<List<Movie>>(
      stream: movieController.getWatchlistMovies(_currentWatchlist.value.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_outlined, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No movies yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Search and add movies to this watchlist',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final movie = snapshot.data![index];
            return MovieCard(movie: movie, showSetDate: true);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    _isSearching.close();
    super.dispose();
  }
}

// Search Result Card (unchanged)
class SearchResultCard extends StatelessWidget {
  final OMDbMovie movie;
  final VoidCallback onAdd;

  const SearchResultCard({Key? key, required this.movie, required this.onAdd})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFAE1B25), width: 2),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.poster.isNotEmpty && movie.poster != 'N/A'
                  ? Image.network(
                      movie.poster,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderPoster();
                      },
                    )
                  : _buildPlaceholderPoster(),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${movie.year} • ${movie.type.capitalize}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: Icon(Icons.add, size: 18, color: Colors.white),
                      label: Text(
                        'Add to Watchlist',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFAE1B25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderPoster() {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey[300],
      child: Icon(Icons.movie, size: 30, color: Colors.grey[600]),
    );
  }
}
