/// AstroSynth Constants
/// Contains all app-wide constants including API endpoints, theme values, and configuration
library;

class AppConstants {
  // App Information
  static const String appName = 'AstroSynth';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'AI-Driven Exoplanet Ecosystem Simulator';

  // NASA API Configuration
  static const String nasaApiBaseUrl =
      'https://exoplanetarchive.ipac.caltech.edu/TAP/sync';
  static const String nasaApiFormat = 'json';
  static const int nasaApiTimeout = 30; // seconds
  static const int nasaApiMaxRetries = 3;

  // Database Configuration
  static const String databaseName = 'astrosynth.db';
  static const int databaseVersion = 1;

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCachedPlanets = 1000;

  // Pagination
  static const int planetsPerPage = 20;
  static const int maxPlanetsToLoad = 5600; // Total known exoplanets

  // Habitability Thresholds
  static const double minHabitableTemp = 273.0; // 0°C in Kelvin
  static const double maxHabitableTemp = 373.0; // 100°C in Kelvin
  static const double optimalHabitableTemp = 288.0; // 15°C in Kelvin

  static const double minHabitableRadius = 0.5; // Earth radii
  static const double maxHabitableRadius = 2.5; // Earth radii

  static const double minHabitableFlux = 0.36; // Earth flux units
  static const double maxHabitableFlux = 1.11; // Earth flux units

  // Star Types (Spectral Classes)
  static const List<String> habitableStarTypes = ['F', 'G', 'K', 'M'];
  static const String optimalStarType = 'G'; // Sun-like

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 4.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Image Assets
  static const String placeholderPlanetImage =
      'assets/images/planet_placeholder.png';
  static const String appLogo = 'assets/images/logo.png';

  // Animations
  static const String loadingAnimation = 'assets/animations/loading.json';
  static const String successAnimation = 'assets/animations/success.json';

  // Biome Types
  static const List<String> biomeTypes = [
    'Desert',
    'Ocean',
    'Ice',
    'Volcanic',
    'Tropical',
    'Temperate',
    'Tundra',
    'Barren',
    'Gas Giant',
    'Rocky',
  ];

  // Discovery Methods
  static const List<String> discoveryMethods = [
    'Transit',
    'Radial Velocity',
    'Microlensing',
    'Direct Imaging',
    'Astrometry',
    'Transit Timing Variations',
    'Other',
  ];

  // Filter Options
  static const List<String> sortOptions = [
    'Name',
    'Discovery Year',
    'Distance',
    'Habitability Score',
    'Mass',
    'Radius',
  ];

  // NASA TAP Query Columns
  static const List<String> defaultQueryColumns = [
    'pl_name', // Planet Name
    'hostname', // Host Star Name
    'sy_dist', // Distance (parsecs)
    'pl_orbper', // Orbital Period (days)
    'pl_rade', // Planet Radius (Earth radii)
    'pl_bmasse', // Planet Mass (Earth masses)
    'pl_eqt', // Equilibrium Temperature (K)
    'pl_orbsmax', // Semi-Major Axis (AU)
    'pl_orbeccen', // Eccentricity
    'st_spectype', // Stellar Spectral Type
    'st_teff', // Stellar Effective Temperature (K)
    'st_rad', // Stellar Radius (Solar radii)
    'st_mass', // Stellar Mass (Solar masses)
    'disc_year', // Discovery Year
    'discoverymethod', // Discovery Method
  ];

  // Achievement Thresholds
  static const int explorerBronze = 10; // planets explored
  static const int explorerSilver = 50;
  static const int explorerGold = 100;

  static const int scientistBronze = 5; // planets analyzed
  static const int scientistSilver = 25;
  static const int scientistGold = 50;

  // Gamification
  static const int pointsPerDiscovery = 10;
  static const int pointsPerAnalysis = 25;
  static const int pointsPerShare = 5;
  static const int pointsPerDailyLogin = 3;

  // Social Features
  static const int maxUsernameLength = 20;
  static const int maxBioLength = 200;
  static const int maxCommentLength = 500;

  // AR Feature Configuration
  static const double defaultPlanetScale = 1.0;
  static const double minPlanetScale = 0.5;
  static const double maxPlanetScale = 3.0;

  // Error Messages
  static const String errorNoInternet =
      'No internet connection. Please check your network.';
  static const String errorApiTimeout = 'Request timed out. Please try again.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoPlanetsFound =
      'No planets found matching your criteria.';

  // Success Messages
  static const String successPlanetSaved = 'Planet saved to favorites!';
  static const String successPlanetShared = 'Planet shared successfully!';
  static const String successAnalysisComplete =
      'Habitability analysis complete!';
}
