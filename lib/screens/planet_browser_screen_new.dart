import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../models/planet.dart';
import '../providers/filter_provider.dart';
import '../providers/planet_provider.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/planet_card.dart';
import 'planet_detail_screen.dart';

/// Main screen for browsing and searching exoplanets with Provider state management
class PlanetBrowserScreen extends StatefulWidget {
  const PlanetBrowserScreen({super.key});

  @override
  State<PlanetBrowserScreen> createState() => _PlanetBrowserScreenState();
}

class _PlanetBrowserScreenState extends State<PlanetBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load planets on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final planetProvider = Provider.of<PlanetProvider>(
        context,
        listen: false,
      );
      if (planetProvider.isEmpty && !planetProvider.isLoading) {
        _loadPlanets();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlanets() async {
    final planetProvider = Provider.of<PlanetProvider>(context, listen: false);
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);

    // Load based on selected filter
    switch (filterProvider.selectedFilter) {
      case 'Favorites':
        // Load all planets if not loaded, then apply filter
        if (planetProvider.isEmpty) {
          await planetProvider.fetchPlanets();
        }
        planetProvider.applyLocalFilter(showFavoritesOnly: true);
        break;
      case 'Habitable':
        await planetProvider.fetchHabitablePlanets();
        break;
      case 'Recent':
        await planetProvider.fetchRecentDiscoveries();
        break;
      case 'Nearby':
        await planetProvider.fetchPlanetsInRange(
          minDistance: 0,
          maxDistance: 100,
        );
        break;
      case 'G-Type Stars':
        await planetProvider.fetchPlanetsByStarType(starType: 'G');
        break;
      default:
        await planetProvider.fetchPlanets();
    }

    // Apply sorting
    planetProvider.sortPlanets(
      filterProvider.sortBy,
      ascending: filterProvider.sortAscending,
    );
  }

  void _searchPlanets(String query) {
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    filterProvider.setSearchQuery(query);

    if (query.isEmpty) {
      _loadPlanets();
    } else {
      final planetProvider = Provider.of<PlanetProvider>(
        context,
        listen: false,
      );
      planetProvider.searchPlanets(query);
      final filterProv = Provider.of<FilterProvider>(context, listen: false);
      planetProvider.sortPlanets(
        filterProv.sortBy,
        ascending: filterProv.sortAscending,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlanetProvider, FilterProvider>(
      builder: (context, planetProvider, filterProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Exoplanet Explorer'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showInfoDialog(planetProvider.totalCount),
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.spaceBackgroundGradient,
            ),
            child: Column(
              children: [
                _buildSearchBar(),
                _buildFilterChips(filterProvider),
                _buildSortOptions(filterProvider, planetProvider),
                Expanded(child: _buildPlanetGrid(planetProvider)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await planetProvider.refresh();
              planetProvider.sortPlanets(
                filterProvider.sortBy,
                ascending: filterProvider.sortAscending,
              );
            },
            child: const Icon(Icons.refresh),
            tooltip: 'Refresh planets',
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchPlanets,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search planets...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchPlanets('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(FilterProvider filterProvider) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterProvider.availableFilters.length,
        itemBuilder: (context, index) {
          final filter = filterProvider.availableFilters[index];
          final isSelected = filterProvider.selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.smallPadding),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                filterProvider.setFilter(filter);
                _loadPlanets();
              },
              backgroundColor: AppTheme.surfaceColor,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.3),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortOptions(
    FilterProvider filterProvider,
    PlanetProvider planetProvider,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: Row(
        children: [
          const Text(
            'Sort by:',
            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultBorderRadius,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filterProvider.sortBy,
                  dropdownColor: AppTheme.cardBackground,
                  isExpanded: true,
                  items: filterProvider.availableSortOptions.map((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    if (value != null) {
                      filterProvider.setSortBy(value);
                      planetProvider.sortPlanets(
                        value,
                        ascending: filterProvider.sortAscending,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${planetProvider.filteredPlanets.length} planets',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetGrid(PlanetProvider planetProvider) {
    if (planetProvider.isLoading) {
      return const LoadingShimmer();
    }

    if (planetProvider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 16),
            Text(
              planetProvider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadPlanets, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (planetProvider.filteredPlanets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No planets found',
              style: TextStyle(
                color: AppTheme.textSecondaryColor.withValues(alpha: 0.7),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search query',
              style: TextStyle(
                color: AppTheme.textSecondaryColor.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.75,
        crossAxisSpacing: AppConstants.defaultPadding,
        mainAxisSpacing: AppConstants.defaultPadding,
      ),
      itemCount: planetProvider.filteredPlanets.length,
      itemBuilder: (context, index) {
        final planet = planetProvider.filteredPlanets[index];
        return PlanetCard(
          planet: planet,
          onTap: () => _navigateToPlanetDetail(planet),
          onFavoriteToggle: () => _toggleFavorite(planet, planetProvider),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    return 2;
  }

  Future<void> _toggleFavorite(
    Planet planet,
    PlanetProvider planetProvider,
  ) async {
    final isFavorite = await planetProvider.toggleFavorite(planet.name);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite
                ? '${planet.displayName} added to favorites'
                : '${planet.displayName} removed from favorites',
          ),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => planetProvider.toggleFavorite(planet.name),
          ),
        ),
      );
    }
  }

  void _navigateToPlanetDetail(Planet planet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanetDetailScreen(planet: planet),
      ),
    );
  }

  void _showInfoDialog(int totalCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.public,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About AstroSynth'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Explore $totalCount confirmed exoplanets from NASA\'s Exoplanet Archive.',
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.science,
                'Habitability Scoring',
                'Advanced algorithms analyze temperature, size, orbit, and stellar characteristics.',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.terrain,
                'Biome Classification',
                'Planets are categorized into 10 unique biome types based on physical properties.',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.filter_alt,
                'Smart Filtering',
                'Filter by habitability, distance, star type, and more.',
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.dividerColor),
              const SizedBox(height: 8),
              const Text(
                'Data Source: NASA Exoplanet Archive',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
