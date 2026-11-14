import 'package:skill_battles/core/utils/error/app_exception.dart';

/// Returns [json] as a JSON object or throws [ParsingException].
Map<String, dynamic> asJsonObject(Object? json) {
  if (json is Map<String, dynamic>) {
    return json;
  }
  throw const ParsingException('Expected a JSON object.');
}

/// Returns [json] as a list of JSON objects or throws [ParsingException].
List<Map<String, dynamic>> asJsonObjectList(Object? json) {
  if (json is List<Object?>) {
    return json.map(asJsonObject).toList(growable: false);
  }
  throw const ParsingException('Expected a JSON array.');
}
