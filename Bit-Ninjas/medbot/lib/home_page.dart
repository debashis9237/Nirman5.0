import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';
import './treatment_page.dart'; // Import the new treatment page
import './emergency_page.dart'; // Import the emergency page
import './profile_page.dart'; // Import the profile page
import './settings_page.dart'; // Import the settings page
import './schedule_page.dart'; // Import the schedule page
import './med_bot_page.dart'; // Import the Med-Bot page
import './voice_assistant_page.dart'; // Talk To Ally page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // For BottomNavigationBar
  // Replaced GlobalKey with a refresh notifier to avoid duplicate GlobalKey issues
  final ValueNotifier<int> _homeRefreshNotifier = ValueNotifier<int>(0);
  String _profileImagePath = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path') ?? '';
    });
  } // Define the list of pages to be displayed by the BottomNavigationBar

  List<Widget> get _widgetOptions => <Widget>[
        HomeScreenBody(
            refreshTrigger:
                _homeRefreshNotifier), // Main content widget with refresh listener
        const TreatmentPage(),
        EmergencyPage(),
        const SchedulePage(),
        const ProfilePage(),
      ];

  void _onItemTapped(int index) {
    // Store previous index
    final previousIndex = _selectedIndex;

    setState(() {
      _selectedIndex = index;
    });

    // Refresh home screen name and profile image when coming back from profile page
    if (index == 0 && previousIndex == 4) {
      // Coming back to home from profile: trigger refresh
      _homeRefreshNotifier.value++;
      _loadProfileImage();
    } else if (previousIndex == 4) {
      // Coming from profile to any other page
      _loadProfileImage();
    }
  }

  Widget _buildProfileIcon() {
    if (_profileImagePath.isNotEmpty && File(_profileImagePath).existsSync()) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(File(_profileImagePath)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return const Icon(Icons.person_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // AppBar is now part of HomeScreenBody or specific to it
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all items are visible
        backgroundColor:
            theme.colorScheme.surface, // Or theme.bottomAppBarColor
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.textTheme.bodyLarge?.color?.withOpacity(0.6),
        elevation: 8.0, // Add some elevation
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              label: 'Treat'), // Placeholder, find better icon
          const BottomNavigationBarItem(
              icon: Icon(Icons.emergency, color: Colors.red),
              label: 'Emergency'), // Emergency button
          const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              label: 'Schedule'), // Placeholder
          BottomNavigationBarItem(
              icon: _buildProfileIcon(),
              label: 'Profile'), // Dynamic profile icon
        ],
      ),
    );
  }
}

