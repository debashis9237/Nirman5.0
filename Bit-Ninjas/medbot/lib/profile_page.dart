import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User profile data
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userAge = '';
  String _userGender = '';
  String _bloodType = '';
  String _emergencyContact = '';
  String _profileImagePath = '';
    // Medical information
  List<String> _allergies = [];
  List<String> _medications = [];
  List<String> _conditions = [];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }  // Load user data from shared preferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? '';
      _userEmail = prefs.getString('user_email') ?? '';
      _userPhone = prefs.getString('user_phone') ?? '';
      _userAge = prefs.getString('user_age') ?? '';
      _userGender = prefs.getString('user_gender') ?? '';
      _bloodType = prefs.getString('blood_type') ?? '';
      _emergencyContact = prefs.getString('emergency_contact') ?? '';
      _profileImagePath = prefs.getString('profile_image_path') ?? '';
      
      _allergies = prefs.getStringList('allergies') ?? [];
      _medications = prefs.getStringList('medications') ?? [];
      _conditions = prefs.getStringList('conditions') ?? [];
    });
  }  // Save user data to shared preferences
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _userName);
    await prefs.setString('user_email', _userEmail);
    await prefs.setString('user_phone', _userPhone);
    await prefs.setString('user_age', _userAge);
    await prefs.setString('user_gender', _userGender);
    await prefs.setString('blood_type', _bloodType);
    await prefs.setString('emergency_contact', _emergencyContact);
    await prefs.setString('profile_image_path', _profileImagePath);
    
    await prefs.setStringList('allergies', _allergies);
    await prefs.setStringList('medications', _medications);
    await prefs.setStringList('conditions', _conditions);
  }

  // Method to pick profile image
  Future<void> _pickProfileImage() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setState(() {
                        _profileImagePath = image.path;
                      });
                      await _saveUserData();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      setState(() {
                        _profileImagePath = image.path;
                      });
                      await _saveUserData();
                    }
                  },
                ),
                if (_profileImagePath.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Photo'),
                    onTap: () async {
                      Navigator.pop(context);
                      setState(() {
                        _profileImagePath = '';
                      });
                      await _saveUserData();
                    },
                  ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }  void _showEditDialog(String title, String currentValue, Function(String) onSave) {
    // Special handling for gender field
    if (title.toLowerCase() == 'gender') {
      _showGenderDialog(onSave);
      return;
    }
    
    final controller = TextEditingController(text: currentValue);
    
    // Get hint text based on field type
    String hintText = '';
    switch (title.toLowerCase()) {
      case 'name':
        hintText = 'Enter your full name';
        break;
      case 'email':
        hintText = 'Enter your email address';
        break;
      case 'phone':
        hintText = 'Enter your phone number';
        break;
      case 'age':
        hintText = 'Enter your age';
        break;
      case 'blood type':
        hintText = 'e.g., A+, B-, O+, AB-';
        break;
      case 'emergency contact':
        hintText = 'Enter emergency contact number';
        break;
      default:
        hintText = 'Enter $title';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: title,
              hintText: hintText,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.of(context).pop();
                _saveUserData();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showGenderDialog(Function(String) onSave) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Male'),
                leading: Radio<String>(
                  value: 'Male',
                  groupValue: _userGender,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.of(context).pop();
                      onSave(value);
                      setState(() => _userGender = value);
                      _saveUserData();
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onSave('Male');
                  setState(() => _userGender = 'Male');
                  _saveUserData();
                },
              ),
              ListTile(
                title: const Text('Female'),
                leading: Radio<String>(
                  value: 'Female',
                  groupValue: _userGender,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.of(context).pop();
                      onSave(value);
                      setState(() => _userGender = value);
                      _saveUserData();
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onSave('Female');
                  setState(() => _userGender = 'Female');
                  _saveUserData();
                },
              ),
              ListTile(
                title: const Text('Other'),
                leading: Radio<String>(
                  value: 'Other',
                  groupValue: _userGender.startsWith('Other') ? 'Other' : _userGender,
                  onChanged: (value) {
                    if (value != null) {
                      Navigator.of(context).pop();
                      _showCustomGenderDialog(onSave);
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showCustomGenderDialog(onSave);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showCustomGenderDialog(Function(String) onSave) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Specify Gender'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Gender',
              hintText: 'Please specify your gender',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  final customGender = controller.text;
                  onSave(customGender);
                  setState(() => _userGender = customGender);
                  _saveUserData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a gender')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showListEditDialog(String title, List<String> currentList, Function(List<String>) onSave) {
    final List<String> tempList = List.from(currentList);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit $title'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tempList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(tempList[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  tempList.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final controller = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Add $title'),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: 'Enter new $title',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (controller.text.isNotEmpty) {
                                    setDialogState(() {
                                      tempList.add(controller.text);
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: Text('Add $title'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSave(tempList);
                    Navigator.of(context).pop();
                    _saveUserData();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              _buildProfileHeader(theme),
              const SizedBox(height: 24),
                // Personal Information Section
              _buildSectionCard(
                theme,
                'Personal Information',
                Icons.person,
                [
                  _buildInfoTile('Name', _userName, () => _showEditDialog('Name', _userName, (value) => setState(() => _userName = value))),
                  _buildInfoTile('Email', _userEmail, () => _showEditDialog('Email', _userEmail, (value) => setState(() => _userEmail = value))),
                  _buildInfoTile('Phone', _userPhone, () => _showEditDialog('Phone', _userPhone, (value) => setState(() => _userPhone = value))),
                  _buildInfoTile('Age', _userAge, () => _showEditDialog('Age', _userAge, (value) => setState(() => _userAge = value))),
                  _buildInfoTile('Gender', _userGender, () => _showEditDialog('Gender', _userGender, (value) => setState(() => _userGender = value))),
                ],
              ),
              const SizedBox(height: 16),
                // Medical Information Section
              _buildSectionCard(
                theme,
                'Medical Information',
                Icons.medical_services,
                [
                  _buildInfoTile('Blood Type', _bloodType, () => _showEditDialog('Blood Type', _bloodType, (value) => setState(() => _bloodType = value))),
                  _buildInfoTile('Emergency Contact', _emergencyContact, () => _showEditDialog('Emergency Contact', _emergencyContact, (value) => setState(() => _emergencyContact = value))),
                  _buildListTile('Allergies', _allergies, () => _showListEditDialog('Allergy', _allergies, (value) => setState(() => _allergies = value))),
                  _buildListTile('Current Medications', _medications, () => _showListEditDialog('Medication', _medications, (value) => setState(() => _medications = value))),
                  _buildListTile('Medical Conditions', _conditions, () => _showListEditDialog('Condition', _conditions, (value) => setState(() => _conditions = value))),
                ],              ),
              const SizedBox(height: 24),
              
              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logout successful!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary,
                backgroundImage: _profileImagePath.isNotEmpty
                    ? FileImage(File(_profileImagePath))
                    : null,
                child: _profileImagePath.isEmpty
                    ? Text(
                        _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),          Text(
            _userName.isNotEmpty ? _userName : 'Your Name',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _userName.isEmpty 
                  ? theme.textTheme.bodyMedium?.color?.withOpacity(0.6)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail.isNotEmpty ? _userEmail : 'your.email@example.com',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _userEmail.isEmpty
                  ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                  : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }  Widget _buildInfoTile(String title, String value, VoidCallback? onTap) {
    final bool isEmpty = value.isEmpty;
    String displayValue = value;
    
    if (isEmpty) {
      switch (title.toLowerCase()) {
        case 'name':
          displayValue = 'Not set';
          break;
        case 'email':
          displayValue = 'Not set';
          break;
        case 'phone':
          displayValue = 'Not set';
          break;
        case 'age':
          displayValue = 'Not set';
          break;
        case 'gender':
          displayValue = 'Not set';
          break;
        case 'blood type':
          displayValue = 'Not set';
          break;
        case 'emergency contact':
          displayValue = 'Not set';
          break;
        default:
          displayValue = 'Not set';
      }
    }
    
    return ListTile(
      title: Text(title),
      subtitle: Text(
        displayValue,
        style: isEmpty 
          ? TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            )
          : null,
      ),
      trailing: onTap != null ? const Icon(Icons.edit, size: 20) : null,
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }  Widget _buildListTile(String title, List<String> items, VoidCallback onTap) {
    final bool isEmpty = items.isEmpty;
    String displayText = '';
    
    if (isEmpty) {
      switch (title.toLowerCase()) {
        case 'allergies':
          displayText = 'No known allergies';
          break;
        case 'current medications':
          displayText = 'No current medications';
          break;
        case 'medical conditions':
          displayText = 'No medical conditions';
          break;
        default:
          displayText = 'None added';
      }
    } else {
      displayText = items.join(', ');
    }
    
    return ListTile(
      title: Text(title),
      subtitle: Text(
        displayText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: isEmpty 
          ? TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            )
          : null,
      ),
      trailing: const Icon(Icons.edit, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
