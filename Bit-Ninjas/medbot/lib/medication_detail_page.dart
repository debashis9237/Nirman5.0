import 'package:flutter/material.dart';

class MedicationDetailPage extends StatelessWidget {
  final String diseaseName;
  final String symptomDurationDays;
  final String medicationAdvice;

  const MedicationDetailPage({
    Key? key,
    required this.diseaseName,
    required this.symptomDurationDays,
    required this.medicationAdvice,
  }) : super(key: key);

  Widget _buildRichText(String text, TextStyle? style, BuildContext context) {
    List<TextSpan> spans = [];
    // Regex to find **bold** and @@red@@ text. It captures the markers and content.
    // Group 1: Bold marker with content (e.g., **text**)
    // Group 2: Content within bold markers (e.g., text)
    // Group 3: Red marker with content (e.g., @@text@@)
    // Group 4: Content within red markers (e.g., text)
    RegExp combinedPattern = RegExp(r'(\*\*(.*?)\*\*)|(@@(.*?)@@)');
    int currentPosition = 0;

    for (Match match in combinedPattern.allMatches(text)) {
      // Add text before the current match
      if (match.start > currentPosition) {
        spans.add(TextSpan(text: text.substring(currentPosition, match.start), style: style));
      }

      // Check if it's a bold match (group 2 will have content)
      if (match.group(1) != null && match.group(2) != null) {
        spans.add(TextSpan(text: match.group(2)!, style: style?.copyWith(fontWeight: FontWeight.bold)));
      }
      // Check if it's a red match (group 4 will have content)
      else if (match.group(3) != null && match.group(4) != null) {
        spans.add(TextSpan(text: match.group(4)!, style: style?.copyWith(color: Colors.red, fontWeight: FontWeight.bold))); // Red and bold for emphasis
      }
      currentPosition = match.end;
    }

    // Add any remaining text after the last match
    if (currentPosition < text.length) {
      spans.add(TextSpan(text: text.substring(currentPosition), style: style));
    }
    
    // Fallback if no markers were found but text exists
    if (spans.isEmpty && text.isNotEmpty) {
         spans.add(TextSpan(text: text, style: style));
    }

    return RichText(text: TextSpan(children: spans)); // Removed redundant style here as it's applied to spans
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(diseaseName),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
        iconTheme: IconThemeData(color: theme.brightness == Brightness.dark ? Colors.white : Colors.black),
        titleTextStyle: theme.textTheme.titleLarge,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Medication for $diseaseName',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Based on symptoms lasting $symptomDurationDays days:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Recommended Advice:',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildRichText(medicationAdvice, theme.textTheme.bodyLarge, context),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
