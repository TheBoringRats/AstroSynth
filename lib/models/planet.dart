import 'package:json_annotation/json_annotation.dart';

part 'planet.g.dart';

/// Represents an exoplanet with all its properties from NASA data
@JsonSerializable(explicitToJson: true)
class Planet {
  @JsonKey(name: 'pl_name')
  final String name;

  @JsonKey(name: 'hostname')
  final String? hostStarName;

  @JsonKey(name: 'sy_dist')
  final double? distanceFromEarth; // in parsecs

  @JsonKey(name: 'pl_orbper')
  final double? orbitalPeriod; // in days

  @JsonKey(name: 'pl_rade')
  final double? radius; // in Earth radii

  @JsonKey(name: 'pl_bmasse')
  final double? mass; // in Earth masses

  @JsonKey(name: 'pl_eqt')
  final double? equilibriumTemperature; // in Kelvin

  @JsonKey(name: 'pl_orbsmax')
  final double? semiMajorAxis; // in AU

  @JsonKey(name: 'pl_orbeccen')
  final double? eccentricity;

  @JsonKey(name: 'st_spectype')
  final String? stellarSpectralType;

  @JsonKey(name: 'st_teff')
  final double? stellarTemperature; // in Kelvin

  @JsonKey(name: 'st_rad')
  final double? stellarRadius; // in Solar radii

  @JsonKey(name: 'st_mass')
  final double? stellarMass; // in Solar masses

  @JsonKey(name: 'disc_year')
  final int? discoveryYear;

  @JsonKey(name: 'discoverymethod')
  final String? discoveryMethod;

  // Calculated fields (not from NASA API)
  @JsonKey(includeFromJson: false, includeToJson: false)
  double? habitabilityScore;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? biomeType;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isFavorite;

  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime? lastUpdated;

  Planet({
    required this.name,
    this.hostStarName,
    this.distanceFromEarth,
    this.orbitalPeriod,
    this.radius,
    this.mass,
    this.equilibriumTemperature,
    this.semiMajorAxis,
    this.eccentricity,
    this.stellarSpectralType,
    this.stellarTemperature,
    this.stellarRadius,
    this.stellarMass,
    this.discoveryYear,
    this.discoveryMethod,
    this.habitabilityScore,
    this.biomeType,
    this.isFavorite = false,
    this.lastUpdated,
  });

  /// Creates a Planet from JSON
  factory Planet.fromJson(Map<String, dynamic> json) => _$PlanetFromJson(json);

  /// Converts Planet to JSON
  Map<String, dynamic> toJson() => _$PlanetToJson(this);

  /// Creates a copy with updated fields
  Planet copyWith({
    String? name,
    String? hostStarName,
    double? distanceFromEarth,
    double? orbitalPeriod,
    double? radius,
    double? mass,
    double? equilibriumTemperature,
    double? semiMajorAxis,
    double? eccentricity,
    String? stellarSpectralType,
    double? stellarTemperature,
    double? stellarRadius,
    double? stellarMass,
    int? discoveryYear,
    String? discoveryMethod,
    double? habitabilityScore,
    String? biomeType,
    bool? isFavorite,
    DateTime? lastUpdated,
  }) {
    return Planet(
      name: name ?? this.name,
      hostStarName: hostStarName ?? this.hostStarName,
      distanceFromEarth: distanceFromEarth ?? this.distanceFromEarth,
      orbitalPeriod: orbitalPeriod ?? this.orbitalPeriod,
      radius: radius ?? this.radius,
      mass: mass ?? this.mass,
      equilibriumTemperature:
          equilibriumTemperature ?? this.equilibriumTemperature,
      semiMajorAxis: semiMajorAxis ?? this.semiMajorAxis,
      eccentricity: eccentricity ?? this.eccentricity,
      stellarSpectralType: stellarSpectralType ?? this.stellarSpectralType,
      stellarTemperature: stellarTemperature ?? this.stellarTemperature,
      stellarRadius: stellarRadius ?? this.stellarRadius,
      stellarMass: stellarMass ?? this.stellarMass,
      discoveryYear: discoveryYear ?? this.discoveryYear,
      discoveryMethod: discoveryMethod ?? this.discoveryMethod,
      habitabilityScore: habitabilityScore ?? this.habitabilityScore,
      biomeType: biomeType ?? this.biomeType,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Converts to database map
  Map<String, dynamic> toDatabase() {
    return {
      'name': name,
      'host_star_name': hostStarName,
      'distance_from_earth': distanceFromEarth,
      'orbital_period': orbitalPeriod,
      'radius': radius,
      'mass': mass,
      'equilibrium_temperature': equilibriumTemperature,
      'semi_major_axis': semiMajorAxis,
      'eccentricity': eccentricity,
      'stellar_spectral_type': stellarSpectralType,
      'stellar_temperature': stellarTemperature,
      'stellar_radius': stellarRadius,
      'stellar_mass': stellarMass,
      'discovery_year': discoveryYear,
      'discovery_method': discoveryMethod,
      'habitability_score': habitabilityScore,
      'biome_type': biomeType,
      'is_favorite': isFavorite ? 1 : 0,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  /// Creates from database map
  factory Planet.fromDatabase(Map<String, dynamic> map) {
    return Planet(
      name: map['name'] as String,
      hostStarName: map['host_star_name'] as String?,
      distanceFromEarth: map['distance_from_earth'] as double?,
      orbitalPeriod: map['orbital_period'] as double?,
      radius: map['radius'] as double?,
      mass: map['mass'] as double?,
      equilibriumTemperature: map['equilibrium_temperature'] as double?,
      semiMajorAxis: map['semi_major_axis'] as double?,
      eccentricity: map['eccentricity'] as double?,
      stellarSpectralType: map['stellar_spectral_type'] as String?,
      stellarTemperature: map['stellar_temperature'] as double?,
      stellarRadius: map['stellar_radius'] as double?,
      stellarMass: map['stellar_mass'] as double?,
      discoveryYear: map['discovery_year'] as int?,
      discoveryMethod: map['discovery_method'] as String?,
      habitabilityScore: map['habitability_score'] as double?,
      biomeType: map['biome_type'] as String?,
      isFavorite: (map['is_favorite'] as int?) == 1,
      lastUpdated: map['last_updated'] != null
          ? DateTime.parse(map['last_updated'] as String)
          : null,
    );
  }

  /// Get display name for the planet
  String get displayName => name;

  /// Get distance in light years
  double? get distanceInLightYears {
    if (distanceFromEarth == null) return null;
    return distanceFromEarth! * 3.26156; // 1 parsec = 3.26156 light years
  }

  /// Check if planet has sufficient data for analysis
  bool get hasSufficientData {
    return radius != null &&
        equilibriumTemperature != null &&
        stellarSpectralType != null;
  }

  /// Get habitability category
  String get habitabilityCategory {
    if (habitabilityScore == null) return 'Unknown';
    if (habitabilityScore! >= 70) return 'High';
    if (habitabilityScore! >= 40) return 'Medium';
    return 'Low';
  }

  @override
  String toString() {
    return 'Planet(name: $name, habitabilityScore: $habitabilityScore, biome: $biomeType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Planet && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}
