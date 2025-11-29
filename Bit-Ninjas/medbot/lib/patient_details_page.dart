import 'package:flutter/material.dart';
import './symptoms_page.dart'; // Import the new symptoms page

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

enum Gender { male, female }

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  int? _age;
  double? _weight;
  double? _height;
  Gender? _selectedGender;
  
  // Lifestyle questions
  bool _drinks = false;
  bool _smokes = false;
  
  // Pregnancy related (for females)
  bool _isPregnant = false;
  int? _pregnancyMonths;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
              // Header Tabs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTab('Patient', isActive: true, context: context),
                  _buildTab('Symptoms', isActive: false, context: context),
                  _buildTab('Disease', isActive: false, context: context),
                  _buildTab('Medication', isActive: false, context: context),
                ],
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value,
              ),
              const SizedBox(height: 16),

              // Age Field
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid age';
                  }
                  return null;
                },
                onSaved: (value) => _age = int.tryParse(value!),
              ),
              const SizedBox(height: 16),

              // Weight and Height Fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value != null && value.isNotEmpty && (double.tryParse(value) == null || double.parse(value) <= 0)) {
                          return 'Invalid weight';
                        }
                        return null; // Optional field
                      },
                      onSaved: (value) => _weight = double.tryParse(value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                       validator: (value) {
                        if (value != null && value.isNotEmpty && (double.tryParse(value) == null || double.parse(value) <= 0)) {
                          return 'Invalid height';
                        }
                        return null; // Optional field
                      },
                      onSaved: (value) => _height = double.tryParse(value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),              // Gender Radio Buttons
              const Text('Gender:', style: TextStyle(fontSize: 16)),
              Row(
                children: <Widget>[
                  Radio<Gender>(
                    value: Gender.male,
                    groupValue: _selectedGender,
                    onChanged: (Gender? value) {
                      setState(() {
                        _selectedGender = value;
                        // Reset pregnancy related fields when changing gender
                        _isPregnant = false;
                        _pregnancyMonths = null;
                      });
                    },
                  ),
                  const Text('Male'),
                  Radio<Gender>(
                    value: Gender.female,
                    groupValue: _selectedGender,
                    onChanged: (Gender? value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                  const Text('Female'),
                ],
              ),
              const SizedBox(height: 24),

              // Lifestyle Questions
              const Text('Lifestyle Questions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              CheckboxListTile(
                title: const Text('Do you drink alcohol?'),
                value: _drinks,
                onChanged: (bool? value) {
                  setState(() {
                    _drinks = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              
              CheckboxListTile(
                title: const Text('Do you smoke?'),
                value: _smokes,
                onChanged: (bool? value) {
                  setState(() {
                    _smokes = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.primary,
              ),

              // Pregnancy Questions (only for females)
              if (_selectedGender == Gender.female) ...[
                const SizedBox(height: 16),
                const Text('Pregnancy Information:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                CheckboxListTile(
                  title: const Text('Are you pregnant?'),
                  value: _isPregnant,
                  onChanged: (bool? value) {
                    setState(() {
                      _isPregnant = value ?? false;
                      if (!_isPregnant) {
                        _pregnancyMonths = null;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                
                if (_isPregnant) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'How many months pregnant?',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_isPregnant && (value == null || value.isEmpty)) {
                        return 'Please enter pregnancy duration';
                      }
                      if (_isPregnant && value != null && value.isNotEmpty) {
                        int? months = int.tryParse(value);
                        if (months == null || months < 1 || months > 9) {
                          return 'Please enter a valid month (1-9)';
                        }
                      }
                      return null;
                    },
                    onSaved: (value) => _pregnancyMonths = int.tryParse(value ?? ''),
                  ),
                ],              ],
              const SizedBox(height: 32),

              // Bottom Navigation Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary),
                    ),
                    child: const Text('Back'),
                  ),                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        
                        // Collect all patient data for analysis
                        Map<String, dynamic> patientData = {
                          'name': _name,
                          'age': _age,
                          'weight': _weight,
                          'height': _height,
                          'gender': _selectedGender?.name,
                          'drinks': _drinks,
                          'smokes': _smokes,
                          'isPregnant': _selectedGender == Gender.female ? _isPregnant : false,
                          'pregnancyMonths': _isPregnant ? _pregnancyMonths : null,
                        };
                        
                        // Display collected data (in real app, you'd save this to database/state management)
                        // String dataString = 'Patient Details:\\n'
                        //     'Name: $_name\\n'
                        //     'Age: $_age\\n'
                        //     'Gender: ${_selectedGender?.name}\\n'
                        //     'Weight: $_weight kg\\n'
                        //     'Height: $_height cm\\n'
                        //     'Drinks alcohol: ${_drinks ? "Yes" : "No"}\\n'
                        //     'Smokes: ${_smokes ? "Yes" : "No"}';
                            
                        // if (_selectedGender == Gender.female) {
                        //   dataString += '\\nPregnant: ${_isPregnant ? "Yes" : "No"}';
                        //   if (_isPregnant && _pregnancyMonths != null) {
                        //     dataString += '\\nPregnancy duration: $_pregnancyMonths months';
                        //   }
                        // }
                        //   dataString += '\\n\\nNext: Symptoms';
                        
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   SnackBar(
                        //     content: Text(dataString),
                        //     duration: const Duration(seconds: 4),
                        //   ),
                        // );
                        
                        // Navigate to the Symptoms screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SymptomsPage(patientData: patientData),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text('Next'),                  ),
                ],
              ),            ],
          ),
        ),
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
