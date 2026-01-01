import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:the_read_thread/Controller/moviesController.dart';
import 'package:the_read_thread/Controller/friendsController.dart';
import 'package:the_read_thread/Model/moviesModel.dart';
import 'package:the_read_thread/UI/threadMovieScreen.dart';

class MoviesScreen extends StatelessWidget {
  final MovieController movieController = Get.put(MovieController());
  final FriendsController friendsController = Get.put(FriendsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateWatchlistDialog(context),
        backgroundColor: Color(0xFFAE1B25),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text('new_watchlist'.tr, style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            child: Column(
              children: [
                Text(
                  'movies'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'your_shared_watchlists'.tr,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(
              () => Row(
                children: [
                  _buildTab('watchlists'.tr, 0),
                  _buildTab('watched'.tr, 1),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
            child: Obx(() {
              switch (movieController.selectedTab.value) {
                case 0:
                  return WatchlistsTab();
                case 1:
                  return CompletedTab();
                default:
                  return WatchlistsTab();
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = movieController.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => movieController.selectedTab.value = index,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFFAE1B25) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Color(0xFFAE1B25).withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateWatchlistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final RxBool isPrivate = true.obs;
    final RxList<String> selectedFriends = <String>[].obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'create_new_watchlist'.tr,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'watchlist_name'.tr,
                  hintText: 'watchlist_name_hint'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'description_optional'.tr,
                  hintText: 'description_hint'.tr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.all(16),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              Obx(
                () => CheckboxListTile(
                  title: Text(
                    'private_watchlist'.tr,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('only_you_can_see'.tr),
                  value: isPrivate.value,
                  onChanged: (value) => isPrivate.value = value ?? true,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  tileColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Obx(() {
                if (!isPrivate.value) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Text(
                        'add_friends'.tr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Obx(() {
                          final friends = friendsController.friends;
                          if (friends.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'no_friends_available'.tr,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'add_friends_to_share'.tr,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              return Obx(
                                () => Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: CheckboxListTile(
                                    title: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _getAvatarColor(
                                            friend.id,
                                          ),
                                          radius: 16,
                                          child: Text(
                                            (friend.name ?? 'U')[0]
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(friend.name ?? 'Unknown'),
                                      ],
                                    ),
                                    value: selectedFriends.contains(friend.id),
                                    onChanged: (value) {
                                      if (value == true) {
                                        selectedFriends.add(friend.id);
                                      } else {
                                        selectedFriends.remove(friend.id);
                                      }
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ],
                  );
                }
                return SizedBox.shrink();
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                movieController.createWatchlist(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  isPrivate: isPrivate.value,
                  members: selectedFriends.toList(),
                );
                Get.back();
                Get.snackbar(
                  'created'.tr,
                  '${'watchlist_created_message'.tr.replaceAll('{name}', nameController.text.trim())}',
                  backgroundColor: Color(0xFFAE1B25),
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFAE1B25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'create'.tr,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
    ];
    return colors[id.hashCode % colors.length];
  }
}

// WATCHLISTS TAB
class WatchlistsTab extends StatelessWidget {
  final MovieController movieController = Get.find<MovieController>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Watchlist>>(
      stream: movieController.getUserWatchlists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_outlined, size: 80, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'no_watchlists_yet'.tr,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'create_watchlist_to_start'.tr,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Get.find<MoviesScreen>()._showCreateWatchlistDialog(
                      context,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFAE1B25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'create_first_watchlist'.tr,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final watchlists = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: watchlists.length,
          itemBuilder: (context, index) {
            final watchlist = watchlists[index];
            return WatchlistCard(watchlist: watchlist);
          },
        );
      },
    );
  }
}

// Watchlist Card
class WatchlistCard extends StatefulWidget {
  final Watchlist watchlist;
  final MovieController movieController = Get.find<MovieController>();

  WatchlistCard({required this.watchlist});

  @override
  State<WatchlistCard> createState() => _WatchlistCardState();
}

class _WatchlistCardState extends State<WatchlistCard> {
  late Stream<int> _movieCountStream;

  @override
  void initState() {
    super.initState();
    _movieCountStream = widget.movieController
        .getWatchlistMoviesStream(widget.watchlist.id)
        .map((movies) => movies.length);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => WatchlistMoviesScreen(watchlist: widget.watchlist));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.watchlist.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.watchlist.isPrivate)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'private'.tr,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (widget.watchlist.description != null &&
                          widget.watchlist.description!.isNotEmpty) ...[
                        SizedBox(height: 6),
                        Text(
                          widget.watchlist.description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Color(0xFFAE1B25),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('delete_watchlist'.tr, style: TextStyle(color: Color(0xFFAE1B25))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Stats Row
            Row(
              children: [
                // Movie Count with Stream
                StreamBuilder<int>(
                  stream: _movieCountStream,
                  builder: (context, snapshot) {
                    final movieCount = snapshot.data ?? 0;
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFFCE7F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            size: 14,
                            color: Color(0xFFAE1B25),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '$movieCount ${'movie_s'.tr}',
                            style: TextStyle(
                              color: Color(0xFFAE1B25),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(width: 12),

                // Members Avatars
                Expanded(child: _buildMemberAvatars()),

                // Arrow Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(0xFFAE1B25).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFFAE1B25),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberAvatars() {
    final currentUserId = widget.movieController.currentUserId;
    if (currentUserId == null) return SizedBox();

    final otherMemberIds = widget.watchlist.members
        .where((id) => id != currentUserId)
        .toList();

    final friendsController = Get.find<FriendsController>();

    if (otherMemberIds.isEmpty) {
      return Row(
        children: [
          _buildAvatar('ME', Color(0xFF2C3E50)),
          SizedBox(width: 8),
          Text(
            'just_you'.tr,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      );
    }

    final matchedFriends = friendsController.friends
        .where((friend) => otherMemberIds.contains(friend.id))
        .toList();

    final displayMembers = matchedFriends.take(3).toList();
    final remainingCount = otherMemberIds.length - displayMembers.length;

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          SizedBox(
            width: 32 + (displayMembers.length * 16),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: _buildAvatar('ME', Color(0xFF2C3E50)),
                ),
                ...displayMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final friend = entry.value;
                  final initials = (friend.name ?? '??')
                      .split(' ')
                      .map((e) => e.isNotEmpty ? e[0] : '')
                      .take(2)
                      .join()
                      .toUpperCase();

                  return Positioned(
                    left: 16 * (index + 1),
                    child: _buildAvatar(
                      initials.isEmpty ? '??' : initials,
                      _getAvatarColor(friend.id),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            otherMemberIds.length == 1
                ? 'one_other'.tr
                : '${otherMemberIds.length} ${'others'.tr}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String text, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
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
    ];
    return colors[id.hashCode % colors.length];
  }

  void _showDeleteDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'delete_watchlist'.tr,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${'delete_confirm_title'.tr.replaceAll('{name}', widget.watchlist.name)}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'delete_confirm_content'.tr,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              widget.movieController.deleteWatchlist(widget.watchlist.id);
              Get.back();
              Get.snackbar(
                'deleted'.tr,
                '${'watchlist_deleted_message'.tr.replaceAll('{name}', widget.watchlist.name)}',
                backgroundColor: Color(0xFFAE1B25),
                colorText: Colors.white,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFAE1B25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('delete'.tr, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// COMPLETED TAB (WATCHED)
class CompletedTab extends StatelessWidget {
  final MovieController movieController = Get.find<MovieController>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Movie>>(
      stream: movieController.getAllCompletedMovies(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 16),
                Text(
                  'no_watched_movies'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'mark_as_watched_to_see'.tr,
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
            return MovieCard(movie: movie, showSetDate: false);
          },
        );
      },
    );
  }
}

// Movie Card Widget
class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool showSetDate;
  final MovieController movieController = Get.find<MovieController>();

  MovieCard({required this.movie, required this.showSetDate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFB91C1C), width: 2),
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
              child: movie.posterUrl.isNotEmpty && movie.posterUrl != 'N/A'
                  ? Image.network(
                      movie.posterUrl,
                      width: 80,
                      height: 120,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4A4A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${movie.year} • ${movie.type.capitalize} ${movie.genre.isNotEmpty ? '• ' + movie.genre : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        movie.rating,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  if (movie.votedBy.isNotEmpty)
                    Row(
                      children: [
                        ...movie.votedBy.take(3).map((memberId) {
                          return Container(
                            margin: EdgeInsets.only(right: 4),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: _getAvatarColor(memberId),
                              child: Text(
                                memberId.substring(0, 2).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        Text(
                          '${movie.votedBy.length} ${'vote'.tr}${movie.votedBy.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            movieController.toggleVote(
                              watchlistId: movie.watchlistId,
                              movieId: movie.id,
                              currentVotes: movie.votedBy,
                            );
                          },
                          icon: Icon(
                            movie.votedBy.contains(
                                  movieController.currentUserId,
                                )
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                          ),
                          label: Text('vote'.tr),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFFAE1B25),
                            side: BorderSide(color: Color(0xFFAE1B25)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      if (showSetDate) ...[
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              movieController.markAsWatched(
                                watchlistId: movie.watchlistId,
                                movieId: movie.id,
                              );
                            },
                            icon: Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: Text(
                              'watched'.tr,
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFB91C1C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ],
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
      width: 80,
      height: 120,
      color: Colors.grey[300],
      child: Icon(Icons.movie, size: 40, color: Colors.grey[600]),
    );
  }

  Color _getAvatarColor(String id) {
    final colors = [
      Color(0xFFAE1B25),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
      Color(0xFF10B981),
    ];
    return colors[id.hashCode % colors.length];
  }
}