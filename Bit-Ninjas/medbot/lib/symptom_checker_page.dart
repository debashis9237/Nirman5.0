import 'package:flutter/material.dart';
import './patient_details_page.dart';

class SymptomCheckerPage extends StatefulWidget {
  const SymptomCheckerPage({super.key});

  @override
  State<SymptomCheckerPage> createState() => _SymptomCheckerPageState();
}

class _SymptomCheckerPageState extends State<SymptomCheckerPage> {
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Checker'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the previous screen (TreatmentPage)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'WELCOME',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Before using our application, please read carefully and accept our Terms and Services:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildTermItem(
                'Non-Diagnostic Nature: Informational checkup only, not a medical diagnosis. Seek professional advice for personalized guidance.'),
            _buildTermItem(
                'Not a Qualified Medical Opinion: It is essential to note that the checkup results do not replace a qualified medical opinion from a healthcare professional.'),
            _buildTermItem(
                'Anonymous Information: User information remains anonymous, and no data is stored on our servers.'),
            _buildTermItem(
                'Secondary Option: Consider it as supplementary; consult a healthcare professional for thorough evaluation.'),
            _buildTermItem(
                'Acknowledging Associated Risks: Understand the potential risks and use the checkup with caution in medical decision-making.'),
            const Spacer(), // Pushes content below to the bottom
            CheckboxListTile(
              title: const Text('I hereby agree to the Terms and Conditions'),
              value: _agreedToTerms,
              onChanged: (bool? value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                OutlinedButton(
                  onPressed: () {
                    // Navigate back to the previous screen (TreatmentPage)
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: _agreedToTerms
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PatientDetailsPage()),
                          );
                        }
                      : null, // Button is disabled if terms are not agreed to
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '• ',
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
