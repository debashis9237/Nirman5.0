import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart'; // Added import for CSV parsing
import 'medication_page.dart'; // Import the new medication page

// Placeholder for a Precautions Page
class PrecautionsPage extends StatelessWidget {
  final String diseaseName;
  final List<String> precautions; // Added to receive precautions

  const PrecautionsPage({
    Key? key,
    required this.diseaseName,
    required this.precautions, // Added
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Precautions for $diseaseName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: precautions.isEmpty
            ? Center(
                child: Text('No specific precautions listed for $diseaseName.'))
            : ListView.builder(
                itemCount: precautions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(precautions[index]),
                  );
                },
              ),
      ),
    );
  }
}

class DiseasePredictionPage extends StatefulWidget {
  final List<String> symptoms;
  final Map<String, dynamic> patientData; // Add patientData field

  const DiseasePredictionPage({
    Key? key,
    required this.symptoms,
    required this.patientData, // Add to constructor
  }) : super(key: key);

  @override
  _DiseasePredictionPageState createState() => _DiseasePredictionPageState();
}

class _DiseasePredictionPageState extends State<DiseasePredictionPage> {
  List<Map<String, dynamic>> _predictions = [];
  final double _threshold = 0.3; // Example threshold
  bool _isLoading = true; // For loading CSV and predictions

  // IMPORTANT: Replace with your actual API Key if the one below is a placeholder
  static const String _apiKey = "AIzaSyCMOVqzMDw53FWNTIx8QJ9Ahk27rJ3vHJg";

  List<List<dynamic>> _symptomCsvData = [];
  List<String> _symptomHeaders = [];

  Map<String, List<String>> _diseasePrecautionsMap = {};
  Map<String, String> _diseaseSpecialistsMap = {};
  Map<String, String> _diseaseDescriptionsMap = {}; // For AI prompt later

  // Keeping Wikipedia URLs separate as they are not in the provided CSVs
  final Map<String, String> _wikipediaUrls = {
    'Fungal infection': 'https://en.wikipedia.org/wiki/Fungal_infection',
    'Allergy': 'https://en.wikipedia.org/wiki/Allergy',
    'Common Cold': 'https://en.wikipedia.org/wiki/Common_cold',
    'Pneumonia': 'https://en.wikipedia.org/wiki/Pneumonia',
    'Diabetes': 'https://en.wikipedia.org/wiki/Diabetes',
    'Hypertension': 'https://en.wikipedia.org/wiki/Hypertension',
    'Migraine': 'https://en.wikipedia.org/wiki/Migraine',
    'Bronchial Asthma': 'https://en.wikipedia.org/wiki/Asthma',
    'Chicken pox': 'https://en.wikipedia.org/wiki/Chickenpox',
    'Dengue': 'https://en.wikipedia.org/wiki/Dengue_fever',
    'Typhoid': 'https://en.wikipedia.org/wiki/Typhoid_fever',
    'Malaria': 'https://en.wikipedia.org/wiki/Malaria',
    'Tuberculosis': 'https://en.wikipedia.org/wiki/Tuberculosis',
    'Gastroenteritis': 'https://en.wikipedia.org/wiki/Gastroenteritis',
    'Urinary tract infection':
        'https://en.wikipedia.org/wiki/Urinary_tract_infection',
    // Add more known URLs if needed
  };

  @override
  void initState() {
    super.initState();
    _loadDataAndPredict();
  }

