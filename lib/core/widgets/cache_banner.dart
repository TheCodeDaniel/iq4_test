import 'package:flutter/material.dart';

class CacheBanner extends StatelessWidget {
  final VoidCallback onRefresh;

  const CacheBanner({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: theme.colorScheme.secondaryContainer,
      child: Row(
        children: [
          Icon(Icons.offline_bolt_outlined, size: 16, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached data',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Text(
              'Refresh',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
