import 'package:flutter/material.dart';
import 'medication_detail_page.dart'; // Import the new detail page
import 'package:http/http.dart' as http; // Added for HTTP requests
import 'dart:convert'; // Added for jsonEncode and jsonDecode
import 'dart:async'; // Added for TimeoutException

class MedicationPage extends StatefulWidget {
  // final String diseaseName; // To display the disease for which medication is shown
  final Map<String, dynamic> patientData;
  final List<Map<String, dynamic>> predictedDiseases;

  const MedicationPage({
    Key? key,
    // required this.diseaseName,
    required this.patientData,
    required this.predictedDiseases,
  }) : super(key: key);

  @override
  _MedicationPageState createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  late List<Map<String, dynamic>> _localPredictedDiseases;
  final TextEditingController _daysController = TextEditingController();
  // bool _isLoading = false; // Replaced with _loadingDiseaseIndex
  int? _loadingDiseaseIndex; // Added to track loading state per item
  bool _isOverallLoading = false; // Added for overall loading state

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of predicted diseases to allow updates
    _localPredictedDiseases = List<Map<String, dynamic>>.from(widget
        .predictedDiseases
        .map((disease) => Map<String, dynamic>.from(disease)));
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  // Helper to build the tab bar
  Widget _buildTab(String title,
      {required bool isActive,
      required BuildContext context,
      VoidCallback? onTap}) {
    final theme = Theme.of(context);
    Widget tabContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
        borderRadius: BorderRadius.circular(8.0),
        child: tabContent,
      );
    }
    return tabContent;
  }

  Future<void> _showSymptomDurationDialog(BuildContext context,
      Map<String, dynamic> diseaseData, int diseaseIndex) async {
    _daysController.clear(); // Clear previous input
    final String diseaseName = diseaseData['name'] ?? 'Unknown Disease';
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Symptom Duration for $diseaseName',
              style: theme.textTheme.titleLarge),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('For how many days have you had these symptoms?'),
                const SizedBox(height: 8),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "e.g., 3",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                final String days = _daysController.text;
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                // Call the async function
                _navigateToMedicationDetail(
                    context, diseaseName, days, diseaseIndex);
              },
            ),
          ],
        );
      },
    );
  }

  // New function to ask AI if clarifying questions are needed
  Future<List<String>> _fetchClarifyingQuestionsFromAI({
    required String diseaseName,
    required int symptomDuration,
    required Map<String, dynamic> patientData,
  }) async {
    const String apiKey = 'AIzaSyCMOVqzMDw53FWNTIx8QJ9Ahk27rJ3vHJg';
    const String apiEndpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';

    final String patientDetails = "Patient Details:\\n"
        "Age: ${patientData['age']}\\n"
        "Weight: ${patientData['weight']} kg\\n"
        "Height: ${patientData['height']} cm\\n"
        "Gender: ${patientData['gender']}\\n"
        "Drinks Alcohol: ${patientData['drinks']}\\n"
        "Smokes: ${patientData['smokes']}\\n"
        "Currently Pregnant: ${patientData['isPregnant']}\\n"
        "${patientData['isPregnant'] == true ? "Pregnancy Months: ${patientData['pregnancyMonths']}\\n" : ""}";

    // Refined prompt for clarifying questions
    final String promptText = """
Based on the following patient information, disease, and symptom duration:
$patientDetails
Disease: $diseaseName
Symptom Duration: $symptomDuration days

**Your Task:**
1.  Analyze the provided information.
2.  Determine if you **critically need** more specific information to provide accurate medication advice or warnings.
    *   Only ask for information that is essential for a deeper analysis (e.g., body temperature if fever is a general symptom, specific visual cues for a skin condition, presence of other highly relevant symptoms).
    *   **If you need to ask about specific symptoms, phrase these questions as Yes/No questions** (e.g., "Do you have a fever (Yes/No)?", "Are you experiencing muscle aches (Yes/No)?"). 
    *   **Do NOT ask "What are your symptoms?" or broadly ask for a list of symptoms again.** The user has already provided initial symptoms to get to this stage.
3.  If no further specific information is critical, return an empty JSON array: `{"questions": []}`.
4.  If you need to ask questions, provide them in a JSON array format like this: `{"questions": ["Question 1?", "Question 2 (Yes/No)?", "Question 3?"]}`.
    *   Limit to a maximum of 3-4 essential questions.
    *   Ensure the output is ONLY the JSON object, starting with `{` and ending with `}`.

**Important:** Your task here is ONLY to decide if clarifying questions are essential and to provide them in the specified JSON format if they are.""";
    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': promptText}
          ]
        }
      ],
      'generationConfig': {
        // Added to guide response type
        'responseMimeType': 'application/json',
      }
    };

    try {
      print('Fetching clarifying questions from AI...');
      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final String responseBody = response.body;
        print('AI Raw Response (for clarifying questions): $responseBody');

        try {
          final Map<String, dynamic> outerResponseData =
              jsonDecode(responseBody);

          if (outerResponseData.containsKey('candidates') &&
              outerResponseData['candidates'] is List &&
              (outerResponseData['candidates'] as List).isNotEmpty) {
            final candidate = (outerResponseData['candidates'] as List).first;
            if (candidate is Map &&
                candidate.containsKey('content') &&
                candidate['content'] is Map &&
                candidate['content'].containsKey('parts') &&
                candidate['content']['parts'] is List &&
                (candidate['content']['parts'] as List).isNotEmpty) {
              final part = (candidate['content']['parts'] as List).first;
              if (part is Map &&
                  part.containsKey('text') &&
                  part['text'] is String) {
                String questionsJsonString = part['text'] as String;

                // The questionsJsonString might be wrapped in ```json ... ``` if the model didn't strictly adhere to responseMimeType
                // This is a safeguard, though ideally the 'application/json' mime type should prevent this for the text part.
                questionsJsonString = questionsJsonString.trim();
                if (questionsJsonString.startsWith("```json")) {
                  questionsJsonString = questionsJsonString.substring(7);
                  if (questionsJsonString.endsWith("```")) {
                    questionsJsonString = questionsJsonString.substring(
                        0, questionsJsonString.length - 3);
                  }
                  questionsJsonString = questionsJsonString.trim();
                }

                final Map<String, dynamic> innerQuestionsData =
                    jsonDecode(questionsJsonString);
                if (innerQuestionsData.containsKey('questions') &&
                    innerQuestionsData['questions'] is List) {
                  List<dynamic> questionListDyn =
                      innerQuestionsData['questions'];
                  if (questionListDyn.isNotEmpty) {
                    print(
                        'Successfully parsed questions: ${questionListDyn.length} questions found.');
                    return List<String>.from(
                        questionListDyn.map((q) => q.toString()));
                  } else {
                    print('Parsed questions list is empty.');
                  }
                } else {
                  print(
                      '\'questions\' key not found or not a list in the inner JSON.');
                }
              } else {
                print('\'text\' key not found in part or not a string.');
              }
            } else {
              print('Invalid candidate structure in AI response.');
            }
          } else {
            print('\'candidates\' key not found or invalid in AI response.');
          }
          // If any of the above checks fail, fall through to return empty list
          print('Could not extract questions from AI response structure.');
          return [];
        } catch (e) {
          print(
              'Error decoding or processing AI response for questions: $e. Raw response: $responseBody');
          return []; // Error case, proceed without questions
        }
      } else {
        print(
            'Error fetching clarifying questions: ${response.statusCode} - ${response.body}');
        return []; // Error case, proceed without questions
      }
    } catch (e) {
      print('Exception fetching clarifying questions: $e');
      return []; // Exception case, proceed without questions
    }
  }

  // New dialog to prompt user for additional information
  Future<Map<String, String>?> _promptForAdditionalInfoDialog(
    BuildContext context,
    List<String> questions,
    String diseaseName,
  ) async {
    final Map<String, TextEditingController> controllers = {
      for (var q in questions) q: TextEditingController()
    };
    final _formKey = GlobalKey<FormState>(); // Optional: for validation

    // Dispose controllers when dialog is done
    void disposeControllers() {
      for (var controller in controllers.values) {
        controller.dispose();
      }
    }

    return showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Additional Information for $diseaseName',
              style: Theme.of(context).textTheme.titleLarge),
          content: SizedBox(
            // Constrain height and make scrollable
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: ListBody(
                  children: questions.map((question) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(question,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: controllers[question],
                            decoration: InputDecoration(
                              hintText: 'Your answer here',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            // validator: (value) { // Optional validation
                            //   if (value == null || value.isEmpty) {
                            //     return 'Please provide an answer';
                            //   }
                            //   return null;
                            // },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Skip'), // Changed from 'Cancel' to 'Skip'
              onPressed: () {
                Navigator.of(dialogContext).pop(null); // Return null if skipped
              },
            ),
            ElevatedButton(
              child: const Text('Submit Answers'),
              onPressed: () {
                // if (_formKey.currentState!.validate()) { // Uncomment if using validation
                final Map<String, String> answers = {};
                for (var question in questions) {
                  answers[question] = controllers[question]!.text;
                }
                Navigator.of(dialogContext).pop(answers);
                // }
              },
            ),
          ],
        );
      },
    ).whenComplete(() {
      disposeControllers(); // Ensure controllers are disposed
    });
  }

  // Placeholder for actual AI service call
  Future<String> _getAiMedicationAdvice({
    required String diseaseName,
    required int symptomDuration,
    required Map<String, dynamic> patientData,
    bool isExtendedDuration = false,
    Map<String, String>? additionalAnswers, // New parameter for additional info
  }) async {
    const String apiKey = 'AIzaSyCMOVqzMDw53FWNTIx8QJ9Ahk27rJ3vHJg';
    const String apiEndpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey';

    String additionalInfoSegment = "";
    if (additionalAnswers != null && additionalAnswers.isNotEmpty) {
      final answersFormatted = additionalAnswers.entries
          .map((e) => "- Question: ${e.key}\\n  Answer: ${e.value}")
          .join("\\n");
      additionalInfoSegment =
          "\\n**Additional Information Provided by User (in response to AI's clarifying questions):**\\n"
          "$answersFormatted\\n";
    }

    String promptText;
    if (isExtendedDuration) {
      promptText = "Patient Details:\\n"
              "Age: ${patientData['age']}\\n"
              "Weight: ${patientData['weight']} kg\\n"
              "Height: ${patientData['height']} cm\\n"
              "Gender: ${patientData['gender']}\\n"
              "Drinks Alcohol: ${patientData['drinks']}\\n"
              "Smokes: ${patientData['smokes']}\\n"
              "Currently Pregnant: ${patientData['isPregnant']}\\n"
              "${patientData['isPregnant'] == true ? "Pregnancy Months: ${patientData['pregnancyMonths']}\\n" : ""}"
              "\\n"
              "Disease: $diseaseName\\n"
              "Symptom Duration: $symptomDuration days (which is MORE THAN 10 DAYS)\\n" +
          additionalInfoSegment + // Added additional info segment
          "\\n"
              "**Task:** The patient's symptoms for '$diseaseName' have persisted for $symptomDuration days. This is a concerning duration.\\n"
              "Generate a response that includes:\\n"
              "1. A @@clear warning@@ about the risks of symptoms lasting this long, emphasizing the need for professional medical attention.\\n"
              "2. **Potential Risks of Delay:** Detail specific potential complications or worsening of the condition if professional consultation for '$diseaseName' is delayed further.\\n"
              "3. **Action Required:** Advise the patient to consult a specific type of specialist suitable for '$diseaseName'. If a specific specialist is not obvious, recommend consulting a General Physician urgently for assessment and referral. Emphasize the urgency.\\n"
              "4. Use '**' for bolding (e.g., **Warning**) and '@@' for red/bold text (e.g., @@Urgent Consultation Needed@@). \\n"
              "5. Ensure the output is a single string, well-formatted for display.\\n"
              "6. @@Do NOT suggest Over-The-Counter (OTC) medications or home remedies in this scenario; the focus must be solely on the urgency of seeking professional medical consultation.@@";
    } else {
      promptText = "Patient Details:\\n"
              "Age: ${patientData['age']}\\n"
              "Weight: ${patientData['weight']} kg\\n"
              "Height: ${patientData['height']} cm\\n"
              "Gender: ${patientData['gender']}\\n"
              "Drinks Alcohol: ${patientData['drinks']}\\n"
              "Smokes: ${patientData['smokes']}\\n"
              "Currently Pregnant: ${patientData['isPregnant']}\\n"
              "${patientData['isPregnant'] == true ? "Pregnancy Months: ${patientData['pregnancyMonths']}\\n" : ""}"
              "\\n"
              "Disease: $diseaseName\\n"
              "Symptom Duration: $symptomDuration days\\n" +
          additionalInfoSegment + // Added additional info segment
          "\\n"
              "**Task:** Provide practical and safe Over-The-Counter (OTC) medication suggestions AND home remedies for initial relief of '$diseaseName' given the patient details, symptom duration, and any additional information provided. "
              "Your response MUST include specific, actionable advice. For example, suggest specific types of OTC medications (e.g., 'ibuprofen for pain relief', 'loratadine for allergies') and concrete home remedies (e.g., 'gargle with salt water for sore throat', 'apply a cold compress to reduce swelling'). "
              "The advice should be something a user can safely act upon without immediate professional consultation, focusing on symptom management. "
              "\\n"
              "**Formatting Requirements:** Ensure the output is a single string. Use '**' for bolding (e.g., **Warning**) and '@@' for red/bold text (e.g., @@Urgent@@). "
              "\\n"
              "**Disclaimer (Include this AFTER providing medication/remedy advice):** Include a clear disclaimer that this advice is not a substitute for professional medical consultation and to see a doctor if symptoms persist, worsen, or if there are any concerns. "
              "\\n"
              "**Important Constraints:** Do NOT prescribe prescription medications. Only suggest generally safe OTC options and common home remedies. If the disease is severe or requires immediate medical attention based on its name alone (e.g., 'Heart Attack', 'Stroke'), then primarily emphasize seeking immediate medical help and provide minimal, very safe comfort measures if any. "
              "Prioritize providing helpful, actionable OTC and home remedy advice before the disclaimer.";
    }

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': promptText}
          ]
        }
      ],
      // 'generationConfig': { // Consider if response_mime_type is needed here too
      //   'maxOutputTokens': 700,
      // }
    };

    try {
      print(
          'Sending request to AI service for advice (with any additional info): $apiEndpoint');
      final response = await http
          .post(
            Uri.parse(apiEndpoint),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 45));

      print('AI Service Response Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseBody = response.body; // Store for potential error logging
        print('AI Advice Raw Response: $responseBody');
        String jsonString = responseBody;
        final jsonMarkdownPattern =
            RegExp(r"```(?:json)?\\s*([\\s\\S]*?)\\s*```");
        final match = jsonMarkdownPattern.firstMatch(responseBody);
        if (match != null) {
          jsonString = match.group(1)!;
        }

        try {
          final Map<String, dynamic> responseData = jsonDecode(jsonString);
          if (responseData.containsKey('candidates') &&
              responseData['candidates'] is List &&
              (responseData['candidates'] as List).isNotEmpty &&
              (responseData['candidates'] as List)
                  .first
                  .containsKey('content') &&
              (responseData['candidates'] as List)
                  .first['content']
                  .containsKey('parts') &&
              (responseData['candidates'] as List).first['content']['parts']
                  is List &&
              ((responseData['candidates'] as List).first['content']['parts']
                      as List)
                  .isNotEmpty &&
              ((responseData['candidates'] as List).first['content']['parts']
                      as List)
                  .first
                  .containsKey('text')) {
            String advice = ((responseData['candidates'] as List)
                    .first['content']['parts'] as List)
                .first['text'] as String;

            if (advice.isEmpty) {
              return "Received empty advice from AI. Please try again.";
            }
            return advice;
          } else {
            print(
                "Failed to extract advice from Gemini response structure. Full response body: $responseBody");
            return "AI service responded, but advice could not be extracted in the expected format. Response: ${responseBody.substring(0, (responseBody.length > 200 ? 200 : responseBody.length))}";
          }
        } catch (e) {
          print(
              'Error decoding JSON for AI advice: $e. Raw response: $responseBody');
          // Check if the raw response itself is the advice (if not JSON)
          if (responseBody.isNotEmpty &&
              !responseBody.trim().startsWith('{') &&
              !responseBody.trim().startsWith('[')) {
            print('Assuming raw response is the advice as it is not JSON.');
            return responseBody;
          }
          return "Error processing AI response. Please try again. Details: $e";
        }
      } else {
        // Handle non-200 responses
        print(
            'AI Service Error: ${response.statusCode} - ${response.reasonPhrase}');
        print('AI Service Error Body: ${response.body}');
        String errorMessage = "Status: ${response.statusCode}.";
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData.containsKey('error') &&
              errorData['error'] is Map &&
              errorData['error'].containsKey('message')) {
            errorMessage += " Message: ${errorData['error']['message']}";
          } else {
            errorMessage +=
                " Body: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}";
          }
        } catch (_) {
          errorMessage +=
              " Body: ${response.body.substring(0, (response.body.length > 100 ? 100 : response.body.length))}";
        }
        return "@@Error: Failed to get advice from AI service. $errorMessage Please try again later.@@";
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Exception during AI service call: $e');
      if (e is http.ClientException) {
        return "@@Error: Network issue connecting to AI service. Please check your connection and try again.@@";
      } else if (e is TimeoutException) {
        return "@@Error: The request to the AI service timed out. Please try again later.@@";
      }
      return "@@Error: An unexpected error occurred while fetching AI advice: $e. Please try again later.@@";
    }
  }

  // Show a fullscreen loading screen using a state variable
  void _showFullscreenLoading() {
    if (mounted) {
      setState(() {
        _isOverallLoading = true;
      });
    }
  }

  void _hideFullscreenLoading() {
    if (mounted) {
      setState(() {
        _isOverallLoading = false;
      });
    }
  }

  // Updated _navigateToMedicationDetail
  Future<void> _navigateToMedicationDetail(BuildContext pageButtonContext,
      String diseaseName, String days, int diseaseIndex) async {
    print(
        'Attempting to generate medication advice for $diseaseName, duration: $days days, index: $diseaseIndex');
    String advice = "An unknown error occurred. Please try again.";
    final int? numDays = int.tryParse(days);

    if (days.isEmpty || numDays == null || numDays <= 0) {
      advice =
          "Symptom duration was not provided or is invalid. Please go back and ensure it is entered correctly on the previous screen.";
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
              content:
                  Text(advice, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    Map<String, String>? additionalAnswers;
    try {
      // 1. Ask for clarifying questions (no loading yet)
      List<String> clarifyingQuestions = await _fetchClarifyingQuestionsFromAI(
        diseaseName: diseaseName,
        symptomDuration: numDays,
        patientData: widget.patientData,
      );
      if (!mounted) return;

      // 2. If clarifying questions, show dialog and get answers
      if (clarifyingQuestions.isNotEmpty) {
        final Map<String, String>? userAnswers =
            await _promptForAdditionalInfoDialog(
          this.context,
          clarifyingQuestions,
          diseaseName,
        );
        if (!mounted) return;
        if (userAnswers != null) {
          additionalAnswers = userAnswers;
        }
      }

      // 3. Show fullscreen loading for the actual AI advice call
      _showFullscreenLoading();
      final bool isExtended = numDays > 10;
      advice = await _getAiMedicationAdvice(
        diseaseName: diseaseName,
        symptomDuration: numDays,
        patientData: widget.patientData,
        isExtendedDuration: isExtended,
        additionalAnswers: additionalAnswers,
      );
      if (!mounted) return;
    } catch (e) {
      advice =
          "@@Error: Could not fetch AI advice at this time. Please try again later.@@\nDebug information: $e";
      print("Error during multi-step AI advice for $diseaseName: $e");
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
              content: Text("Error fetching advice: ",
                  style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      _hideFullscreenLoading();
    }

    if (!mounted) return;

    Navigator.of(pageButtonContext, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => MedicationDetailPage(
          diseaseName: diseaseName,
          medicationAdvice: advice,
          symptomDurationDays: numDays.toString(),
        ),
      ),
    );
  }

  // Make sure to remove or comment out the old _getSpecialistForDisease and _getPotentialComplications if they are no longer used.
  // For now, I will leave them as the previous step mentioned they were still there.
  // String _getPotentialComplications(String diseaseName) { ... }
  // String _getSpecialistForDisease(String diseaseName) { ... }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Medication Advice'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          extendBodyBehindAppBar: true,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Header Tabs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTab('Patient', isActive: false, context: context,
                            onTap: () {
                          // Navigate back to Patient Details if needed, or adjust logic
                          // For now, assume it might go back multiple steps or to a specific route
                          // This might need a more robust navigation solution (e.g., named routes or passing back data)
                          if (Navigator.canPop(context))
                            Navigator.pop(context); // Pop once
                          if (Navigator.canPop(context))
                            Navigator.pop(
                                context); // Pop twice to get past disease prediction
                        }),
                        _buildTab('Symptoms', isActive: false, context: context,
                            onTap: () {
                          if (Navigator.canPop(context))
                            Navigator.pop(
                                context); // Pop once to get past disease prediction
                        }),
                        _buildTab('Disease', isActive: false, context: context,
                            onTap: () {
                          if (Navigator.canPop(context))
                            Navigator.pop(context); // Pop to disease prediction
                        }),
                        _buildTab('Medication',
                            isActive: true, context: context),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // User Details Section
                    Text('User Details:', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.patientData.entries.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Text('${entry.key}: ',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold)),
                                  Expanded(
                                      child: Text(entry.value.toString(),
                                          style: theme.textTheme.titleMedium)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Medication for Predicted Diseases Section
                    Text('Medication for Predicted Diseases:',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    // Use _localPredictedDiseases and provide index to update medication
                    ..._localPredictedDiseases.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> disease = entry.value;
                      final String diseaseName =
                          disease['name'] ?? 'Unknown Disease';
                      String medicationAdvice = disease['medicationAdvice'] ??
                          "Tap 'Get Medication' for advice.";

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
                              Text(diseaseName,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              // _buildRichText(medicationAdvice, theme.textTheme.bodyMedium), // No longer display advice here directly
                              // Display initial or placeholder advice if needed, or remove this Text widget
                              Text(medicationAdvice,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadingDiseaseIndex == index
                                    ? null
                                    : () {
                                        // Disable button if this item is loading
                                        _showSymptomDurationDialog(
                                            context, disease, index);
                                      },
                                child: _loadingDiseaseIndex == index
                                    ? const SizedBox(
                                        height: 20.0,
                                        width: 20.0,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.0,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white)),
                                      )
                                    : const Text('Get Medication'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 20), // Adjusted spacing slightly
                    // Removed SizedBox wrapper and full-width styling for Download Prescription button
                    // const SizedBox(height: 20), // Adjusted spacing - this line can be removed or adjusted as needed
                    // Bottom Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Align buttons to ends
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(
                                context); // Go back to Disease Prediction Page
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12), // Adjusted padding
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Back'),
                        ),
                        ElevatedButton(
                          // Moved Download Prescription button here
                          onPressed: () {
                            // TODO: Implement Download Prescription
                            print('Download Prescription tapped');
                          },
                          style: ElevatedButton.styleFrom(
                            // backgroundColor: theme.colorScheme.secondary, // Optional: customize color
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12), // Adjusted padding
                            textStyle: const TextStyle(
                                fontSize: 16), // Adjusted text size
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Download Prescription'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isOverallLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
