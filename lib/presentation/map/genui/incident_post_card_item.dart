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
      _ => const Color(0xFFEF6C00),
    };

    DateTime? timestamp;
    final timestampString = data['timestamp'] as String?;
    if (timestampString != null && timestampString.isNotEmpty) {
      timestamp = DateTime.tryParse(timestampString);
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (data['incidentType'] as String? ?? 'Incident')
                            .toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        timeago.format(timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['content'] as String? ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['address'] as String? ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((data['imageUrl'] as String?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
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
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetaChip(
                      icon: Icons.verified_rounded,
                      label:
                          '${data['confirmCount'] as int? ?? 0} confirmations',
                    ),
                    _MetaChip(
                      icon: Icons.forum_rounded,
                      label: '${data['replyCount'] as int? ?? 0} replies',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
