import 'package:flutter/foundation.dart';

/// Manages the filter and search state for the planet browser
///
/// Handles search queries, filter selections, and sort options,
/// providing reactive updates to the UI.
class FilterProvider with ChangeNotifier {
  // Search state
  String _searchQuery = '';

  // Filter state
  String _selectedFilter = 'All';
  final List<String> _availableFilters = [
    'All',
    'Favorites',
    'Habitable',
    'Recent',
    'Nearby',
    'G-Type Stars',
  ];

  // Sort state
  String _sortBy = 'Name';
  bool _sortAscending = true;
  final List<String> _availableSortOptions = [
    'Name',
    'Year',
    'Distance',
    'Habitability',
    'Mass',
    'Radius',
  ];

  // Additional filter criteria
  double? _minHabitability;
  double? _maxDistance;
  String? _biomeType;
  int? _minYear;
  int? _maxYear;

  // Getters
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  List<String> get availableFilters => _availableFilters;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  List<String> get availableSortOptions => _availableSortOptions;
  double? get minHabitability => _minHabitability;
  double? get maxDistance => _maxDistance;
  String? get biomeType => _biomeType;
  int? get minYear => _minYear;
  int? get maxYear => _maxYear;

  // Computed properties
  bool get hasActiveFilters =>
      _selectedFilter != 'All' ||
      _searchQuery.isNotEmpty ||
      _minHabitability != null ||
      _maxDistance != null ||
      _biomeType != null ||
      _minYear != null ||
      _maxYear != null;

  bool get isFilteringFavorites => _selectedFilter == 'Favorites';
  bool get isFilteringHabitable => _selectedFilter == 'Habitable';
  bool get isFilteringRecent => _selectedFilter == 'Recent';
  bool get isFilteringNearby => _selectedFilter == 'Nearby';
  bool get isFilteringGType => _selectedFilter == 'G-Type Stars';

  /// Update search query
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  /// Clear search query
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  /// Set selected filter
  void setFilter(String filter) {
    if (_availableFilters.contains(filter) && _selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  /// Clear filter (set to 'All')
  void clearFilter() {
    if (_selectedFilter != 'All') {
      _selectedFilter = 'All';
      notifyListeners();
    }
  }

  /// Set sort criteria
  void setSortBy(String sortBy, {bool? ascending}) {
    bool changed = false;

    if (_availableSortOptions.contains(sortBy) && _sortBy != sortBy) {
      _sortBy = sortBy;
      changed = true;
    }

    if (ascending != null && _sortAscending != ascending) {
      _sortAscending = ascending;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Toggle sort direction
  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
    notifyListeners();
  }

  /// Set minimum habitability filter
  void setMinHabitability(double? value) {
    if (_minHabitability != value) {
      _minHabitability = value;
      notifyListeners();
    }
  }

  /// Set maximum distance filter
  void setMaxDistance(double? value) {
    if (_maxDistance != value) {
      _maxDistance = value;
      notifyListeners();
    }
  }

  /// Set biome type filter
  void setBiomeType(String? value) {
    if (_biomeType != value) {
      _biomeType = value;
      notifyListeners();
    }
  }

  /// Set year range filter
  void setYearRange({int? minYear, int? maxYear}) {
    bool changed = false;

    if (_minYear != minYear) {
      _minYear = minYear;
      changed = true;
    }

    if (_maxYear != maxYear) {
      _maxYear = maxYear;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Clear all advanced filters
  void clearAdvancedFilters() {
    bool changed = false;

    if (_minHabitability != null) {
      _minHabitability = null;
      changed = true;
    }

    if (_maxDistance != null) {
      _maxDistance = null;
      changed = true;
    }

    if (_biomeType != null) {
      _biomeType = null;
      changed = true;
    }

    if (_minYear != null || _maxYear != null) {
      _minYear = null;
      _maxYear = null;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Clear all filters and search
  void clearAll() {
    bool changed = false;

    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      changed = true;
    }

    if (_selectedFilter != 'All') {
      _selectedFilter = 'All';
      changed = true;
    }

    if (_minHabitability != null ||
        _maxDistance != null ||
        _biomeType != null ||
        _minYear != null ||
        _maxYear != null) {
      _minHabitability = null;
      _maxDistance = null;
      _biomeType = null;
      _minYear = null;
      _maxYear = null;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Reset sort to default
  void resetSort() {
    bool changed = false;

    if (_sortBy != 'Name') {
      _sortBy = 'Name';
      changed = true;
    }

    if (!_sortAscending) {
      _sortAscending = true;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Get a summary of active filters
  Map<String, dynamic> getFilterSummary() {
    return {
      'searchQuery': _searchQuery,
      'selectedFilter': _selectedFilter,
      'sortBy': _sortBy,
      'sortAscending': _sortAscending,
      'minHabitability': _minHabitability,
      'maxDistance': _maxDistance,
      'biomeType': _biomeType,
      'minYear': _minYear,
      'maxYear': _maxYear,
      'hasActiveFilters': hasActiveFilters,
    };
  }

  /// Apply a preset filter configuration
  void applyPreset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'habitable':
        _selectedFilter = 'Habitable';
        _minHabitability = 50.0;
        _sortBy = 'Habitability';
        _sortAscending = false;
        break;

      case 'nearby':
        _selectedFilter = 'Nearby';
        _maxDistance = 100.0; // 100 parsecs
        _sortBy = 'Distance';
        _sortAscending = true;
        break;

      case 'recent':
        _selectedFilter = 'Recent';
        _minYear = DateTime.now().year - 5;
        _sortBy = 'Year';
        _sortAscending = false;
        break;

      case 'favorites':
        _selectedFilter = 'Favorites';
        _sortBy = 'Name';
        _sortAscending = true;
        break;

      case 'g-type':
        _selectedFilter = 'G-Type Stars';
        _sortBy = 'Habitability';
        _sortAscending = false;
        break;

      default:
        clearAll();
        return;
    }

    notifyListeners();
  }
}
