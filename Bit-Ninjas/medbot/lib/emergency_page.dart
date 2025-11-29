import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyPage extends StatelessWidget {
  EmergencyPage({super.key});

  // Emergency contact numbers (you can customize these based on your region)
  final List<Map<String, dynamic>> _emergencyContacts = [
    {
      'title': 'Emergency Services',
      'number': '911',
      'icon': Icons.local_hospital,
      'color': Colors.red,
      'description': 'Police, Fire, Medical Emergency'
    },
    {
      'title': 'Fire Department',
      'number': '119',
      'icon': Icons.local_fire_department,
      'color': Colors.orange,
      'description': 'Fire Emergency'
    },
    {
      'title': 'Police',
      'number': '110',
      'icon': Icons.local_police,
      'color': Colors.blue,
      'description': 'Police Emergency'
    },
    {
      'title': 'Ambulance',
      'number': '102',
      'icon': Icons.medical_services,
      'color': Colors.green,
      'description': 'Medical Emergency'
    },
    {
      'title': 'Poison Control',
      'number': '1-800-222-1222',
      'icon': Icons.medical_services,
      'color': Colors.purple,
      'description': 'Poison Emergency'
    },
    {
      'title': 'Crisis Hotline',
      'number': '988',
      'icon': Icons.support_agent,
      'color': Colors.teal,
      'description': 'Mental Health Crisis'
    },
  ];

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'SOS Alert',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'This will immediately call emergency services (911). Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _makePhoneCall('911');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Call 911'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [              // SOS Button
              Container(
                width: double.infinity,
                height: 100,
                margin: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  onPressed: () => _showSOSDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 8,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sos,
                        size: 40,
                        color: Colors.white,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'SOS Emergency',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),              // Emergency Instructions
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                margin: const EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Emergency Instructions',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1. Stay calm and assess the situation\n'
                      '2. Ensure your safety first\n'
                      '3. Call appropriate emergency services\n'
                      '4. Provide clear location and details\n'
                      '5. Follow dispatcher instructions',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),

              // Emergency Contacts Section
              Text(
                'Emergency Contacts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),              const SizedBox(height: 14),
              
              // Emergency Contacts Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _emergencyContacts.length,
                itemBuilder: (context, index) {
                  final contact = _emergencyContacts[index];
                  return _buildEmergencyCard(contact, theme);
                },
              ),

              const SizedBox(height: 20),              // Medical Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.medical_information,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Medical Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Keep your medical information handy:\n'
                      '• Current medications\n'
                      '• Known allergies\n'
                      '• Emergency contacts\n'
                      '• Medical conditions\n'
                      '• Insurance information',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // Added bottom padding to prevent overflow
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> contact, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () => _makePhoneCall(contact['number']),
        borderRadius: BorderRadius.circular(12.0),        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  color: (contact['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  contact['icon'],
                  size: 20,
                  color: contact['color'],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                contact['title'],
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                contact['number'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: contact['color'],
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                contact['description'],
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
