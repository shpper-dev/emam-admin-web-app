import 'package:emam_admin_web_app/features/units/models/unit_json.dart';

enum UnitSettingType { choice, boolean, integer, unknown }

/// One entry of the server's settings schema, which the forms are drawn from.
class UnitSettingSpec {
  const UnitSettingSpec({
    required this.key,
    required this.label,
    required this.type,
    required this.help,
    required this.defaultValue,
    this.choices = const [],
    this.min,
    this.max,
  });

  final String key;
  final String label;
  final UnitSettingType type;
  final String help;
  final Object? defaultValue;
  final List<String> choices;
  final int? min;
  final int? max;

  factory UnitSettingSpec.fromJson(String key, Map<dynamic, dynamic> json) {
    final type = switch (json['type']) {
      'choice' => UnitSettingType.choice,
      'bool' => UnitSettingType.boolean,
      'int' => UnitSettingType.integer,
      _ => UnitSettingType.unknown,
    };
    return UnitSettingSpec(
      key: key,
      label: readString(json['label']) ?? key,
      type: type,
      help: readString(json['help']) ?? '',
      defaultValue: json['default'],
      choices: readStrings(json['choices']),
      min: readInt(json['min']),
      max: readInt(json['max']),
    );
  }

  /// Whether the server would take [value] for this setting.
  bool accepts(Object? value) => switch (type) {
    UnitSettingType.choice => value is String && choices.contains(value),
    UnitSettingType.boolean => value is bool,
    UnitSettingType.integer =>
      value is int &&
          (min == null || value >= min!) &&
          (max == null || value <= max!),
    UnitSettingType.unknown => false,
  };
}

/// `GET /api/admin/device-settings`: the fleet-wide values, the schema and
/// the commands the server knows.
class FleetSettings {
  const FleetSettings({
    required this.values,
    required this.schema,
    required this.commands,
  });

  final Map<String, Object?> values;
  final List<UnitSettingSpec> schema;
  final List<String> commands;

  factory FleetSettings.fromJson(Map<dynamic, dynamic> json) {
    final schema = readMap(json['schema']);
    return FleetSettings(
      values: readMap(json['values']),
      schema: [
        for (final entry in schema.entries)
          if (entry.value is Map)
            UnitSettingSpec.fromJson(entry.key, entry.value as Map),
      ],
      commands: readStrings(json['commands']),
    );
  }

  /// The settings the forms can edit; types this panel doesn't know are left
  /// out rather than guessed at.
  List<UnitSettingSpec> get editable => [
    for (final spec in schema)
      if (spec.type != UnitSettingType.unknown) spec,
  ];

  UnitSettingSpec? spec(String key) {
    for (final spec in schema) {
      if (spec.key == key) return spec;
    }
    return null;
  }

  /// What a unit without its own setting uses: the fleet value, else the
  /// built-in default.
  Object? fleetValue(String key) => values[key] ?? spec(key)?.defaultValue;

  /// What [unitSettings] amount to for one unit.
  Object? effectiveValue(String key, Map<String, Object?> unitSettings) =>
      unitSettings[key] ?? fleetValue(key);

  FleetSettings withValues(Map<String, Object?> values) =>
      FleetSettings(values: values, schema: schema, commands: commands);
}
