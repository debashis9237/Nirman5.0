import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // Added for CSV loading
import 'package:pocketdoctor/disease_prediction_page.dart'; // Added for navigation

class SymptomsPage extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const SymptomsPage({super.key, required this.patientData});

  @override
  State<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allSymptoms = []; // Initialize as empty, will be loaded from CSV
  List<String> _filteredSymptoms = [];
  final List<String> _selectedSymptoms = [];
  bool _isLoadingSymptoms = true; // Added for loading state

  @override
  void initState() {
    super.initState();
    _loadSymptoms(); // Load symptoms from CSV
    _searchController.addListener(() {
      _filterSymptoms();
    });
  }

  Future<void> _loadSymptoms() async {
    try {
      final String csvData = await rootBundle.loadString('assets/dis-sym-processed-categorical.csv');
      final List<String> lines = csvData.split('\n');

      if (lines.isNotEmpty) {
        final String headerLine = lines.first.trim();
        List<String> headers = headerLine.split(',');
        List<String> symptoms = [];

        if (headers.isNotEmpty) {
          // Try to identify and skip a potential 'disease' or 'prognosis' column (case-insensitive)
          String firstHeader = headers.first.trim().toLowerCase();
          int startIndex = 0;
          if (firstHeader == 'disease' || firstHeader == 'prognosis' || firstHeader.contains('disease name')) {
            startIndex = 1;
          }

          symptoms = headers
              .sublist(startIndex)
              .map((header) {
                // Clean up symptom names: replace underscores, remove extra quotes, trim
                return header
                    .trim()
                    .replaceAll('_', ' ')
                    .replaceAll('"', '') // Remove double quotes
                    .replaceAll('\'', ''); // Remove single quotes
              })
              .where((symptom) => symptom.isNotEmpty) // Filter out any empty strings
              .toList();
        }
        // Remove duplicates and sort
        _allSymptoms = symptoms.toSet().toList()..sort();
      }
    } catch (e) {
      print('Error loading or parsing symptoms CSV: $e');
      // Fallback or error display
      _allSymptoms = ['Error: Could not load symptoms'];
    }

    setState(() {
      _filteredSymptoms = _allSymptoms;
      _isLoadingSymptoms = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSymptoms() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSymptoms = _allSymptoms.where((symptom) {
        return symptom.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _onSymptomSelected(String symptom) {
    setState(() {
      if (_selectedSymptoms.contains(symptom)) {
        _selectedSymptoms.remove(symptom);
      } else {
        _selectedSymptoms.add(symptom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool canProceed = _selectedSymptoms.length >= 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Symptoms'),
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
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
            // Header Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTab('Patient', isActive: false, context: context),
                _buildTab('Symptoms', isActive: true, context: context),
                _buildTab('Disease', isActive: false, context: context),
                _buildTab('Medication', isActive: false, context: context),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Symptoms',
                hintText: 'E.g., Fever, Headache',
                prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Selected Symptoms Display
            if (_selectedSymptoms.isNotEmpty)
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _selectedSymptoms.map((symptom) => Chip(
                  label: Text(symptom, style: TextStyle(color: theme.colorScheme.onPrimary)),
                  backgroundColor: theme.colorScheme.primary,
                  deleteIconColor: theme.colorScheme.onPrimary,
                  onDeleted: () => _onSymptomSelected(symptom),
                )).toList(),
              ),
            if (_selectedSymptoms.isNotEmpty) const SizedBox(height: 12),
            
            // Instructional Text
            if (_selectedSymptoms.length < 3)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '* Select at least 3 symptoms for better results',
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
                ),
              ),

            // Symptoms List
            Expanded(
              child: _isLoadingSymptoms
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSymptoms.isEmpty && _searchController.text.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'No symptoms found for "${_searchController.text}".',
                                style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add_circle_outline),
                                label: Text('Add "${_searchController.text}" as symptom'),
                                onPressed: () {
                                  final customSymptom = _searchController.text.trim();
                                  if (customSymptom.isNotEmpty && !_selectedSymptoms.contains(customSymptom)) {
                                    setState(() {
                                      _selectedSymptoms.add(customSymptom);
                                      // Optionally add to _allSymptoms and _filteredSymptoms if you want it to appear in the list
                                      // _allSymptoms.add(customSymptom);
                                      // _allSymptoms.sort(); // Keep it sorted if adding
                                      _searchController.clear(); // Clear search bar
                                      _filterSymptoms(); // Refresh the list (will be empty if not added to _allSymptoms)
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.secondary,
                                  foregroundColor: theme.colorScheme.onSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredSymptoms.length,
                          itemBuilder: (context, index) {
                            final symptom = _filteredSymptoms[index];
                            final isSelected = _selectedSymptoms.contains(symptom);
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                title: Text(symptom, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                trailing: Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    _onSymptomSelected(symptom);
                                  },
                                  activeColor: theme.colorScheme.primary,
                                ),
                                onTap: () => _onSymptomSelected(symptom),
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),

            // Bottom Navigation Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                OutlinedButton.icon(
                  icon: const Icon(Icons.arrow_back_ios_new),
                  label: const Text('Back'),
                  onPressed: () {
                    Navigator.pop(context); // Go back to PatientDetailsPage
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.online_prediction), // Changed icon
                  label: const Text('Predict'), // Changed text
                  onPressed: canProceed
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiseasePredictionPage(
                                symptoms: _selectedSymptoms,
                                patientData: widget.patientData, // Pass patientData
                              ),
                            ),
                          );
                        }
                      : null, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.12),
                    foregroundColor: canProceed ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface.withOpacity(0.38),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, {required bool isActive, required BuildContext context}) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
      ),
    );
  }
}
