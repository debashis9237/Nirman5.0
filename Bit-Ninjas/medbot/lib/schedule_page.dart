import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<ScheduleItem> _scheduleItems = [];
  DateTime _selectedDate = DateTime.now();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadScheduleData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Load schedule data from SharedPreferences
  Future<void> _loadScheduleData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? scheduleData = prefs.getStringList('schedule_items');
    
    if (scheduleData != null) {
      setState(() {
        _scheduleItems = scheduleData.map((item) => ScheduleItem.fromJson(item)).toList();
      });
    }
  }

  // Save schedule data to SharedPreferences
  Future<void> _saveScheduleData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> scheduleData = _scheduleItems.map((item) => item.toJson()).toList();
    await prefs.setStringList('schedule_items', scheduleData);
  }
  // Add new schedule item
  void _addScheduleItem(ScheduleItem item) {
    setState(() {
      _scheduleItems.add(item);
    });
    _saveScheduleData();
    _scheduleNotification(item);
  }

  // Delete schedule item
  void _deleteScheduleItem(int index) {
    setState(() {
      _scheduleItems.removeAt(index);
    });
    _saveScheduleData();
  }

  // Get items for selected date
  List<ScheduleItem> _getItemsForDate(DateTime date) {
    return _scheduleItems.where((item) {
      return item.date.year == date.year &&
             item.date.month == date.month &&
             item.date.day == date.day;
    }).toList()..sort((a, b) => a.time.compareTo(b.time));
  }

  // Get items by type
  List<ScheduleItem> _getItemsByType(ScheduleType type) {
    return _scheduleItems.where((item) => item.type == type).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  // Schedule notification for schedule item
  void _scheduleNotification(ScheduleItem item) {
    // Parse time string to get notification time
    final timeParts = item.time.split(' ');
    final timeOnly = timeParts[0];
    final period = timeParts.length > 1 ? timeParts[1] : '';
    
    final hourMinute = timeOnly.split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    
    // Convert to 24-hour format
    if (period.toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (period.toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }
    
    // Create notification time
    final notificationTime = DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      hour,
      minute,
    );
    
    // Only schedule if the time is in the future
    if (notificationTime.isAfter(DateTime.now())) {
      final notificationId = item.hashCode;
      
      switch (item.type) {
        case ScheduleType.appointment:
          _notificationService.scheduleAppointmentReminder(
            id: notificationId,
            title: '🏥 Appointment Reminder',
            body: '${item.title}${item.location.isNotEmpty ? ' at ${item.location}' : ''}',
            scheduledTime: notificationTime.subtract(const Duration(minutes: 30)), // 30 minutes before
            payload: 'appointment_${item.hashCode}',
          );
          break;
        case ScheduleType.medication:
          _notificationService.scheduleMedicationReminder(
            id: notificationId,
            title: '💊 Medication Reminder',
            body: 'Time to take ${item.title}',
            scheduledTime: notificationTime,
            payload: 'medication_${item.hashCode}',
          );
          break;
        case ScheduleType.exercise:
          _notificationService.scheduleExerciseReminder(
            id: notificationId,
            title: '🏃‍♂️ Exercise Reminder',
            body: 'Time for ${item.title}',
            scheduledTime: notificationTime,
            payload: 'exercise_${item.hashCode}',
          );
          break;
        case ScheduleType.checkup:
          _notificationService.scheduleAppointmentReminder(
            id: notificationId,
            title: '🩺 Health Checkup Reminder',
            body: '${item.title}${item.location.isNotEmpty ? ' at ${item.location}' : ''}',
            scheduledTime: notificationTime.subtract(const Duration(hours: 1)), // 1 hour before
            payload: 'checkup_${item.hashCode}',
          );
          break;
        case ScheduleType.other:
          _notificationService.showImmediateNotification(
            id: notificationId,
            title: '📅 Schedule Reminder',
            body: item.title,
            payload: 'other_${item.hashCode}',
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.medical_services), text: 'Appointments'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Activities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayView(theme),
          _buildAppointmentsView(theme),
          _buildMedicationsView(theme),
          _buildActivitiesView(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTodayView(ThemeData theme) {
    final todayItems = _getItemsForDate(DateTime.now());
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelector(theme),
          const SizedBox(height: 24),
          if (todayItems.isEmpty)
            _buildEmptyState('No scheduled items for today', Icons.today)
          else
            _buildScheduleList(todayItems, theme),
        ],
      ),
    );
  }

  Widget _buildAppointmentsView(ThemeData theme) {
    final appointments = _getItemsByType(ScheduleType.appointment);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (appointments.isEmpty)
            _buildEmptyState('No upcoming appointments', Icons.event_available)
          else
            _buildScheduleList(appointments, theme),
        ],
      ),
    );
  }

  Widget _buildMedicationsView(ThemeData theme) {
    final medications = _getItemsByType(ScheduleType.medication);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (medications.isEmpty)
            _buildEmptyState('No medication reminders', Icons.medication)
          else
            _buildScheduleList(medications, theme),
        ],
      ),
    );
  }

  Widget _buildActivitiesView(ThemeData theme) {
    final activities = _getItemsByType(ScheduleType.exercise);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (activities.isEmpty)
            _buildEmptyState('No fitness activities scheduled', Icons.fitness_center)
          else
            _buildScheduleList(activities, theme),
        ],
      ),
    );
  }

  Widget _buildDateSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _selectDate(context),
            icon: Icon(Icons.edit_calendar, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showAddScheduleDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<ScheduleItem> items, ThemeData theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: _getTypeColor(item.type).withOpacity(0.2),
              child: Icon(_getTypeIcon(item.type), color: _getTypeColor(item.type)),
            ),
            title: Text(
              item.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (item.description.isNotEmpty) ...[
                  Text(item.description),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${DateFormat('MMM d').format(item.date)} at ${item.time}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (item.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: theme.textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteScheduleItem(_scheduleItems.indexOf(item));
                } else if (value == 'edit') {
                  _showEditScheduleDialog(context, item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showAddScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        onAdd: _addScheduleItem,
      ),
    );
  }

  void _showEditScheduleDialog(BuildContext context, ScheduleItem item) {
    showDialog(
      context: context,
      builder: (context) => AddScheduleDialog(
        onAdd: (newItem) {
          final index = _scheduleItems.indexOf(item);
          setState(() {
            _scheduleItems[index] = newItem;
          });
          _saveScheduleData();
        },
        existingItem: item,
      ),
    );
  }

  Color _getTypeColor(ScheduleType type) {
    switch (type) {
      case ScheduleType.appointment:
        return Colors.blue;
      case ScheduleType.medication:
        return Colors.green;
      case ScheduleType.exercise:
        return Colors.orange;
      case ScheduleType.checkup:
        return Colors.purple;
      case ScheduleType.other:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(ScheduleType type) {
    switch (type) {
      case ScheduleType.appointment:
        return Icons.medical_services;
      case ScheduleType.medication:
        return Icons.medication;
      case ScheduleType.exercise:
        return Icons.fitness_center;
      case ScheduleType.checkup:
        return Icons.health_and_safety;
      case ScheduleType.other:
        return Icons.event;
    }
  }
}

class AddScheduleDialog extends StatefulWidget {
  final Function(ScheduleItem) onAdd;
  final ScheduleItem? existingItem;

  const AddScheduleDialog({
    super.key,
    required this.onAdd,
    this.existingItem,
  });

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  ScheduleType _selectedType = ScheduleType.appointment;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _titleController.text = item.title;
      _descriptionController.text = item.description;
      _locationController.text = item.location;
      _selectedType = item.type;
      _selectedDate = item.date;
      
      // Parse time string to TimeOfDay
      final timeParts = item.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1].split(' ')[0]);
      final isPM = item.time.contains('PM');
      _selectedTime = TimeOfDay(
        hour: isPM && hour != 12 ? hour + 12 : (isPM || hour != 12 ? hour : 0),
        minute: minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem != null ? 'Edit Schedule Item' : 'Add Schedule Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ScheduleType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              items: ScheduleType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getTypeIcon(type)),
                      const SizedBox(width: 8),
                      Text(_getTypeLabel(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Date'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Time'),
                    subtitle: Text(_selectedTime.format(context)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                  ),
                ),
              ],
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
            if (_titleController.text.isNotEmpty) {
              final item = ScheduleItem(
                title: _titleController.text,
                description: _descriptionController.text,
                location: _locationController.text,
                type: _selectedType,
                date: _selectedDate,
                time: _selectedTime.format(context),
              );
              widget.onAdd(item);
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.existingItem != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  IconData _getTypeIcon(ScheduleType type) {
    switch (type) {
      case ScheduleType.appointment:
        return Icons.medical_services;
      case ScheduleType.medication:
        return Icons.medication;
      case ScheduleType.exercise:
        return Icons.fitness_center;
      case ScheduleType.checkup:
        return Icons.health_and_safety;
      case ScheduleType.other:
        return Icons.event;
    }
  }

  String _getTypeLabel(ScheduleType type) {
    switch (type) {
      case ScheduleType.appointment:
        return 'Doctor Appointment';
      case ScheduleType.medication:
        return 'Medication Reminder';
      case ScheduleType.exercise:
        return 'Exercise/Fitness';
      case ScheduleType.checkup:
        return 'Health Checkup';
      case ScheduleType.other:
        return 'Other';
    }
  }
}

enum ScheduleType {
  appointment,
  medication,
  exercise,
  checkup,
  other,
}

class ScheduleItem {
  final String title;
  final String description;
  final String location;
  final ScheduleType type;
  final DateTime date;
  final String time;

  ScheduleItem({
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.date,
    required this.time,
  });

  // Convert to JSON string for storage
  String toJson() {
    return '${type.index}|$title|$description|$location|${date.millisecondsSinceEpoch}|$time';
  }

  // Create from JSON string
  static ScheduleItem fromJson(String json) {
    final parts = json.split('|');
    return ScheduleItem(
      type: ScheduleType.values[int.parse(parts[0])],
      title: parts[1],
      description: parts[2],
      location: parts[3],
      date: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4])),
      time: parts[5],
    );
  }
}
