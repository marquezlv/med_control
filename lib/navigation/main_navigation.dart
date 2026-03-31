import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/medications.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _homeRefreshSignal = 0;
  int _medicationsRefreshSignal = 0;

  void _openMedicationManager() {
    setState(() {
      _selectedIndex = 1;
      _medicationsRefreshSignal++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(
        onOpenMedicationManager: _openMedicationManager,
        refreshSignal: _homeRefreshSignal,
      ),
      MedicationsScreen(refreshSignal: _medicationsRefreshSignal),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) {
              _homeRefreshSignal++;
            } else {
              _medicationsRefreshSignal++;
            }
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.medication_rounded),
            label: 'Medications',
          ),
        ],
      ),
    );
  }
}
