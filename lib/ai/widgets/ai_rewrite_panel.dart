import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class AiRewritePanel extends StatelessWidget {
  final String originalText;
  final void Function(String style) onRewrite;
  final VoidCallback onClose;

  const AiRewritePanel({
    super.key,
    required this.originalText,
    required this.onRewrite,
    required this.onClose,
  });

  static const _styles = [
    ('Professional', Icons.business_center_rounded, 'professional'),
    ('Friendly', Icons.emoji_emotions_rounded, 'friendly'),
    ('Formal', Icons.account_balance_rounded, 'formal'),
    ('Polite', Icons.favorite_rounded, 'polite'),
    ('Short', Icons.compress_rounded, 'short and concise'),
    ('Longer', Icons.expand_rounded, 'more detailed and elaborate'),
    ('Fix Grammar', Icons.spellcheck_rounded, 'grammatically correct'),
    ('Translate Urdu', Icons.translate_rounded, 'translated to Urdu'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Rewrite / Transform',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '"${originalText.length > 60 ? '${originalText.substring(0, 57)}...' : originalText}"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _styles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, icon, style) = _styles[i];
                return ActionChip(
                  avatar: Icon(icon, size: 16, color: AppColors.primary),
                  label: Text(label,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  backgroundColor: AppColors.primary.withOpacity(0.07),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  onPressed: () => onRewrite(style),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
