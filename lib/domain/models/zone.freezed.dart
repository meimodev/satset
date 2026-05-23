// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'zone.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Zone {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get short => throw _privateConstructorUsedError;

  /// 0xAARRGGBB hex. UI wraps this in `Color(...)`.
  int get colorHex => throw _privateConstructorUsedError;

  /// Stable key (e.g. `tableRestaurant`). UI maps it to an `IconData`.
  String get iconKey => throw _privateConstructorUsedError;

  /// Create a copy of Zone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ZoneCopyWith<Zone> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ZoneCopyWith<$Res> {
  factory $ZoneCopyWith(Zone value, $Res Function(Zone) then) =
      _$ZoneCopyWithImpl<$Res, Zone>;
  @useResult
  $Res call({
    String id,
    String name,
    String short,
    int colorHex,
    String iconKey,
  });
}

/// @nodoc
class _$ZoneCopyWithImpl<$Res, $Val extends Zone>
    implements $ZoneCopyWith<$Res> {
  _$ZoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Zone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? short = null,
    Object? colorHex = null,
    Object? iconKey = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            short: null == short
                ? _value.short
                : short // ignore: cast_nullable_to_non_nullable
                      as String,
            colorHex: null == colorHex
                ? _value.colorHex
                : colorHex // ignore: cast_nullable_to_non_nullable
                      as int,
            iconKey: null == iconKey
                ? _value.iconKey
                : iconKey // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ZoneImplCopyWith<$Res> implements $ZoneCopyWith<$Res> {
  factory _$$ZoneImplCopyWith(
    _$ZoneImpl value,
    $Res Function(_$ZoneImpl) then,
  ) = __$$ZoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String short,
    int colorHex,
    String iconKey,
  });
}

/// @nodoc
class __$$ZoneImplCopyWithImpl<$Res>
    extends _$ZoneCopyWithImpl<$Res, _$ZoneImpl>
    implements _$$ZoneImplCopyWith<$Res> {
  __$$ZoneImplCopyWithImpl(_$ZoneImpl _value, $Res Function(_$ZoneImpl) _then)
    : super(_value, _then);

  /// Create a copy of Zone
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? short = null,
    Object? colorHex = null,
    Object? iconKey = null,
  }) {
    return _then(
      _$ZoneImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        short: null == short
            ? _value.short
            : short // ignore: cast_nullable_to_non_nullable
                  as String,
        colorHex: null == colorHex
            ? _value.colorHex
            : colorHex // ignore: cast_nullable_to_non_nullable
                  as int,
        iconKey: null == iconKey
            ? _value.iconKey
            : iconKey // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ZoneImpl implements _Zone {
  const _$ZoneImpl({
    required this.id,
    required this.name,
    required this.short,
    this.colorHex = 0xFFFF9233,
    this.iconKey = 'tableRestaurant',
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String short;

  /// 0xAARRGGBB hex. UI wraps this in `Color(...)`.
  @override
  @JsonKey()
  final int colorHex;

  /// Stable key (e.g. `tableRestaurant`). UI maps it to an `IconData`.
  @override
  @JsonKey()
  final String iconKey;

  @override
  String toString() {
    return 'Zone(id: $id, name: $name, short: $short, colorHex: $colorHex, iconKey: $iconKey)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ZoneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.short, short) || other.short == short) &&
            (identical(other.colorHex, colorHex) ||
                other.colorHex == colorHex) &&
            (identical(other.iconKey, iconKey) || other.iconKey == iconKey));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, short, colorHex, iconKey);

  /// Create a copy of Zone
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ZoneImplCopyWith<_$ZoneImpl> get copyWith =>
      __$$ZoneImplCopyWithImpl<_$ZoneImpl>(this, _$identity);
}

abstract class _Zone implements Zone {
  const factory _Zone({
    required final String id,
    required final String name,
    required final String short,
    final int colorHex,
    final String iconKey,
  }) = _$ZoneImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get short;

  /// 0xAARRGGBB hex. UI wraps this in `Color(...)`.
  @override
  int get colorHex;

  /// Stable key (e.g. `tableRestaurant`). UI maps it to an `IconData`.
  @override
  String get iconKey;

  /// Create a copy of Zone
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ZoneImplCopyWith<_$ZoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
