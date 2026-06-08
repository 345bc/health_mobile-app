import 'package:flutter/material.dart';
import 'package:frontend/screens/log_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'water_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final Set<int> _visitedTabs = {0};

  final List<Widget> _pages = const [
    HomeScreen(),
    LogScreen(),
    WaterScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_pages.length, (index) {
          // ✅ Tab chưa từng mở → render SizedBox rỗng, không chạy initState
          if (!_visitedTabs.contains(index)) return const SizedBox.shrink();
          return _pages[index];
        }),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _currentIndex = index;
          _visitedTabs.add(index); // ✅ Đánh dấu tab đã mở → lần sau giữ state
        });
      },
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      backgroundColor: const Color(0xFFF0F6FF),
      indicatorColor: const Color(0xFFD0E8FF),
      shadowColor: const Color(0x220F75F4),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: Color(0xFF0F75F4),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        );
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.edit_note_rounded),
          selectedIcon: Icon(Icons.edit_note_rounded),
          label: 'Ghi chép',
        ),
        NavigationDestination(
          icon: Icon(Icons.water_drop_outlined),
          selectedIcon: Icon(Icons.water_drop),
          label: 'Uống nước',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_2_rounded),
          selectedIcon: Icon(Icons.person_2_rounded),
          label: 'Cá nhân',
        ),
      ],
    );
  }
}
