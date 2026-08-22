// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';
import 'package:drift/internal/migrations.dart';
import 'schema_v62.dart' as v62;
import 'schema_v63.dart' as v63;

class GeneratedHelper implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version) {
    switch (version) {
      case 62:
        return v62.DatabaseAtV62(db);
      case 63:
        return v63.DatabaseAtV63(db);
      default:
        throw MissingSchemaException(version, versions);
    }
  }

  static const versions = const [62, 63];
}
