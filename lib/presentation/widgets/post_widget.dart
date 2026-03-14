import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/post_model.dart';
import '../blocs/post/post_bloc.dart';
import '../blocs/post/post_event.dart';
import '../post/post_detail_page.dart';
import 'full_screen_image_viewer.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../../data/models/rating_request.dart';

class PostWidget extends StatelessWidget {
  final PostModel post;

  const PostWidget({super.key, required this.post});

  String _formatDate(String timestamp) {
    if (timestamp.isEmpty) return "Just now";
    try {
      final date = DateTime.parse(timestamp);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${date.day} ${months[date.month - 1]}";
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // PERF: Using read instead of watch to prevent rebuilds on auth changes.
    // Auth state only changes on login/logout, not during normal usage.
    final authState = context.read<AuthBloc>().state;
    String currentUserId = '';
    if (authState is Authenticated) {
      currentUserId = authState.user.uid;
    }

    final userRating = post.ratedBy[currentUserId];
    final isConfirmed = userRating == 'confirm';
    final isRefuted = userRating == 'refute';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface
              .withValues(alpha: 0.6), // Glassmorphism container
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
          // Removing heavy shadows for a flatter, more modern look
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                );
              },
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.05),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.02),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP ROW (avatar + info)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          backgroundImage: post.userAvatarUrl != null
                              ? CachedNetworkImageProvider(post.userAvatarUrl!)
                              : null,
                          child: post.userAvatarUrl == null
                              ? Text(
                                  (post.userName?.isNotEmpty == true
                                          ? post.userName!
                                          : post.userId.length > 5
                                              ? post.userId
                                              : "U")
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.userName?.isNotEmpty == true
                                          ? post.userName!
                                          : (post.userId.length > 5
                                              ? post.userId.substring(0, 5)
                                              : post.userId),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (post.confirmCount > 5)
                                    const Icon(
                                      Icons.verified,
                                      size: 14,
                                      color: theme
                                          .colorScheme.primary, // Canopi Green
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "· ${_formatDate(post.timestamp)}",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // TEXT CONTENT
                    Text(
                      post.content,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.95,
                        ),
                      ),
                    ),

                    if (post.severity.isNotEmpty ||
                        post.incidentType.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (post.severity.isNotEmpty)
                            _buildTag(
                              label: post.severity.toUpperCase(),
                              color: _getSeverityColor(post.severity),
                              theme: theme,
                            ),
                          if (post.incidentType.isNotEmpty)
                            _buildTag(
                              label: post.incidentType,
                              color: theme.colorScheme.onSurface,
                              theme: theme,
                              isOutline: true,
                            ),
                        ],
                      ),
                    ],

                    if (post.absoluteImageUrl != null) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullScreenImageViewer(
                                imageUrl: post.absoluteImageUrl!,
                                post: post,
                                heroTag: 'post_image_${post.id}',
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: 'post_image_${post.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: post.absoluteImageUrl!,
                                fit: BoxFit
                                    .cover, // Ensures center crop by default
                                height: 220,
                                width: double.infinity,
                                placeholder: (context, url) => Container(
                                  height: 220,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 220,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: theme.disabledColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Action Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAction(
                          icon: Icons.chat_bubble_outline,
                          label: "${post.replyCount}",
                          color: theme.colorScheme.onSurface,
                          theme: theme,
                          isActive: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PostDetailPage(post: post),
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            _buildAction(
                              icon: isConfirmed
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_up_outlined,
                              label: "${post.confirmCount}",
                              color: Colors.green,
                              theme: theme,
                              isActive: isConfirmed,
                              onTap: () {
                                if (currentUserId.isNotEmpty) {
                                  context.read<PostBloc>().add(
                                        RatePostEvent(
                                          postId: post.id,
                                          request: RatingRequest(
                                            userId: currentUserId,
                                            rating: 'confirm',
                                          ),
                                        ),
                                      );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please sign in to rate posts',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildAction(
                              icon: isRefuted
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_down_outlined,
                              label: "${post.refuteCount}",
                              color: Colors.redAccent,
                              theme: theme,
                              isActive: isRefuted,
                              onTap: () {
                                if (currentUserId.isNotEmpty) {
                                  context.read<PostBloc>().add(
                                        RatePostEvent(
                                          postId: post.id,
                                          request: RatingRequest(
                                            userId: currentUserId,
                                            rating: 'refute',
                                          ),
                                        ),
                                      );
                                } else {
                                  // Prompt login or show snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please sign in to rate posts',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        _buildAction(
                          icon: Icons.share_outlined,
                          label: "",
                          color: theme.colorScheme.onSurface,
                          theme: theme,
                          isActive: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    final activeColor = isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return Material(
      color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
      borderRadius: BorderRadius.circular(32), // More pill-shaped
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color:
                  isActive ? color.withValues(alpha: 0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: activeColor),
              if (label.isNotEmpty && label != "0") ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color:
                        isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required String label,
    required Color color,
    required ThemeData theme,
    bool isOutline = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withValues(alpha: 0.12),
        border: isOutline
            ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2))
            : Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