  Future<List<List<dynamic>>> _loadCsv(String path) async {
    try {
      final String csvString = await rootBundle.loadString(path);
      return const CsvToListConverter().convert(csvString);
    } catch (e) {
      print('Error loading CSV $path: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error loading data file: ${path.split('/').last}')),
        );
      }
      return [];
    }
  }

  Future<void> _loadDataAndPredict() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    // Access patientData using widget.patientData
    // Example: print("Patient Data in DiseasePredictionPage: ${widget.patientData}");

    _symptomCsvData =
        await _loadCsv('assets/dis-sym-processed-categorical.csv');

    final precautionData = await _loadCsv('assets/disease_precaution.csv');
    if (precautionData.length > 1) {
      for (var i = 1; i < precautionData.length; i++) {
        // Skip header
        final row = precautionData[i];
        if (row.isNotEmpty && row[0] != null) {
          String diseaseName = row[0].toString().trim();
          List<String> precautions = [];
          for (var j = 1; j < row.length; j++) {
            if (row[j] != null && row[j].toString().trim().isNotEmpty) {
              precautions.add(row[j].toString().trim());
            }
          }
          _diseasePrecautionsMap[diseaseName] = precautions;
        }
      }
    }

    final specialistData = await _loadCsv('assets/Doctor_Versus_Disease.csv');
    if (specialistData.length > 1) {
      for (var i = 1; i < specialistData.length; i++) {
        // Skip header
        final row = specialistData[i];
        if (row.length > 1 && row[0] != null && row[1] != null) {
          _diseaseSpecialistsMap[row[0].toString().trim()] =
              row[1].toString().trim();
        }
      }
    }

    final descriptionData = await _loadCsv('assets/disease_description.csv');
    if (descriptionData.length > 1) {
      for (var i = 1; i < descriptionData.length; i++) {
        // Skip header
        final row = descriptionData[i];
        if (row.length > 1 && row[0] != null && row[1] != null) {
          _diseaseDescriptionsMap[row[0].toString().trim()] =
              row[1].toString().trim();
        }
      }
    }

    List<Map<String, dynamic>> csvPredictions = [];
    if (_symptomCsvData.isNotEmpty) {
      _symptomHeaders = _symptomCsvData.first
          .map((e) => e.toString().trim().replaceAll('_', ' '))
          .toList();
      csvPredictions = _generatePredictionsFromCsv();
    } else {
      csvPredictions = [
        {
          'name': 'Error',
          'chance': 0.0,
          'wikipediaUrl': '',
          'specialist': 'N/A',
          'precautions': ['Could not load critical symptom data.'],
          'description': ''
        }
      ];
    }

    if (_apiKey == "YOUR_API_KEY") {
      print("API Key not set. Skipping AI enhancement.");
      if (mounted) {
        setState(() {
          _predictions = csvPredictions.isNotEmpty
              ? csvPredictions
              : [
                  {
                    'name': 'No specific match found',
                    'chance': 0.0,
                    'wikipediaUrl': '',
                    'specialist': 'N/A',
                    'precautions': ['Please consult a doctor.'],
                    'description': ''
                  }
                ];
          _isLoading = false;
        });
      }
    } else {
      try {
        final aiEnhancedPredictions =
            await _getAiEnhancedPredictions(csvPredictions, widget.symptoms);
        // ADDED: Log what is received from _getAiEnhancedPredictions
        print(
            "DEBUG: _loadDataAndPredict: aiEnhancedPredictions received: ${aiEnhancedPredictions.map((p) => p['name']).toList()}");

        if (mounted) {
          setState(() {
            // ADDED: Log inside setState
            print(
                "DEBUG: setState: aiEnhancedPredictions.isNotEmpty = ${aiEnhancedPredictions.isNotEmpty}");
            if (aiEnhancedPredictions.isNotEmpty) {
              _predictions = aiEnhancedPredictions;
              print(
                  "DEBUG: setState: _predictions set to AI. Count: ${_predictions.length}. Names: ${_predictions.map((p) => p['name']).toList()}");
            } else if (csvPredictions.isNotEmpty) {
              _predictions = csvPredictions;
              print(
                  "DEBUG: setState: _predictions set to CSV. Count: ${_predictions.length}. Names: ${_predictions.map((p) => p['name']).toList()}");
            } else {
              _predictions = [
                {
                  'name': 'No specific match found',
                  'chance': 0.0,
                  'wikipediaUrl': '',
                  'specialist': 'N/A',
                  'precautions': ['Please consult a doctor.'],
                  'description': ''
                }
              ];
              print(
                  "DEBUG: setState: _predictions set to 'No specific match found'.");
            }
            _isLoading = false;
            print("DEBUG: setState: _isLoading = false.");
          });
        } else {
          // ADDED: Log if not mounted
          print(
              "DEBUG: _loadDataAndPredict: Component not mounted, setState skipped.");
        }
      } catch (e) {
        print("Error during AI prediction: $e");
        if (mounted) {
          setState(() {
            _predictions = csvPredictions.isNotEmpty
                ? csvPredictions // Fallback to CSV on AI error
                : [
                    {
                      'name': 'Error during AI prediction',
                      'chance': 0.0,
                      'wikipediaUrl': '',
                      'specialist': 'N/A',
                      'precautions': [
                        'Could not get AI enhanced results. Showing initial findings.'
                      ],
                      'description': ''
                    }
                  ];
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getAiEnhancedPredictions(
      List<Map<String, dynamic>> csvBasedPredictions,
      List<String> symptoms) async {
    if (_apiKey == "YOUR_API_KEY") {
      print("AI API Key is not configured. Returning CSV based predictions.");
      return csvBasedPredictions;
    }

    final model =
        GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: _apiKey);

    String symptomsString = symptoms.join(", ");
    String csvDiseasesString = "";

    // Prepare patient data string for the prompt
    String patientDataString = '';
    if (widget.patientData.isNotEmpty) {
      patientDataString = 'Patient Details: ';
      widget.patientData.forEach((key, value) {
        patientDataString += '$key: $value, ';
      });
      // Remove trailing comma and space
      patientDataString =
          patientDataString.substring(0, patientDataString.length - 2);
      patientDataString += '.\\n'; // Add a period and newline
    }

    // Take top 3-5 CSV predictions to feed to AI
    int count = 0;
    for (var pred in csvBasedPredictions) {
      if (count < 5 &&
          pred['name'] != 'Error' &&
          pred['name'] != 'Data Error' &&
          pred['name'] != 'No specific match found') {
        String diseaseName = pred['name'];
        // Ensure a fallback description if none is available from CSV
        String description = _diseaseDescriptionsMap[diseaseName] ??
            "A medical condition requiring further investigation.";
        csvDiseasesString += "- ${diseaseName}: ${description}\\\\n";
        count++;
      }
    }
    if (csvDiseasesString.isEmpty &&
        csvBasedPredictions.isNotEmpty &&
        csvBasedPredictions.first['name'] != 'Error' &&
        csvBasedPredictions.first['name'] != 'Data Error') {
      // Fallback if all csv predictions were filtered out but some existed
      String diseaseName = csvBasedPredictions.first['name'];
      String description = _diseaseDescriptionsMap[diseaseName] ??
          "A medical condition requiring further investigation.";
      csvDiseasesString = "- ${diseaseName}: ${description}\\\\n";
    }

    final prompt = '''
Based on the following symptoms: ${symptomsString}.
${patientDataString} // Include patient data in the prompt
Our initial analysis suggests these possible diseases with their descriptions:
${csvDiseasesString.isNotEmpty ? csvDiseasesString : "No initial candidates from CSV analysis, please predict based on symptoms alone."}
Please act as a medical expert. Refine this list or provide new predictions.
For each disease you predict, you MUST provide all of the following fields, each on a new line:
DiseaseName: [Name of the disease]
Chance: [XX]% (If very low, state a low percentage like 1% or 5%)
Description: [Concise medical description. If information is insufficient for a confident diagnosis, explain limitations here.]
DetailedPrecautions: [Detailed precautions as a paragraph or hyphenated list. If not applicable or unknown, state \"General wellness advice recommended due to non-specific symptoms.\"]
SuggestedMedicalTests: [Suggested tests as a paragraph or hyphenated list. If none specific, state \"Consult a doctor for test recommendations based on a full examination.\"]
MedicationAdvice: [General medication advice. If symptoms are non-specific, state \"Consult a doctor for any medication and to rule out serious conditions.\"]
--- (use three hyphens as a separator between diseases)
List the most relevant diseases based on your confidence, ordered from most to least likely.
IMPORTANT: ALWAYS provide your assessment in the structured format above for each potential condition, even if confidence is very low or symptoms are vague. Do NOT just state 'Insufficient information' as a general response; instead, incorporate uncertainty into the 'Description' or other relevant fields of the structured output for each considered disease.
''';

    print("AI Prompt: $prompt"); // For debugging

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      print("AI Response: ${response.text}"); // For debugging

      if (response.text == null || response.text!.trim().isEmpty) {
        print("AI response is null or empty.");
        return [];
      }

      String parsableText = response.text!;
      final diseaseNameKey = "DiseaseName:";
      int startIndex = parsableText.indexOf(diseaseNameKey);

      if (startIndex == -1) {
        print(
            "AI response does not contain the start key '$diseaseNameKey'. Full response: ${response.text}");
        // Check for insufficient information message even if key is missing
        if (response.text!
                .trim()
                .toLowerCase()
                .contains("insufficient information") &&
            response.text!.trim().length < 150) {
          print("AI response considered insufficient.");
          return [];
        }
        // If no key and not clearly insufficient, it might be a malformed positive response or a different kind of message.
        // Depending on strictness, you might return [] or try a more lenient parse if applicable.
        // For now, returning empty if the primary key is missing.
        return [];
      }

      parsableText = parsableText.substring(startIndex);

      // Added length check for short insufficient info messages AFTER trying to find the key
      if (parsableText
              .trim()
              .toLowerCase()
              .contains("insufficient information") &&
          parsableText.trim().length < 100 &&
          !parsableText.trim().startsWith(diseaseNameKey)) {
        print(
            "AI response (after substring) considered insufficient or empty.");
        return [];
      }

      List<Map<String, dynamic>> aiPredictions = [];
      // Corrected: Split by '---' as per prompt, then trim each block.
      final diseaseBlocks = parsableText.trim().split('---');

      for (var rawBlock in diseaseBlocks) {
        final block = rawBlock.trim();
        if (block.isEmpty) continue;

        print("DEBUG PARSING BLOCK --- START ---");
        print(
            "Original Block (first 150 chars): ${block.substring(0, (block.length > 150 ? 150 : block.length))}");

        String? diseaseName;
        double? chance;
        String? description;
        String? detailedPrecautions;
        String? suggestedMedicalTests;
        String? medicationAdvice;

        // Corrected to split by actual newline characters.
        final lines = block.split('\n');
        print(
            "Number of lines found by block.split(\\'\\n\\'): ${lines.length}");
        if (lines.length == 1 &&
            block.isNotEmpty &&
            block.contains("DiseaseName:")) {
          print(
              "WARNING: Only one line found by block.split(\\'\\n\\'). Block content (first 150 chars): '${block.substring(0, (block.length > 150 ? 150 : block.length))}'");
          print(
              "Attempting to split the single line by literal \'\\\\n\' (backslash followed by n) as a fallback for debugging...");
          final linesFallback = block.split(
              '\\\\n'); // This splits by the literal string "\\n" (i.e., a backslash char followed by an 'n' char)
          if (linesFallback.length > 1) {
            print(
                "Fallback split by literal \'\\\\n\' found ${linesFallback.length} lines. This might indicate the AI response contains literal \'\\\\n\' strings instead of actual newlines in this block.");
          } else {
            print(
                "Fallback split by literal \'\\\\n\' also found 1 line. The issue is likely not mixed literal/actual newlines in this specific block, or the block is truly a single line of text from AI.");
          }
        }

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim(); // Trim each line
          if (line.isEmpty) continue;

          print("  Processing line ${i + 1}/${lines.length}: '$line'");

          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            // Reconstruct value more safely in case value contains ':'
            final value = line.substring(key.length + 1).trim();
            print("    Extracted Key: '$key', Extracted Value: '$value'");

            switch (key) {
              case 'DiseaseName':
                diseaseName = value;
                print("      Matched 'DiseaseName'");
                break;
              case 'Chance':
                String chanceString = value.replaceAll('%', '').trim();
                chance = double.tryParse(chanceString);
                print(
                    "      Matched 'Chance'. Input to tryParse: '$chanceString', Parsed value: $chance");
                break;
              case 'Description':
                description = value;
                print("      Matched 'Description'");
                break;
              case 'DetailedPrecautions':
                detailedPrecautions = value;
                print("      Matched 'DetailedPrecautions'");
                break;
              case 'SuggestedMedicalTests':
                suggestedMedicalTests = value;
                print("      Matched 'SuggestedMedicalTests'");
                break;
              case 'MedicationAdvice':
                medicationAdvice = value;
                print("      Matched 'MedicationAdvice'");
                break;
              default:
                print("      WARN: Unmatched key: '$key'");
            }
          } else {
            print(
                "    WARN: Line did not split into >= 2 parts using ':' : '$line'");
          }
        }
        print(
            "Values before adding to aiPredictions list: diseaseName=$diseaseName, chance=$chance, description=$description, detailedPrecautions=$detailedPrecautions, suggestedMedicalTests=$suggestedMedicalTests, medicationAdvice=$medicationAdvice");
        print("DEBUG PARSING BLOCK --- END ---");

        // Enhanced Debugging for specific block
        if (diseaseName != null &&
            diseaseName.toLowerCase().contains("diabetes")) {
          print("DEBUG PARSING DIABETES BLOCK (or similar):");
          print(
              "  Raw Block Snippet: ${block.substring(0, (block.length > 100 ? 100 : block.length))}"); // Print first 100 chars
          print("  Extracted diseaseName: $diseaseName");
          print("  Extracted chance: $chance");
          print("  Extracted description: $description");
          print("  Extracted detailedPrecautions: $detailedPrecautions");
          print("  Extracted suggestedMedicalTests: $suggestedMedicalTests");
          print("  Extracted medicationAdvice: $medicationAdvice");
        }

        if (diseaseName != null && chance != null && description != null) {
          String diseaseNameTrimmed = diseaseName.trim();

          // Use AI description directly.
          String finalDescription = description.isNotEmpty
              ? description
              : _diseaseDescriptionsMap[diseaseNameTrimmed] ??
                  _diseaseDescriptionsMap.entries
                      .firstWhere(
                          (entry) =>
                              entry.key.toLowerCase() ==
                              diseaseNameTrimmed.toLowerCase(),
                          orElse: () => MapEntry(diseaseNameTrimmed,
                              'No detailed description available.'))
                      .value;
          if (finalDescription.isEmpty ||
              finalDescription == 'No detailed description available.') {
            finalDescription = description.isNotEmpty
                ? description
                : "Consult a healthcare professional for more details.";
          }

          String? urlFromMap = _wikipediaUrls[diseaseNameTrimmed];
          if (urlFromMap == null || urlFromMap.isEmpty) {
            final lowerCaseKey = diseaseNameTrimmed.toLowerCase();
            for (var entry in _wikipediaUrls.entries) {
              if (entry.key.toLowerCase() == lowerCaseKey) {
                urlFromMap = entry.value;
                break;
              }
            }
          }
          String wikipediaUrl = (urlFromMap != null && urlFromMap.isNotEmpty)
              ? urlFromMap
              : 'https://en.wikipedia.org/w/index.php?search=${Uri.encodeComponent(diseaseNameTrimmed)}';

          String specialist = _diseaseSpecialistsMap[diseaseNameTrimmed] ??
              _diseaseSpecialistsMap.entries
                  .firstWhere(
                      (entry) =>
                          entry.key.toLowerCase() ==
                          diseaseNameTrimmed.toLowerCase(),
                      orElse: () =>
                          MapEntry(diseaseNameTrimmed, 'General Physician'))
                  .value;

          // Use AI precautions if available, otherwise fallback to CSV (though prompt asks AI for detailed ones)
          List<String> finalPrecautions = [];
          if (detailedPrecautions != null &&
              detailedPrecautions.isNotEmpty &&
              detailedPrecautions.toLowerCase() != "none") {
            finalPrecautions = detailedPrecautions.startsWith('- ')
                ? detailedPrecautions
                    .split('\n- ')
                    .map((e) => e.replaceFirst('- ', '').trim())
                    .where((e) => e.isNotEmpty)
                    .toList() // Corrected this line
                : [
                    detailedPrecautions.trim()
                  ]; // Added trim here for consistency
          } else {
            finalPrecautions = _diseasePrecautionsMap[diseaseNameTrimmed] ??
                _diseasePrecautionsMap.entries
                    .firstWhere(
                        (entry) =>
                            entry.key.toLowerCase() ==
                            diseaseNameTrimmed.toLowerCase(),
                        orElse: () => MapEntry(diseaseNameTrimmed, <String>[]))
                    .value;
          }

          aiPredictions.add({
            'name': diseaseNameTrimmed,
            'chance': chance / 100.0, // Convert percentage to 0.0-1.0 scale
            'wikipediaUrl': wikipediaUrl,
            'specialist': specialist,
            'precautions':
                finalPrecautions, // This will now be primarily from AI if provided
            'description': finalDescription,
            'detailedPrecautions':
                detailedPrecautions ?? "Not specified by AI.",
            'suggestedMedicalTests':
                suggestedMedicalTests ?? "Not specified by AI.",
            'medicationAdvice':
                medicationAdvice ?? "Consult a doctor for medication advice.",
          });
          if (diseaseNameTrimmed.toLowerCase().contains("diabetes")) {
            print("  SUCCESSFULLY ADDED DIABETES BLOCK TO aiPredictions.");
          }
        } else {
          print("Could not add AI prediction block to list. Details:");
          // Only print detailed block if it's potentially the one we're interested in or if few blocks
          if (block.toLowerCase().contains("diabetes") ||
              diseaseBlocks.length < 3) {
            print(
                "  Block content snippet: ${block.substring(0, (block.length > 150 ? 150 : block.length))}");
          } else {
            print(
                "  (Skipping full block content for brevity as it doesn't seem to be the primary target and there are many blocks)");
          }
          print("  Extracted diseaseName: $diseaseName");
          print("  Extracted chance: $chance");
          print("  Extracted description: $description");
          if (block.toLowerCase().contains("diabetes")) {
            print(
                "  ^^^ THIS WAS THE DIABETES (or similar) BLOCK THAT FAILED THE NULL CHECK FOR ESSENTIALS ^^^");
          }
        }
      }
      aiPredictions.sort(
          (a, b) => (b['chance'] as double).compareTo(a['chance'] as double));

      // Diagnostic print for parsed AI predictions
      print(
          "Parsed AI Predictions: ${aiPredictions.map((p) => p['name']).toList()}"); // Log just names to keep it shorter
      for (var p in aiPredictions) {
        print(
            "Details for ${p['name']}: Description - ${p['description']?.substring(0, (p['description']?.length ?? 0) > 50 ? 50 : p['description']?.length ?? 0)}, Precautions - ${p['detailedPrecautions']?.substring(0, (p['detailedPrecautions']?.length ?? 0) > 50 ? 50 : p['detailedPrecautions']?.length ?? 0)}, Tests - ${p['suggestedMedicalTests']?.substring(0, (p['suggestedMedicalTests']?.length ?? 0) > 50 ? 50 : p['suggestedMedicalTests']?.length ?? 0)}, Advice - ${p['medicationAdvice']?.substring(0, (p['medicationAdvice']?.length ?? 0) > 50 ? 50 : p['medicationAdvice']?.length ?? 0)}");
      }

      return aiPredictions.isNotEmpty ? aiPredictions : [];
    } catch (e) {
      print("Error calling Generative AI or parsing response: $e");
      return [];
    }
  }

  // Method to get disease description, tests, and recommendations from AI
  Future<Map<String, String>> _getAiDiseaseDescription(
      String diseaseName) async {
    if (_apiKey == "YOUR_API_KEY") {
      print("AI API Key is not configured correctly for disease details.");
      return {
        "Description": "API key not configured. Cannot fetch details.",
        "SuggestedMedicalTests": "N/A",
        "Recommendations": "N/A",
      };
    }
    final model =
        GenerativeModel(model: 'gemini-2.0-flash-exp', apiKey: _apiKey);
    final prompt =
        '''For the disease "$diseaseName", provide a brief medical description, a list of suggested medical tests (e.g., "Blood test, X-ray"), and brief patient recommendations (e.g., "Rest, Hydrate, Follow-up with doctor"). Format the output strictly as follows, with each item on a new line:
Description: [Your description here]
SuggestedMedicalTests: [Test1, Test2, ... or a sentence describing tests]
Recommendations: [Your recommendations here]''';

    print("AI Info Prompt for $diseaseName: $prompt"); // For debugging

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final text = response.text;

      print("AI Info Response for $diseaseName: $text"); // For debugging

      if (text == null || text.trim().isEmpty) {
        return {
          "Description": "AI response was empty.",
          "SuggestedMedicalTests": "N/A",
          "Recommendations": "N/A",
        };
      }

      final lines = text.trim().split('\\n'); // Split by newline
      String description = "No description provided by AI.";
      String tests = "Not specified by AI.";
      String recommendations = "Not specified by AI.";

      for (var line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          switch (key) {
            case 'Description':
              description = value;
              break;
            case 'SuggestedMedicalTests':
              tests = value;
              break;
            case 'Recommendations':
              recommendations = value;
              break;
          }
        }
      }
      return {
        "Description": description,
        "SuggestedMedicalTests": tests,
        "Recommendations": recommendations,
      };
    } catch (e) {
      print("Error fetching AI disease details for $diseaseName: $e");
      return {
        "Description": "Error fetching details. Please try again.",
        "SuggestedMedicalTests": "Error.",
        "Recommendations": "Error.",
      };
    }
  }

  // Method to show AI description, tests, and recommendations in a dialog
  void _showAiDiseaseDescriptionDialog(
      BuildContext context, String diseaseName) async {
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext dialogContext) {
        return FutureBuilder<Map<String, String>>(
          future: _getAiDiseaseDescription(diseaseName),
          builder: (context, snapshot) {
            final theme = Theme.of(context); // Get theme for styling
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Fetching Details for $diseaseName'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              );
            }

            String descriptionText = 'Error loading description.';
            String testsText = 'Not specified.';
            String recommendationsText = 'Not specified.';

            if (snapshot.hasError) {
              descriptionText = 'Error: ${snapshot.error}';
            } else if (snapshot.hasData) {
              descriptionText =
                  snapshot.data!['Description'] ?? 'No description available.';
              testsText =
                  snapshot.data!['SuggestedMedicalTests'] ?? 'Not specified.';
              recommendationsText =
                  snapshot.data!['Recommendations'] ?? 'Not specified.';
            } else {
              descriptionText = 'No details available or an error occurred.';
            }

            return AlertDialog(
              title: Text('Details for $diseaseName',
                  style: theme.textTheme.titleLarge),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('Description:',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(descriptionText, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Text('Suggested Medical Tests:',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(testsText, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Text('Recommendations:',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(recommendationsText,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _generatePredictionsFromCsv() {
    // Return type changed
    List<Map<String, dynamic>> allPossiblePredictions = [];
    if (_symptomCsvData.length < 2 || _symptomHeaders.isEmpty) {
      // This case is handled in _loadDataAndPredict now for setting _predictions
      return []; // Return empty list
    }

    int diseaseColumnIndex = _symptomHeaders.indexWhere(
        (h) => h.toLowerCase() == 'disease' || h.toLowerCase() == 'prognosis');
    if (diseaseColumnIndex == -1) diseaseColumnIndex = 0;

    for (int i = 1; i < _symptomCsvData.length; i++) {
      // Start from 1 to skip header row
      final row = _symptomCsvData[i];
      if (row.isEmpty || row.length <= diseaseColumnIndex) continue;

      String diseaseName = row[diseaseColumnIndex].toString().trim();
      if (diseaseName.isEmpty) continue;

      int matchCount = 0;
      int symptomsInCsvForRow = 0;

      for (String selectedSymptom in widget.symptoms) {
        int symptomCsvIndex = -1;
        for (int j = 0; j < _symptomHeaders.length; j++) {
          if (j == diseaseColumnIndex) continue;
          if (_symptomHeaders[j].toLowerCase() ==
              selectedSymptom.toLowerCase().trim()) {
            symptomCsvIndex = j;
            break;
          }
        }

        if (symptomCsvIndex != -1 && symptomCsvIndex < row.length) {
          // Ensure the value is '1' for a match
          if (row[symptomCsvIndex].toString().trim() == '1') {
            matchCount++;
          }
        }
      }

      for (int j = 0; j < _symptomHeaders.length; j++) {
        if (j == diseaseColumnIndex) continue;
        if (j < row.length && row[j].toString().trim() == '1') {
          symptomsInCsvForRow++;
        }
      }

      double chance = 0.0;
      if (widget.symptoms.isNotEmpty && symptomsInCsvForRow > 0) {
        // Prioritize matchCount / symptomsInCsvForRow for better accuracy with categorical data
        chance = matchCount / symptomsInCsvForRow;
      } else if (widget.symptoms.isNotEmpty && matchCount > 0) {
        // Fallback if symptomsInCsvForRow is 0 (should not happen with good data)
        chance = matchCount / widget.symptoms.length.toDouble();
      }

      chance = chance.isNaN || chance.isInfinite ? 0.0 : chance;

      if (chance > 0.01) {
        // Initial filter for some possibility
        String specialist = _diseaseSpecialistsMap[diseaseName] ??
            _diseaseSpecialistsMap.entries
                .firstWhere(
                    (entry) =>
                        entry.key.toLowerCase() == diseaseName.toLowerCase(),
                    orElse: () => MapEntry(diseaseName, 'General Physician'))
                .value;
        if (specialist.isEmpty) specialist = 'General Physician';

        List<String> precautions = _diseasePrecautionsMap[diseaseName] ??
            _diseasePrecautionsMap.entries
                .firstWhere(
                    (entry) =>
                        entry.key.toLowerCase() == diseaseName.toLowerCase(),
                    orElse: () => MapEntry(diseaseName, <String>[]))
                .value;

        String diseaseNameTrimmed = diseaseName.trim();
        String? urlFromMap = _wikipediaUrls[diseaseNameTrimmed];

        // Case-insensitive lookup if direct lookup fails or is empty
        if (urlFromMap == null || urlFromMap.isEmpty) {
          final lowerCaseKey = diseaseNameTrimmed.toLowerCase();
          for (var entry in _wikipediaUrls.entries) {
            if (entry.key.toLowerCase() == lowerCaseKey) {
              urlFromMap = entry.value;
              break;
            }
          }
        }

        String wikipediaUrl = (urlFromMap != null && urlFromMap.isNotEmpty)
            ? urlFromMap
            : 'https://en.wikipedia.org/w/index.php?search=${Uri.encodeComponent(diseaseNameTrimmed)}';
        print(
            "[CSV Prediction] Disease: '$diseaseNameTrimmed', Using Wiki URL: '$wikipediaUrl'");

        allPossiblePredictions.add({
          'name': diseaseName,
          'chance': chance,
          'wikipediaUrl': wikipediaUrl,
          'specialist': specialist,
          'precautions': precautions,
          'description': _diseaseDescriptionsMap[diseaseName] ??
              _diseaseDescriptionsMap.entries
                  .firstWhere(
                      (entry) =>
                          entry.key.toLowerCase() == diseaseName.toLowerCase(),
                      orElse: () => MapEntry(diseaseName, ''))
                  .value,
        });
      }
    }

    // Consolidate predictions: take the max chance for each unique disease name
    Map<String, Map<String, dynamic>> uniqueDiseasePredictionsMap = {};
    for (var pred in allPossiblePredictions) {
      String name = pred['name'];
      if (uniqueDiseasePredictionsMap.containsKey(name)) {
        if ((pred['chance'] as double) >
            (uniqueDiseasePredictionsMap[name]!['chance'] as double)) {
          uniqueDiseasePredictionsMap[name] = pred;
        }
      } else {
        uniqueDiseasePredictionsMap[name] = pred;
      }
    }

    List<Map<String, dynamic>> newPredictions =
        uniqueDiseasePredictionsMap.values.toList();
    newPredictions.sort(
        (a, b) => (b['chance'] as double).compareTo(a['chance'] as double));

    return newPredictions; // Return the consolidated CSV predictions
  }

  void _showPrecautions(
      BuildContext context, String diseaseName, List<String> precautions) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PrecautionsPage(
              diseaseName: diseaseName,
              precautions: precautions)), // Pass precautions
    );
  }

  void _navigateToMedicationPage(String diseaseName) {
    // This method is no longer suitable as MedicationPage needs more data.
    // We will navigate directly from the 'Next' button with all required data.
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => MedicationPage(diseaseName: diseaseName)),
    // );
  }

  Widget _buildTab(String title,
      {required bool isActive,
      required BuildContext context,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    Widget tabContent = Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 8.0), // Added some vertical padding for better tap area
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive
              ? theme.colorScheme.primary
              : theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(8.0), // Optional: for visual feedback
        child: tabContent,
      );
    }
    return tabContent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String symptomsText = widget.symptoms.join(', ');
    if (symptomsText.length > 100) {
      // Truncate if too long for display
      symptomsText = '${symptomsText.substring(0, 97)}...';
    }

    // Ensure _isLoading check is at the beginning of the build method
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Disease Prediction'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            // Added back button for loading screen
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error/No Data check
    if (_predictions.isEmpty ||
        (_predictions.length == 1 &&
            (_predictions.first['name'] == 'Error' ||
                _predictions.first['name'] == 'Data Error' ||
                _predictions.first['name'] == 'No specific match found'))) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Disease Prediction'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                _predictions.isNotEmpty &&
                        _predictions.first['precautions'] is List &&
                        (_predictions.first['precautions'] as List).isNotEmpty
                    ? (_predictions.first['precautions'] as List<String>)
                        .join('\n')
                    : (_predictions.isNotEmpty &&
                            _predictions.first['name'] != null
                        ? _predictions.first['name']! +
                            ": No specific information available."
                        : 'Could not load prediction data.'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease Prediction'),
        backgroundColor: Colors.transparent, // Make AppBar transparent
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true, // Extend body behind appbar for background
      body: Container(
        // Main container for background image or color
        // decoration: BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage("assets/your_background_image.png"), // Add your background image here
        //     fit: BoxFit.cover,
        //   ),
        // ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Header Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTab('Patient', isActive: false, context: context),
                    _buildTab('Symptoms', isActive: false, context: context),
                    _buildTab('Disease', isActive: true, context: context),
                    _buildTab(
                      'Medication',
                      isActive:
                          false, // Remains false as we navigate to a new page
                      context: context,
                      onTap: () {
                        if (_predictions.isNotEmpty) {
                          // final dynamic firstPredictionNameDynamic = _predictions.first['name'];
                          // if (firstPredictionNameDynamic is String && firstPredictionNameDynamic.isNotEmpty) {
                          //   _navigateToMedicationPage(firstPredictionNameDynamic);
                          // }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicationPage(
                                patientData:
                                    widget.patientData, // Pass patient data
                                predictedDiseases:
                                    _predictions, // Pass all predictions
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No predictions available to show medication for.')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Given Symptoms
                Text(
                  'Based on the given symptoms: ${widget.symptoms.join(', ').replaceAll('_', ' ')}',
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Predictions List
                Expanded(
                  child: ListView.builder(
                    itemCount: _predictions.length,
                    itemBuilder: (context, index) {
                      final prediction = _predictions[index];
                      // Diagnostic print for what the UI is about to render
                      print(
                          "UI Rendering Prediction for ${prediction['name']}: HasDetailedPrecautions - ${prediction.containsKey('detailedPrecautions') && prediction['detailedPrecautions'] != null && prediction['detailedPrecautions'] != "Not specified by AI."}, HasTests - ${prediction.containsKey('suggestedMedicalTests') && prediction['suggestedMedicalTests'] != null && prediction['suggestedMedicalTests'] != "Not specified by AI."}, HasAdvice - ${prediction.containsKey('medicationAdvice') && prediction['medicationAdvice'] != null && prediction['medicationAdvice'] != "Consult a doctor for medication advice."}");

                      final String diseaseName =
                          prediction['name'] ?? 'Unknown Disease';
                      final String specialist =
                          prediction['specialist'] ?? 'N/A';
                      final List<String> generalPrecautions =
                          List<String>.from(prediction['precautions'] ?? []);
                      // final String wikipediaUrl = prediction['wikipediaUrl'] ?? ''; // Not directly used in this card structure
                      final double chance = prediction['chance'] ?? 0.0;

                      // AI fields from the prediction map
                      final String aiDescription = prediction['description'] ??
                          'No AI overview provided.';
                      final String aiDetailedPrecautions =
                          prediction['detailedPrecautions'] ??
                              'Not specified by AI.';
                      final String aiSuggestedMedicalTests =
                          prediction['suggestedMedicalTests'] ??
                              'Not specified.';
                      final String aiMedicationAdvice =
                          prediction['medicationAdvice'] ??
                              'Consult a doctor for medication advice.';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      diseaseName, // Display the disease name
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline,
                                        color: theme
                                            .colorScheme.primary), // Add icon
                                    color: theme.colorScheme.primary,
                                    onPressed: () {
                                      // Add onPressed
                                      _showAiDiseaseDescriptionDialog(
                                          context, diseaseName);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (chance > 0) ...[
                                // Only show progress and percentage if chance is calculated
                                LinearProgressIndicator(
                                  value: chance,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  color: chance > 0.6
                                      ? Colors.green
                                      : (chance > 0.3
                                          ? Colors.orange
                                          : Colors.red),
                                  minHeight: 6, // Make it a bit thicker
                                ),
                                const SizedBox(height: 2),
                                Text(
                                    '${(chance * 100).toStringAsFixed(1)}% chance',
                                    style: theme.textTheme.labelSmall),
                              ],
                              const SizedBox(height: 8.0),

                              if (chance < _threshold && chance > 0) ...[
                                // _threshold should be defined in your class, e.g. 0.4
                                Text(
                                  'Probability is relatively low. We recommend you consult $specialist for further advice.',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                      fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 8.0),
                              ],

                              // AI Description (from main AI call's structured output)
                              if (aiDescription.isNotEmpty &&
                                  aiDescription != 'No AI overview provided.' &&
                                  aiDescription !=
                                      'Consult a healthcare professional for more details.')
                                ExpansionTile(
                                  title: Text("Overview (from AI)",
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  children: [
                                    Text(aiDescription,
                                        style: theme.textTheme.bodyMedium)
                                  ],
                                ),

                              // AI Detailed Precautions
                              if (aiDetailedPrecautions.isNotEmpty &&
                                  aiDetailedPrecautions !=
                                      "Not specified by AI.")
                                ExpansionTile(
                                  title: Text("Detailed Precautions (from AI)",
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  children: [
                                    Text(aiDetailedPrecautions,
                                        style: theme.textTheme.bodyMedium)
                                  ],
                                ),

                              // AI Suggested Medical Tests
                              if (aiSuggestedMedicalTests.isNotEmpty &&
                                  aiSuggestedMedicalTests !=
                                      "Not specified by AI.")
                                ExpansionTile(
                                  title: Text(
                                      "Suggested Medical Tests (from AI)",
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: const EdgeInsets.symmetric(
                                      horizontal: 8.0, vertical: 4.0),
                                  children: [
                                    Text(aiSuggestedMedicalTests,
                                        style: theme.textTheme.bodyMedium)
                                  ],
                                ),

                              // AI Medication Advice
                              if (aiMedicationAdvice.isNotEmpty &&
                                  aiMedicationAdvice !=
                                      "Consult a doctor for medication advice.")
                                ExpansionTile(
                                  title: Text("Medication Advice (from AI)",
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight
                                                  .w600)), // Added title
                                  tilePadding:
                                      EdgeInsets.zero, // Added tilePadding
                                  childrenPadding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 4.0), // Added childrenPadding
                                  children: [
                                    Text(aiMedicationAdvice,
                                        style: theme.textTheme.bodyMedium)
                                  ],
                                ),

                              const SizedBox(height: 12.0),
                              if (generalPrecautions
                                  .isNotEmpty) // Only show button if there are general precautions
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _showPrecautions(context, diseaseName,
                                          generalPrecautions);
                                    },
                                    child: const Text('Precautions'),
                                  ),
                                ),
                            ],
                          ),
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
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Go back to SymptomsPage
                      },
                      style: OutlinedButton.styleFrom(
                        // foregroundColor: theme.colorScheme.primary,
                        // side: BorderSide(color: theme.colorScheme.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_predictions.isNotEmpty) {
                          // final dynamic firstPredictionNameDynamic = _predictions.first['name'];
                          // if (firstPredictionNameDynamic is String && firstPredictionNameDynamic.isNotEmpty) {
                          //   _navigateToMedicationPage(firstPredictionNameDynamic);
                          // }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MedicationPage(
                                patientData:
                                    widget.patientData, // Pass patient data
                                predictedDiseases:
                                    _predictions, // Pass all predictions
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No predictions available to show medication for.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: theme.colorScheme.primary,
                        // foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
