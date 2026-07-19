import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/pin_storage.dart';
import '../widgets/set_pin_dialog.dart';
import '../screens/my_files_screen.dart';
import '../screens/shared_with_me_screen.dart';
import '../screens/my_shares_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _hasPin = false;

  final List<Widget> _screens = const [
    MyFilesScreen(),
    SharedWithMeScreen(),
    MySharesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final hasPin = await PinStorage().hasPin();
    if (mounted) {
      setState(() => _hasPin = hasPin);
    }
  }

  Future<void> _showSetPinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => SetPinDialog(isChange: _hasPin),
    );
    if (result == true) {
      _checkPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FamilyVault'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthProvider>().logout();
              } else if (value == 'pin') {
                _showSetPinDialog();
              }
            },
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      _hasPin ? Icons.lock : Icons.lock_outline,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(_hasPin ? 'Change PIN' : 'Set PIN'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error, size: 20),
                    SizedBox(width: 12),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                radius: 16,
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'My Files',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Shared',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share_outlined),
              activeIcon: Icon(Icons.share),
              label: 'My Shares',
            ),
          ],
        ),
      ),
    );
  }
}