// New Widget for the Home Screen's main content
class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key, required this.refreshTrigger});

  final ValueNotifier<int> refreshTrigger;

  @override
  State<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  String _firstName = 'User';

  // Health Facts Carousel State
  late PageController _pageController;
  Timer? _timer;
  int _currentFactIndex = 0;

  // Health Facts Data
  final List<Map<String, dynamic>> _healthFacts = [
    {
      'fact':
          'Your brain uses about 20% of your body\'s total energy, even though it only weighs about 3 pounds.',
      'category': 'Brain Health',
      'icon': Icons.psychology_outlined,
      'color': Colors.purple,
    },
    {
      'fact':
          'Walking for just 30 minutes a day can reduce the risk of heart disease by up to 35%.',
      'category': 'Heart Health',
      'icon': Icons.favorite_outline,
      'color': Colors.red,
    },
    {
      'fact':
          'Drinking water first thing in the morning can boost your metabolism by up to 30%.',
      'category': 'Hydration',
      'icon': Icons.water_drop_outlined,
      'color': Colors.blue,
    },
    {
      'fact':
          'Laughing for 15 minutes burns the same calories as walking for 2 minutes.',
      'category': 'Mental Health',
      'icon': Icons.sentiment_very_satisfied_outlined,
      'color': Colors.orange,
    },
    {
      'fact':
          'Getting 7-9 hours of sleep can improve memory consolidation by up to 40%.',
      'category': 'Sleep Health',
      'icon': Icons.bedtime_outlined,
      'color': Colors.indigo,
    },
    {
      'fact':
          'Eating colorful fruits and vegetables provides over 25,000 different antioxidants.',
      'category': 'Nutrition',
      'icon': Icons.restaurant_outlined,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _pageController = PageController();
    _startAutoSlide();
    // Listen for external refresh triggers (e.g., returning from profile page)
    widget.refreshTrigger.addListener(_handleExternalRefresh);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    widget.refreshTrigger.removeListener(_handleExternalRefresh);
    super.dispose();
  }

  void _handleExternalRefresh() {
    refreshUserName();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentFactIndex = (_currentFactIndex + 1) % _healthFacts.length;
        _pageController.animateToPage(
          _currentFactIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString('user_name') ?? '';

    setState(() {
      if (fullName.isNotEmpty) {
        // Extract first name (everything before the first space)
        final nameParts = fullName.trim().split(' ');
        _firstName = nameParts.first;
      } else {
        _firstName = 'User';
      }
    });
  }

  // Public method to refresh user name
  void refreshUserName() {
    _loadUserName();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello,',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7)),
            ),
            Text(
              '$_firstName!',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
              icon: Icon(Icons.settings, color: theme.colorScheme.primary),
              iconSize: 28,
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchDoctor(theme),
            const SizedBox(height: 24.0),
            _buildSpecialitiesList(theme),
            const SizedBox(height: 24.0),
            Text('Upcoming Appointment', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12.0),
            _buildUpcomingAppointmentCard(theme), const SizedBox(height: 24.0),
            // Did You Know? Section (moved above Health Feed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Did You Know?',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                    onTap: () {
                      // Navigate to full list of health facts (optional)
                    },
                    child: Icon(Icons.refresh_outlined,
                        color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 12.0),
            _buildHealthFactsCarousel(theme),
            const SizedBox(height: 24.0),
            // Health Feed Section (moved below)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Health Feed', style: theme.textTheme.titleLarge),
                TextButton(
                    onPressed: () {
                      // Navigate to full health feed page
                    },
                    child: Text('View All',
                        style: TextStyle(color: theme.colorScheme.primary))),
              ],
            ),
            const SizedBox(height: 12.0),
            _buildHealthFeed(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthFeed(ThemeData theme) {
    final healthTips = [
      {
        'title': 'Morning Hydration',
        'description':
            'Start your day with a glass of warm lemon water to boost metabolism.',
        'icon': Icons.wb_sunny_outlined,
        'category': 'Daily Tips',
        'color': Colors.orange,
      },
      {
        'title': 'Walking Benefits',
        'description':
            '30 minutes of walking burns 150-200 calories and improves heart health.',
        'icon': Icons.directions_walk,
        'category': 'Exercise',
        'color': Colors.blue,
      },
      {
        'title': 'Better Sleep',
        'description':
            'Avoid screens 1 hour before bedtime for better sleep quality.',
        'icon': Icons.bedtime_outlined,
        'category': 'Sleep',
        'color': Colors.purple,
      },
      {
        'title': 'Colorful Nutrition',
        'description':
            'Include different colored vegetables for varied vitamins and antioxidants.',
        'icon': Icons.restaurant_outlined,
        'category': 'Nutrition',
        'color': Colors.green,
      },
    ];

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: healthTips.length,
        itemBuilder: (context, index) {
          final tip = healthTips[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16.0),
            child: Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              color: theme.colorScheme.surface,
              child: InkWell(
                onTap: () {
                  // Navigate to HealthTipDetailPage when tapped
                },
                borderRadius: BorderRadius.circular(12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: (tip['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Icon(
                              tip['icon'] as IconData,
                              color: tip['color'] as Color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tip['title'] as String,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0, vertical: 2.0),
                                  decoration: BoxDecoration(
                                    color: (tip['color'] as Color)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    tip['category'] as String,
                                    style: TextStyle(
                                      color: tip['color'] as Color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Text(
                          tip['description'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyLarge?.color
                                ?.withOpacity(0.7),
                            height: 1.3,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Tap to read more',
                            style: TextStyle(
                              color: tip['color'] as Color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: tip['color'] as Color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchDoctor(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search Doctor',
          hintStyle: TextStyle(
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5)),
          icon: Icon(Icons.search,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSpecialitiesList(ThemeData theme) {
    final specialities = [
      {
        'name': 'Talk To Ally',
        'icon': Icons.person_outline,
      },
      {'name': 'Med Mini Bot', 'icon': Icons.smart_toy_outlined},
    ];
    return SizedBox(
      height: 100, // Adjust height as needed
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: specialities.length,
        itemBuilder: (context, index) {
          return Container(
            width: 80, // Adjust width as needed
            margin: const EdgeInsets.only(right: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    final name = specialities[index]['name'];
                    if (name == 'Talk To Ally') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VoiceAssistantPage()),
                      );
                    } else if (name == 'Med Mini Bot') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedBotPage()),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        specialities[index]['name'] == 'Talk To Ally'
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      specialities[index]['icon'] as IconData,
                      size: 30,
                      color: specialities[index]['name'] == 'Talk To Ally'
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  specialities[index]['name'] as String,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(ThemeData theme) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: theme.colorScheme.primary
          .withOpacity(0.8), // Using primary color as in image
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: Icon(Icons.person_pin_circle_outlined,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. Jennifer Smith',
                        style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text('Orthopedic Consultation (Foot & Ankle)',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white.withOpacity(0.9))),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      color: Colors.white.withOpacity(0.9), size: 16),
                  const SizedBox(width: 4),
                  Text('Wed, 7 Sep 2024',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white.withOpacity(0.9))),
                ]),
                Row(children: [
                  Icon(Icons.access_time_outlined,
                      color: Colors.white.withOpacity(0.9), size: 16),
                  const SizedBox(width: 4),
                  Text('10:30 - 11:30 AM',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white.withOpacity(0.9))),
                ]),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHealthFactsCarousel(ThemeData theme) {
    // Per-category gradients for visual variety (matches multi-gradient request)
    LinearGradient _gradientFor(String category) {
      switch (category) {
        case 'Brain Health':
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B123A), Color(0xFF522063), Color(0xFF8C46C7)],
          );
        case 'Heart Health':
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A0B27), Color(0xFF8E1242), Color(0xFFD83E72)],
          );
        case 'Hydration':
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2747), Color(0xFF0F4C81), Color(0xFF2F7AC9)],
          );
        case 'Mental Health':
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF422100), Color(0xFF80460A), Color(0xFFE27E28)],
          );
        case 'Sleep Health':
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF141B3A), Color(0xFF263066), Color(0xFF4A5DA8)],
          );
        case 'Nutrition':
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0E3A24), Color(0xFF1F6B3F), Color(0xFF33A35C)],
          );
        default:
          return LinearGradient(colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.6)
          ]);
      }
    }

    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentFactIndex = index),
        itemCount: _healthFacts.length,
        itemBuilder: (context, index) {
          final fact = _healthFacts[index];
          final category = fact['category'] as String;
          final gradient = _gradientFor(category);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & category pill
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          fact['icon'] as IconData,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Health Fact',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Inner white-ish card with fact text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: gradient.colors.last.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lightbulb_outline,
                              size: 20, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            fact['fact'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13.5,
                              color: Colors.black87,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Footer controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fact ${index + 1} of ${_healthFacts.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _timer?.cancel();
                              _currentFactIndex =
                                  (_currentFactIndex + 1) % _healthFacts.length;
                              _pageController.animateToPage(
                                _currentFactIndex,
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeInOut,
                              );
                              _startAutoSlide();
                            },
                            child: Row(
                              children: [
                                Icon(Icons.refresh_outlined,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.85)),
                                const SizedBox(width: 4),
                                Text(
                                  'Tap refresh for more',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
