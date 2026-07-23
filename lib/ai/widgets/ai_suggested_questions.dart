import 'package:flutter/material.dart';
import 'package:smartstitch/core/theme/app.theme.dart';

class AiSuggestedQuestions extends StatelessWidget {
  final List<String> questions;
  final void Function(String) onTap;

  const AiSuggestedQuestions({
    super.key,
    required this.questions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Suggested questions',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => onTap(questions[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary.withOpacity(0.05),
                ),
                child: Text(
                  questions[i],
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
