import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/models/post_model.dart';
import '../../data/models/replies_model.dart';
import '../../data/models/rating_request.dart';
import '../blocs/post/post_bloc.dart';
import '../blocs/post/post_event.dart';
import '../blocs/post/post_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../widgets/traks_logo.dart';
import '../widgets/full_screen_image_viewer.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<PostBloc>().add(FetchReplies(widget.post.id));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final content = _commentController.text.trim();

    final authState = context.read<AuthBloc>().state;
    String userId = 'anonymous'; // Fallback

    if (authState is Authenticated) {
      final user = authState.user;
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        userId = user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        userId = user.email!;
      } else {
        userId = user.uid;
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in to reply')));
      return;
    }

    if (content.isNotEmpty) {
      context.read<PostBloc>().add(
        CreateReply(postId: widget.post.id, userId: userId, content: content),
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _ratePost(String type) {
    final authState = context.read<AuthBloc>().state;
    String userId = '';

    if (authState is Authenticated) {
      userId = authState.user.uid;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to rate posts')),
      );
      return;
    }

    context.read<PostBloc>().add(
      RatePostEvent(
        postId: widget.post.id,
        request: RatingRequest(userId: userId, rating: type),
      ),
    );

    // Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "You marked this as ${type == 'confirm' ? 'confirmed' : 'refuted'}",
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final postTime = DateTime.tryParse(widget.post.timestamp) ?? DateTime.now();
    final dateStr = "${postTime.day}/${postTime.month}/${postTime.year}";
    final timeStr =
        "${postTime.hour}:${postTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: const Color(0xFF0D110F),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: const Color(0xFF0D110F),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const TraksLogo(fontSize: 20),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- 1. THE HERO POST (WITH UPDATES) ---
              SliverToBoxAdapter(
                child: BlocBuilder<PostBloc, PostState>(
                  builder: (context, state) {
                    // Try to find the latest version of this post in the state
                    final currentPost = state.posts.firstWhere(
                      (p) => p.id == widget.post.id,
                      orElse: () => widget.post,
                    );

                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author Row
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: const NetworkImage(
                                    "https://i.pravatar.cc/150?u=user",
                                  ),
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "User ${currentPost.userId.length > 6 ? currentPost.userId.substring(0, 6) : currentPost.userId}",
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.5,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      "@user_${currentPost.userId.length > 4 ? currentPost.userId.substring(0, 4) : currentPost.userId}",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme.hintColor,
                                            height: 1.1,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              _SeverityBadge(severity: currentPost.severity),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Post Content
                          SelectableText(
                            currentPost.content,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 21,
                              height: 1.35,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                          ),

                          if (currentPost.imageUrl != null) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageViewer(
                                      imageUrl: currentPost.imageUrl!,
                                      post: currentPost,
                                      heroTag:
                                          'post_detail_image_${currentPost.id}',
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'post_detail_image_${currentPost.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: CachedNetworkImage(
                                    imageUrl: currentPost.imageUrl!,
                                    width: double.infinity,
                                    fit: BoxFit.fitWidth,
                                    placeholder: (context, url) => Container(
                                      height: 240,
                                      color: colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          height: 100,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: theme.hintColor,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Metadata
                          Text(
                            "$timeStr · $dateStr · TRAKS for Android",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),

                          // Interaction Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ActionBarItem(
                                  icon: Icons.chat_bubble_outline_rounded,
                                  label: "Replies",
                                  count: currentPost.replyCount,
                                  onTap: () =>
                                      FocusScope.of(context).requestFocus(),
                                ),
                                _ActionBarItem(
                                  icon: Icons.keyboard_arrow_up_rounded,
                                  label: "Confirms",
                                  count: currentPost.confirmCount,
                                  activeColor: Colors.green,
                                  onTap: () => _ratePost('confirm'),
                                ),
                                _ActionBarItem(
                                  icon: Icons.keyboard_arrow_down_rounded,
                                  label: "Refutes",
                                  count: currentPost.refuteCount,
                                  activeColor: Colors.red,
                                  onTap: () => _ratePost('refute'),
                                ),
                                _ActionBarItem(
                                  icon: Icons.share_rounded,
                                  label: "Share",
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // --- 2. REPLIES HEADER ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverToBoxAdapter(
                  child: BlocBuilder<PostBloc, PostState>(
                    builder: (context, state) {
                      final replies = state.replies[widget.post.id] ?? [];
                      return Row(
                        children: [
                          Text(
                            "Replies",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (replies.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${replies.length}",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // --- 3. REPLIES LIST ---
              BlocBuilder<PostBloc, PostState>(
                builder: (context, state) {
                  final replies = state.replies[widget.post.id] ?? [];
                  final castedReplies = replies.cast<RepliesModel>();

                  if (state.status == PostStatus.loading &&
                      castedReplies.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (castedReplies.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 80,
                          horizontal: 40,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1D1C),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: Colors.white.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Be the first to reply",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Share your thoughts and start a conversation with the community.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(
                                  alpha: 0.5,
                                ),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _ReplyItem(reply: castedReplies[index]);
                    }, childCount: castedReplies.length),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // --- 3. INPUT AREA ---
          _GlassyReplyInput(
            controller: _commentController,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFF44336);
      case 'medium':
        return const Color(0xFFFF9800);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }
}

class _ActionBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? count;
  final Color? activeColor;
  final VoidCallback onTap;

  const _ActionBarItem({
    required this.icon,
    required this.label,
    this.count,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = activeColor ?? theme.hintColor.withValues(alpha: 0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: color),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    "$count",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyItem extends StatelessWidget {
  final RepliesModel reply;
  const _ReplyItem({required this.reply});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final replyTime = DateTime.tryParse(reply.timestamp) ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D1C),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {}, // Future: view reply details
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with custom frame
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      backgroundImage: const NetworkImage(
                        "https://i.pravatar.cc/150?u=reply",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text:
                                          "User ${reply.userId.length > 6 ? reply.userId.substring(0, 6) : reply.userId}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "  ·  ${timeago.format(replyTime)}",
                                      style: TextStyle(
                                        color: theme.hintColor.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.more_vert_rounded,
                              size: 16,
                              color: theme.hintColor.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reply.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            fontSize: 15,
                            color: colorScheme.onSurface.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Mini action bar for reply
                        Row(
                          children: [
                            _ReplyAction(
                              icon: Icons.favorite_border_rounded,
                              label: "Like",
                              onTap: () {},
                            ),
                            const SizedBox(width: 16),
                            _ReplyAction(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: "Reply",
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReplyAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 14, color: theme.hintColor.withValues(alpha: 0.6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassyReplyInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _GlassyReplyInput({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24 + bottomInset,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -10,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D1C).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                        ),
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Add your voice...",
                          hintStyle: TextStyle(
                            color: theme.hintColor.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _AnimatedSendButton(onTap: onSubmit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSendButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedSendButton({required this.onTap});

  @override
  State<_AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<_AnimatedSendButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF22C55E),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
