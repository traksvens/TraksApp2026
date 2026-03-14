import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:genui/genui.dart';

final incidentPostCardItem = CatalogItem(
  name: 'IncidentPostCard',
  dataSchema: S.object(
    properties: {
      'incidentType': S.string(),
      'content': S.string(),
      'severity': S.string(),
      'timestamp': S.string(),
      'address': S.string(),
      'imageUrl': S.string(),
      'confirmCount': S.integer(),
      'replyCount': S.integer(),
      'userName': S.string(),
      'userAvatarUrl': S.string(),
      'isAnonymous': S.boolean(),
    },
    required: ['incidentType', 'content', 'severity', 'timestamp', 'address'],
  ),
  widgetBuilder: (itemContext) {
    final data = Map<String, dynamic>.from(itemContext.data as Map);
    final theme = Theme.of(itemContext.buildContext);
    final severity = (data['severity'] as String? ?? 'medium').toLowerCase();
    final color = switch (severity) {
      'high' => const Color(0xFFD84315),
      'low' => const Color(0xFF2E7D32),
      _ => theme.colorScheme.primary,
    };

    DateTime? timestamp;
    final timestampString = data['timestamp'] as String?;
    if (timestampString != null && timestampString.isNotEmpty) {
      timestamp = DateTime.tryParse(timestampString);
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((data['imageUrl'] as String?)?.isNotEmpty ?? false)
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: data['imageUrl'] as String,
                        fit: BoxFit.cover,
                        placeholder: (context, _) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage:
                              (data['userAvatarUrl'] as String?)?.isNotEmpty ==
                                      true
                                  ? CachedNetworkImageProvider(
                                      data['userAvatarUrl'] as String)
                                  : null,
                          child: (data['userAvatarUrl'] as String?)?.isEmpty ??
                                  true
                              ? Icon(
                                  data['isAnonymous'] == true
                                      ? Icons.visibility_off_rounded
                                      : Icons.person_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['userName'] as String? ?? 'User',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (timestamp != null)
                                Text(
                                  timeago.format(timestamp),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: color.withValues(alpha: 0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (data['incidentType'] as String? ?? 'Incident')
                          .toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.hintColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['content'] as String? ?? '',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['address'] as String? ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _MetaIndicator(
                          icon: Icons.verified_rounded,
                          count: data['confirmCount'] as int? ?? 0,
                          label: 'Verifications',
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 24),
                        _MetaIndicator(
                          icon: Icons.forum_rounded,
                          count: data['replyCount'] as int? ?? 0,
                          label: 'Replies',
                          color: theme.colorScheme.primary,
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
    );
  },
);

class _MetaIndicator extends StatelessWidget {
  const _MetaIndicator({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
