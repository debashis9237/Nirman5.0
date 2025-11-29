import 'package:flutter/material.dart';
import './chatbot_page.dart'; // Import the ChatbotPage
import './symptom_checker_page.dart'; // Import the Symptom Checker Page
import './medication_reminders_page.dart'; // Import the Medication Reminders Page

class TreatmentPage extends StatelessWidget {
  const TreatmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment Options'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button if it's a main tab
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Explore your treatment options or get quick help.",
            style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8)),
          ),
          const SizedBox(height: 20),
          _buildTreatmentOptionCard(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Chat with AI Doctor',
            subtitle: 'Get instant medical advice and answers.',
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ChatbotPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.ease;

                    final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    final offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300), // Adjust duration as needed
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTreatmentOptionCard(
            context,
            icon: Icons.medical_services_outlined,
            title: 'Symptom Checker',
            subtitle: 'Analyze your symptoms.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SymptomCheckerPage()), // Navigate to SymptomCheckerPage
              );
            },
          ),
          const SizedBox(height: 16),
          _buildTreatmentOptionCard(
            context,
            icon: Icons.playlist_add_check_outlined,
            title: 'View Treatment Plans',
            subtitle: 'Access your prescribed treatment plans.',
            onTap: () {
              // TODO: Navigate to Treatment Plans
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Treatment Plans (Not Implemented Yet)')),
              );
            },
          ),
          const SizedBox(height: 16),           _buildTreatmentOptionCard(
            context,
            icon: Icons.alarm_on_outlined,
            title: 'Medication Reminders',
            subtitle: 'Manage and get reminders for your medications.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedicationRemindersPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentOptionCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: Icon(icon, size: 30, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7))),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      ),
    );
  }
}
