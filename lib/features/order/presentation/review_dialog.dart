import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ReviewResult {
  const ReviewResult(this.rating, this.comment);
  final int rating;
  final String? comment;
}

Future<ReviewResult?> showReviewDialog(
  BuildContext context, {
  int? initialRating,
  String? initialComment,
}) {
  return showDialog<ReviewResult>(
    context: context,
    builder: (_) => _ReviewDialog(
      initialRating: initialRating,
      initialComment: initialComment,
    ),
  );
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({this.initialRating, this.initialComment});

  final int? initialRating;
  final String? initialComment;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating = widget.initialRating ?? 0;
  late final _comment =
      TextEditingController(text: widget.initialComment ?? '');

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Beri ulasan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  onPressed: () => setState(() => _rating = i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 32,
                    color: const Color(0xFFFBBF24),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _comment,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Tulis pengalamanmu (opsional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _rating == 0
              ? null
              : () => Navigator.of(context).pop(
                    ReviewResult(_rating, _comment.text.trim()),
                  ),
          child: const Text('Kirim'),
        ),
      ],
    );
  }
}
