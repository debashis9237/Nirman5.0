import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class MedicationRemindersPage extends StatefulWidget {
  const MedicationRemindersPage({super.key});

  @override
  State<MedicationRemindersPage> createState() => _MedicationRemindersPageState();
}

class _MedicationRemindersPageState extends State<MedicationRemindersPage> {
  List<MedicationReminder> _reminders = [];
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadReminders();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.init();
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? reminderData = prefs.getStringList('medication_reminders');
    
    if (reminderData != null) {
      setState(() {
        _reminders = reminderData.map((item) => MedicationReminder.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> reminderData = _reminders.map((item) => item.toJson()).toList();
    await prefs.setStringList('medication_reminders', reminderData);
  }

  void _addReminder(MedicationReminder reminder) {
    setState(() {
      _reminders.add(reminder);
    });
    _saveReminders();
    _scheduleNotifications(reminder);
  }

  void _editReminder(int index, MedicationReminder newReminder) {
    // Cancel old notifications
    _cancelNotifications(_reminders[index]);
    
    setState(() {
      _reminders[index] = newReminder;
    });
    _saveReminders();
    _scheduleNotifications(newReminder);
  }

  void _deleteReminder(int index) {
    _cancelNotifications(_reminders[index]);
    setState(() {
      _reminders.removeAt(index);
    });
    _saveReminders();
  }

  void _toggleReminder(int index) {
    final reminder = _reminders[index];
    final newReminder = MedicationReminder(
      id: reminder.id,
      medicationName: reminder.medicationName,
      dosage: reminder.dosage,
      frequency: reminder.frequency,
      times: reminder.times,
      startDate: reminder.startDate,
      endDate: reminder.endDate,
      notes: reminder.notes,
      isActive: !reminder.isActive,
    );

    if (newReminder.isActive) {
      _scheduleNotifications(newReminder);
    } else {
      _cancelNotifications(reminder);
    }

    setState(() {
      _reminders[index] = newReminder;
    });
    _saveReminders();
  }

  void _scheduleNotifications(MedicationReminder reminder) {
    if (!reminder.isActive) return;

    for (final time in reminder.times) {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Schedule recurring notification based on frequency
      RepeatInterval interval;
      switch (reminder.frequency) {
        case MedicationFrequency.daily:
          interval = RepeatInterval.daily;
          break;
        case MedicationFrequency.twiceDaily:
        case MedicationFrequency.thriceDaily:
        case MedicationFrequency.fourTimesDaily:
          interval = RepeatInterval.daily;
          break;
        case MedicationFrequency.weekly:
          interval = RepeatInterval.weekly;
          break;
        case MedicationFrequency.asNeeded:
          // Don't schedule recurring for as needed medications
          continue;
      }

      final notificationId = reminder.id * 100 + reminder.times.indexOf(time);
      
      _notificationService.scheduleRecurringMedicationReminder(
        id: notificationId,
        title: '💊 Medication Reminder',
        body: 'Time to take ${reminder.medicationName} (${reminder.dosage})',
        firstScheduledTime: scheduledDate,
        repeatInterval: interval,
        payload: 'medication_${reminder.id}',
      );
    }
  }

  void _cancelNotifications(MedicationReminder reminder) {
    for (int i = 0; i < reminder.times.length; i++) {
      final notificationId = reminder.id * 100 + i;
      _notificationService.cancelNotification(notificationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: _reminders.isEmpty
          ? _buildEmptyState(theme)
          : _buildRemindersList(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReminderDialog(context),
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No medication reminders set',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first medication reminder to stay on track',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddReminderDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: reminder.isActive 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              child: Icon(
                Icons.medication,
                color: reminder.isActive ? Colors.green : Colors.grey,
              ),
            ),
            title: Text(
              reminder.medicationName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                decoration: reminder.isActive ? null : TextDecoration.lineThrough,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Dosage: ${reminder.dosage}'),
                Text('Frequency: ${_getFrequencyText(reminder.frequency)}'),
                Text('Times: ${reminder.times.map((t) => t.format(context)).join(', ')}'),
                if (reminder.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: ${reminder.notes}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'toggle':
                    _toggleReminder(index);
                    break;
                  case 'edit':
                    _showEditReminderDialog(context, reminder, index);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, index);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(reminder.isActive ? Icons.pause : Icons.play_arrow),
                      const SizedBox(width: 8),
                      Text(reminder.isActive ? 'Pause' : 'Resume'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFrequencyText(MedicationFrequency frequency) {
    switch (frequency) {
      case MedicationFrequency.daily:
        return 'Once daily';
      case MedicationFrequency.twiceDaily:
        return 'Twice daily';
      case MedicationFrequency.thriceDaily:
        return 'Three times daily';
      case MedicationFrequency.fourTimesDaily:
        return 'Four times daily';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.asNeeded:
        return 'As needed';
    }
  }

  void _showAddReminderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddMedicationReminderDialog(
        onAdd: _addReminder,
      ),
    );
  }

  void _showEditReminderDialog(BuildContext context, MedicationReminder reminder, int index) {
    showDialog(
      context: context,
      builder: (context) => AddMedicationReminderDialog(
        onAdd: (newReminder) => _editReminder(index, newReminder),
        existingReminder: reminder,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete the reminder for ${_reminders[index].medicationName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteReminder(index);
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medication Reminders'),
        content: const Text(
          'Set up reminders to help you remember to take your medications on time. '
          'You can customize the frequency, times, and add notes for each medication.\n\n'
          'Make sure to enable notifications in your device settings for the best experience.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class AddMedicationReminderDialog extends StatefulWidget {
  final Function(MedicationReminder) onAdd;
  final MedicationReminder? existingReminder;

  const AddMedicationReminderDialog({
    super.key,
    required this.onAdd,
    this.existingReminder,
  });

  @override
  State<AddMedicationReminderDialog> createState() => _AddMedicationReminderDialogState();
}

class _AddMedicationReminderDialogState extends State<AddMedicationReminderDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  
  MedicationFrequency _selectedFrequency = MedicationFrequency.daily;
  List<TimeOfDay> _selectedTimes = [TimeOfDay.now()];
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    if (widget.existingReminder != null) {
      final reminder = widget.existingReminder!;
      _nameController.text = reminder.medicationName;
      _dosageController.text = reminder.dosage;
      _notesController.text = reminder.notes;
      _selectedFrequency = reminder.frequency;
      _selectedTimes = List.from(reminder.times);
      _startDate = reminder.startDate;
      _endDate = reminder.endDate;
    } else {
      _updateTimesForFrequency();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTimesForFrequency() {
    setState(() {
      switch (_selectedFrequency) {
        case MedicationFrequency.daily:
          _selectedTimes = [const TimeOfDay(hour: 9, minute: 0)];
          break;
        case MedicationFrequency.twiceDaily:
          _selectedTimes = [
            const TimeOfDay(hour: 9, minute: 0),
            const TimeOfDay(hour: 21, minute: 0),
          ];
          break;
        case MedicationFrequency.thriceDaily:
          _selectedTimes = [
            const TimeOfDay(hour: 9, minute: 0),
            const TimeOfDay(hour: 14, minute: 0),
            const TimeOfDay(hour: 21, minute: 0),
          ];
          break;
        case MedicationFrequency.fourTimesDaily:
          _selectedTimes = [
            const TimeOfDay(hour: 8, minute: 0),
            const TimeOfDay(hour: 13, minute: 0),
            const TimeOfDay(hour: 18, minute: 0),
            const TimeOfDay(hour: 23, minute: 0),
          ];
          break;
        case MedicationFrequency.weekly:
          _selectedTimes = [const TimeOfDay(hour: 9, minute: 0)];
          break;
        case MedicationFrequency.asNeeded:
          _selectedTimes = [];
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingReminder != null 
          ? 'Edit Medication Reminder' 
          : 'Add Medication Reminder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medication Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 500mg, 1 tablet)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<MedicationFrequency>(
              value: _selectedFrequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: MedicationFrequency.values.map((frequency) {
                return DropdownMenuItem(
                  value: frequency,
                  child: Text(_getFrequencyText(frequency)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFrequency = value!;
                  _updateTimesForFrequency();
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedFrequency != MedicationFrequency.asNeeded) ...[
              const Text('Reminder Times:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._selectedTimes.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                return ListTile(
                  title: Text('Time ${index + 1}'),
                  subtitle: Text(time.format(context)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _selectTime(context, index),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectStartDate(context),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('End Date (Optional)'),
                    subtitle: Text(_endDate != null 
                        ? DateFormat('MMM d, yyyy').format(_endDate!)
                        : 'No end date'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectEndDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
            if (_nameController.text.isNotEmpty && _dosageController.text.isNotEmpty) {
              final reminder = MedicationReminder(
                id: widget.existingReminder?.id ?? DateTime.now().millisecondsSinceEpoch,
                medicationName: _nameController.text,
                dosage: _dosageController.text,
                frequency: _selectedFrequency,
                times: _selectedTimes,
                startDate: _startDate,
                endDate: _endDate,
                notes: _notesController.text,
                isActive: true,
              );
              widget.onAdd(reminder);
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.existingReminder != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  String _getFrequencyText(MedicationFrequency frequency) {
    switch (frequency) {
      case MedicationFrequency.daily:
        return 'Once daily';
      case MedicationFrequency.twiceDaily:
        return 'Twice daily';
      case MedicationFrequency.thriceDaily:
        return 'Three times daily';
      case MedicationFrequency.fourTimesDaily:
        return 'Four times daily';
      case MedicationFrequency.weekly:
        return 'Weekly';
      case MedicationFrequency.asNeeded:
        return 'As needed';
    }
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    setState(() {
      _endDate = picked;
    });
  }
}

enum MedicationFrequency {
  daily,
  twiceDaily,
  thriceDaily,
  fourTimesDaily,
  weekly,
  asNeeded,
}

class MedicationReminder {
  final int id;
  final String medicationName;
  final String dosage;
  final MedicationFrequency frequency;
  final List<TimeOfDay> times;
  final DateTime startDate;
  final DateTime? endDate;
  final String notes;
  final bool isActive;

  MedicationReminder({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.startDate,
    this.endDate,
    required this.notes,
    required this.isActive,
  });

  String toJson() {
    final timesString = times.map((t) => '${t.hour}:${t.minute}').join(',');
    final endDateString = endDate?.millisecondsSinceEpoch.toString() ?? '';
    return '$id|$medicationName|$dosage|${frequency.index}|$timesString|${startDate.millisecondsSinceEpoch}|$endDateString|$notes|$isActive';
  }

  static MedicationReminder fromJson(String json) {
    final parts = json.split('|');
    final timesString = parts[4];
    final times = timesString.isEmpty ? <TimeOfDay>[] : timesString.split(',').map((t) {
      final timeParts = t.split(':');
      return TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
    }).toList();
    
    return MedicationReminder(
      id: int.parse(parts[0]),
      medicationName: parts[1],
      dosage: parts[2],
      frequency: MedicationFrequency.values[int.parse(parts[3])],
      times: times,
      startDate: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[5])),
      endDate: parts[6].isEmpty ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(parts[6])),
      notes: parts[7],
      isActive: parts[8] == 'true',
    );
  }
}
