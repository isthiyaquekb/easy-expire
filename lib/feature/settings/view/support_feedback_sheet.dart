import 'package:easyexpire/feature/settings/viewmodel/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum FeedbackType { bug, feedback, feature }

class SupportFeedbackSheet extends StatefulWidget {
  final FeedbackType initialType;

  const SupportFeedbackSheet({
    super.key,
    this.initialType = FeedbackType.feedback,
  });

  static Future<void> show(
    BuildContext context, {
    FeedbackType type = FeedbackType.feedback,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SupportFeedbackSheet(initialType: type),
    );
  }

  @override
  State<SupportFeedbackSheet> createState() => _SupportFeedbackSheetState();
}

class _SupportFeedbackSheetState extends State<SupportFeedbackSheet> {
  late FeedbackType _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _sheetTitle {
    switch (_selectedType) {
      case FeedbackType.bug:
        return 'Report a Bug';
      case FeedbackType.feedback:
        return 'Share Feedback';
      case FeedbackType.feature:
        return 'Request a Feature';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _sheetTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type Segment Selector
            SegmentedButton<FeedbackType>(
              segments: const [
                ButtonSegment(
                  value: FeedbackType.bug,
                  label: Text('Bug'),
                  icon: Icon(Icons.bug_report_outlined),
                ),
                ButtonSegment(
                  value: FeedbackType.feedback,
                  label: Text('Feedback'),
                  icon: Icon(Icons.star_outline),
                ),
                ButtonSegment(
                  value: FeedbackType.feature,
                  label: Text('Feature'),
                  icon: Icon(Icons.lightbulb_outline),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<FeedbackType> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Rating Stars (if Feedback)
            if (_selectedType == FeedbackType.feedback) ...[
              Text(
                "How's your experience?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return IconButton(
                    icon: Icon(
                      starValue <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = starValue;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
            ],

            // Title Field
            TextField(
              controller: _titleController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText:
                    _selectedType == FeedbackType.bug
                        ? 'Issue Summary'
                        : (_selectedType == FeedbackType.feature
                            ? 'Feature Title'
                            : 'Subject'),
                hintText:
                    _selectedType == FeedbackType.bug
                        ? 'e.g., Expiry dates not saving properly'
                        : 'e.g., Great app / Need barcode generator',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description Field
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Details',
                hintText:
                    _selectedType == FeedbackType.bug
                        ? 'Describe what happened, steps to reproduce...'
                        : 'Tell us your thoughts or idea...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title or subject')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final vm = context.read<SettingsViewmodel>();
      await vm.submitFeedback(
        type: _selectedType.name,
        title: title,
        description: desc,
        rating: _selectedType == FeedbackType.feedback ? _rating : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Your feedback has been received.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    }
  }
}
