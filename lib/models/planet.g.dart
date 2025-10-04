// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Planet _$PlanetFromJson(Map<String, dynamic> json) => Planet(
  name: json['pl_name'] as String,
  hostStarName: json['hostname'] as String?,
  distanceFromEarth: (json['sy_dist'] as num?)?.toDouble(),
  orbitalPeriod: (json['pl_orbper'] as num?)?.toDouble(),
  radius: (json['pl_rade'] as num?)?.toDouble(),
  mass: (json['pl_bmasse'] as num?)?.toDouble(),
  equilibriumTemperature: (json['pl_eqt'] as num?)?.toDouble(),
  semiMajorAxis: (json['pl_orbsmax'] as num?)?.toDouble(),
  eccentricity: (json['pl_orbeccen'] as num?)?.toDouble(),
  stellarSpectralType: json['st_spectype'] as String?,
  stellarTemperature: (json['st_teff'] as num?)?.toDouble(),
  stellarRadius: (json['st_rad'] as num?)?.toDouble(),
  stellarMass: (json['st_mass'] as num?)?.toDouble(),
  discoveryYear: (json['disc_year'] as num?)?.toInt(),
  discoveryMethod: json['discoverymethod'] as String?,
);

Map<String, dynamic> _$PlanetToJson(Planet instance) => <String, dynamic>{
  'pl_name': instance.name,
  'hostname': instance.hostStarName,
  'sy_dist': instance.distanceFromEarth,
  'pl_orbper': instance.orbitalPeriod,
  'pl_rade': instance.radius,
  'pl_bmasse': instance.mass,
  'pl_eqt': instance.equilibriumTemperature,
  'pl_orbsmax': instance.semiMajorAxis,
  'pl_orbeccen': instance.eccentricity,
  'st_spectype': instance.stellarSpectralType,
  'st_teff': instance.stellarTemperature,
  'st_rad': instance.stellarRadius,
  'st_mass': instance.stellarMass,
  'disc_year': instance.discoveryYear,
  'discoverymethod': instance.discoveryMethod,
};
