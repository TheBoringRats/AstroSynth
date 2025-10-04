import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/planet.dart';

/// Planet Comparison Screen - Inspired by NASA Eyes on Exoplanets
///
/// Features:
/// - Side-by-side planet comparison (up to 3 planets + Earth)
/// - Travel time calculator with different spacecraft speeds
/// - Size comparison visualization
/// - Light travel time ("looking back in time")
/// - Interactive comparison metrics
class PlanetComparisonScreen extends StatefulWidget {
  final List<Planet> initialPlanets;

  const PlanetComparisonScreen({super.key, this.initialPlanets = const []});

  @override
  State<PlanetComparisonScreen> createState() => _PlanetComparisonScreenState();
}

class _PlanetComparisonScreenState extends State<PlanetComparisonScreen>
    with SingleTickerProviderStateMixin {
  late List<Planet> _selectedPlanets;
  late TabController _tabController;

  // Earth reference for comparison
  final Planet _earth = Planet(
    name: 'Earth',
    hostStarName: 'Sun',
    radius: 1.0,
    mass: 1.0,
    equilibriumTemperature: 288,
    semiMajorAxis: 1.0,
    distanceFromEarth: 0,
    orbitalPeriod: 365.25,
    eccentricity: 0.0167,
    discoveryYear: null,
    discoveryMethod: 'Home Planet',
    stellarSpectralType: 'G2V',
    stellarTemperature: 5778,
  );

  @override
  void initState() {
    super.initState();
    _selectedPlanets = [_earth, ...widget.initialPlanets.take(2)];
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.spaceBackgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              Expanded(child: _buildTabContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planet Comparison',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Compare exoplanets side-by-side',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(icon: Icon(Icons.compare), text: 'Comparison'),
          Tab(icon: Icon(Icons.rocket_launch), text: 'Travel Time'),
          Tab(icon: Icon(Icons.timeline), text: 'Light Travel'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildComparisonTab(),
        _buildTravelTimeTab(),
        _buildLightTravelTab(),
      ],
    );
  }

  // ============================================================
  // TAB 1: PLANET COMPARISON
  // ============================================================
  Widget _buildComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanetSelector(),
          const SizedBox(height: 24),
          _buildSizeComparison(),
          const SizedBox(height: 24),
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildPlanetSelector() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected Planets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedPlanets.map((planet) {
                return Chip(
                  avatar: Icon(
                    planet.name == 'Earth' ? Icons.public : Icons.language,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    planet.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: planet.name == 'Earth'
                      ? const Color(0xFF0984E3)
                      : AppTheme.primaryColor,
                  deleteIcon: planet.name != 'Earth'
                      ? const Icon(Icons.close, size: 18, color: Colors.white)
                      : null,
                  onDeleted: planet.name != 'Earth'
                      ? () {
                          setState(() {
                            _selectedPlanets.remove(planet);
                          });
                        }
                      : null,
                );
              }).toList(),
            ),
            if (_selectedPlanets.length < 4)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  onPressed: _addPlanetDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Planet'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeComparison() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Size Comparison',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _selectedPlanets.map((planet) {
                  final radius = planet.radius ?? 1.0;
                  final maxRadius = _selectedPlanets
                      .map((p) => p.radius ?? 1.0)
                      .reduce(math.max);
                  final size = (radius / maxRadius) * 150;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _getPlanetGradient(planet),
                          boxShadow: [
                            BoxShadow(
                              color: _getPlanetGradient(
                                planet,
                              ).colors.first.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        planet.name == 'Earth' ? 'Earth' : planet.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '${radius.toStringAsFixed(2)} R⊕',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      color: AppTheme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Comparison',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
              'Radius',
              _selectedPlanets
                  .map((p) => '${(p.radius ?? 1.0).toStringAsFixed(2)} R⊕')
                  .toList(),
            ),
            _buildComparisonRow(
              'Mass',
              _selectedPlanets
                  .map((p) => '${(p.mass ?? 1.0).toStringAsFixed(2)} M⊕')
                  .toList(),
            ),
            _buildComparisonRow(
              'Temperature',
              _selectedPlanets
                  .map(
                    (p) =>
                        '${(p.equilibriumTemperature ?? 288).toStringAsFixed(0)} K',
                  )
                  .toList(),
            ),
            _buildComparisonRow(
              'Distance',
              _selectedPlanets.map((p) {
                if (p.name == 'Earth') return '0 ly';
                final ly = (p.distanceFromEarth ?? 0) * 3.26156;
                return '${ly.toStringAsFixed(1)} ly';
              }).toList(),
            ),
            _buildComparisonRow(
              'Orbital Period',
              _selectedPlanets
                  .map(
                    (p) => '${(p.orbitalPeriod ?? 365).toStringAsFixed(1)} d',
                  )
                  .toList(),
            ),
            _buildComparisonRow(
              'Discovery Year',
              _selectedPlanets
                  .map((p) => p.discoveryYear?.toString() ?? 'N/A')
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...values.map(
            (value) => Expanded(
              flex: 2,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 2: TRAVEL TIME CALCULATOR
  // ============================================================
  Widget _buildTravelTimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _selectedPlanets.where((p) => p.name != 'Earth').map((
          planet,
        ) {
          return _buildTravelTimeCard(planet);
        }).toList(),
      ),
    );
  }

  Widget _buildTravelTimeCard(Planet planet) {
    final distanceLY = (planet.distanceFromEarth ?? 0) * 3.26156;
    final distanceKM = distanceLY * 9.461e12; // km

    // Spacecraft speeds (km/s)
    final voyager1Speed = 17.0; // km/s
    final newHorizonsSpeed = 16.26; // km/s (at launch)
    final parkerSpeed = 163.0; // km/s (peak speed)
    final lightSpeed = 299792.458; // km/s

    // Calculate travel times
    final voyagerYears = (distanceKM / voyager1Speed) / (365.25 * 24 * 3600);
    final newHorizonsYears =
        (distanceKM / newHorizonsSpeed) / (365.25 * 24 * 3600);
    final parkerYears = (distanceKM / parkerSpeed) / (365.25 * 24 * 3600);
    final lightYears = distanceLY;

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.language, color: AppTheme.primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planet.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${distanceLY.toStringAsFixed(1)} light-years away',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Travel Time with Current Technology:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildTravelOption(
              '🛸 Voyager 1',
              '17 km/s',
              voyagerYears,
              Colors.blue,
            ),
            _buildTravelOption(
              '🚀 New Horizons',
              '16.3 km/s',
              newHorizonsYears,
              Colors.purple,
            ),
            _buildTravelOption(
              '☀️ Parker Solar Probe',
              '163 km/s (peak)',
              parkerYears,
              Colors.orange,
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildTravelOption(
              '💡 Speed of Light',
              '299,792 km/s',
              lightYears,
              Colors.amber,
              isLight: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Even at light speed, it would take ${lightYears.toStringAsFixed(1)} years!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelOption(
    String name,
    String speed,
    double years,
    Color color, {
    bool isLight = false,
  }) {
    String timeString;
    if (years > 1e9) {
      timeString = '${(years / 1e9).toStringAsFixed(1)} billion years';
    } else if (years > 1e6) {
      timeString = '${(years / 1e6).toStringAsFixed(1)} million years';
    } else if (years > 1000) {
      timeString = '${(years / 1000).toStringAsFixed(1)}k years';
    } else {
      timeString = '${years.toStringAsFixed(0)} years';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.3)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  speed,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
            ),
            child: Text(
              timeString,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 3: LIGHT TRAVEL TIME
  // ============================================================
  Widget _buildLightTravelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _selectedPlanets.where((p) => p.name != 'Earth').map((
          planet,
        ) {
          return _buildLightTravelCard(planet);
        }).toList(),
      ),
    );
  }

  Widget _buildLightTravelCard(Planet planet) {
    final distanceLY = (planet.distanceFromEarth ?? 0) * 3.26156;
    final yearsAgo = distanceLY.round();
    final yearOnEarth = DateTime.now().year - yearsAgo;

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planet.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Looking back in time',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.1),
                    const Color(0xFFFFA500).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFFFFD700),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Light left this planet',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$yearsAgo years ago',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Around the year $yearOnEarth on Earth',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildHistoricalContext(yearOnEarth),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalContext(int year) {
    String event = _getHistoricalEvent(year);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu, color: Color(0xFF667eea), size: 24),
              const SizedBox(width: 8),
              const Text(
                'What was happening on Earth?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getHistoricalEvent(int year) {
    if (year > 2000) return 'The modern internet era, smartphones everywhere';
    if (year > 1990) return 'The World Wide Web was invented';
    if (year > 1969) return 'Humans walked on the Moon';
    if (year > 1945) return 'World War II had just ended';
    if (year > 1900) return 'The age of automobiles and aviation began';
    if (year > 1800)
      return 'The Industrial Revolution was transforming society';
    if (year > 1700) return 'The Age of Enlightenment and scientific discovery';
    if (year > 1500) return 'Renaissance period, Da Vinci and Michelangelo';
    if (year > 1000) return 'Medieval period, castles and knights';
    if (year > 0) return 'Ancient Roman Empire dominated Europe';
    if (year > -500) return 'Classical Greece, philosophy and democracy';
    if (year > -3000) return 'Egyptian pyramids were being built';
    return 'Dawn of human civilization';
  }

  // ============================================================
  // HELPERS
  // ============================================================
  LinearGradient _getPlanetGradient(Planet planet) {
    if (planet.name == 'Earth') {
      return const LinearGradient(
        colors: [Color(0xFF0984E3), Color(0xFF006994)],
      );
    }

    final temp = planet.equilibriumTemperature ?? 285;
    if (temp > 1000) {
      return const LinearGradient(
        colors: [Color(0xFFFF4500), Color(0xFFFF6347)],
      );
    } else if (temp > 500) {
      return const LinearGradient(
        colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
      );
    } else if (temp < 150) {
      return const LinearGradient(
        colors: [Color(0xFFB0E0E6), Color(0xFFF0F8FF)],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
      );
    }
  }

  void _addPlanetDialog() {
    // TODO: Implement planet selection dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Planet selection coming soon!')),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text(
          'About Planet Comparison',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Compare exoplanets side-by-side, calculate travel times with '
          'different spacecraft, and see how long light takes to reach us.\n\n'
          'Inspired by NASA Eyes on Exoplanets.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
