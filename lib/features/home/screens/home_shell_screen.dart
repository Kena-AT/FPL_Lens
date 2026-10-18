import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../squad/screens/squad_screen.dart';
import 'home_screen.dart';

class HomeShellScreen extends StatefulWidget {
  final int initialIndex;

  const HomeShellScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    HomeScreen(),
    SquadScreen(),
    _LineupPlaceholder(),
    _TransfersPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 64,
        decoration: const BoxDecoration(
          color: AppTokens.bgSurface,
          border: Border(top: BorderSide(color: AppTokens.borderSubtle)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTokens.neonPrimary,
          unselectedItemColor: AppTokens.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Squad',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_soccer_outlined),
              activeIcon: Icon(Icons.sports_soccer),
              label: 'Lineup',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz_outlined),
              activeIcon: Icon(Icons.swap_horiz),
              label: 'Transfers',
            ),
          ],
        ),
      ),
    );
  }
}

class _LineupPlaceholder extends StatelessWidget {
  const _LineupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(title: const Text('Lineup')),
      body: const Center(
        child: Text(
          'Lineup Optimizer coming in Sprint 10.',
          style: TextStyle(color: AppTokens.textSecondary),
        ),
      ),
    );
  }
}

class _TransfersPlaceholder extends StatelessWidget {
  const _TransfersPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.bgBase,
      appBar: AppBar(title: const Text('Transfer Lab')),
      body: const Center(
        child: Text(
          'Transfer Lab coming in Sprint 11.',
          style: TextStyle(color: AppTokens.textSecondary),
        ),
      ),
    );
  }
}
