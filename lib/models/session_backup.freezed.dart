// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_backup.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionBackup {

 String get accessToken; Uri get homeserver; String get userID; String get deviceID; String get deviceName;
/// Create a copy of SessionBackup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionBackupCopyWith<SessionBackup> get copyWith => _$SessionBackupCopyWithImpl<SessionBackup>(this as SessionBackup, _$identity);

  /// Serializes this SessionBackup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionBackup&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.homeserver, homeserver) || other.homeserver == homeserver)&&(identical(other.userID, userID) || other.userID == userID)&&(identical(other.deviceID, deviceID) || other.deviceID == deviceID)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,homeserver,userID,deviceID,deviceName);

@override
String toString() {
  return 'SessionBackup(accessToken: $accessToken, homeserver: $homeserver, userID: $userID, deviceID: $deviceID, deviceName: $deviceName)';
}


}

/// @nodoc
abstract mixin class $SessionBackupCopyWith<$Res>  {
  factory $SessionBackupCopyWith(SessionBackup value, $Res Function(SessionBackup) _then) = _$SessionBackupCopyWithImpl;
@useResult
$Res call({
 String accessToken, Uri homeserver, String userID, String deviceID, String deviceName
});




}
/// @nodoc
class _$SessionBackupCopyWithImpl<$Res>
    implements $SessionBackupCopyWith<$Res> {
  _$SessionBackupCopyWithImpl(this._self, this._then);

  final SessionBackup _self;
  final $Res Function(SessionBackup) _then;

/// Create a copy of SessionBackup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? homeserver = null,Object? userID = null,Object? deviceID = null,Object? deviceName = null,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,homeserver: null == homeserver ? _self.homeserver : homeserver // ignore: cast_nullable_to_non_nullable
as Uri,userID: null == userID ? _self.userID : userID // ignore: cast_nullable_to_non_nullable
as String,deviceID: null == deviceID ? _self.deviceID : deviceID // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionBackup].
extension SessionBackupPatterns on SessionBackup {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionBackup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionBackup() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionBackup value)  $default,){
final _that = this;
switch (_that) {
case _SessionBackup():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionBackup value)?  $default,){
final _that = this;
switch (_that) {
case _SessionBackup() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  Uri homeserver,  String userID,  String deviceID,  String deviceName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionBackup() when $default != null:
return $default(_that.accessToken,_that.homeserver,_that.userID,_that.deviceID,_that.deviceName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  Uri homeserver,  String userID,  String deviceID,  String deviceName)  $default,) {final _that = this;
switch (_that) {
case _SessionBackup():
return $default(_that.accessToken,_that.homeserver,_that.userID,_that.deviceID,_that.deviceName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  Uri homeserver,  String userID,  String deviceID,  String deviceName)?  $default,) {final _that = this;
switch (_that) {
case _SessionBackup() when $default != null:
return $default(_that.accessToken,_that.homeserver,_that.userID,_that.deviceID,_that.deviceName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SessionBackup implements SessionBackup {
  const _SessionBackup({required this.accessToken, required this.homeserver, required this.userID, required this.deviceID, required this.deviceName});
  factory _SessionBackup.fromJson(Map<String, dynamic> json) => _$SessionBackupFromJson(json);

@override final  String accessToken;
@override final  Uri homeserver;
@override final  String userID;
@override final  String deviceID;
@override final  String deviceName;

/// Create a copy of SessionBackup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionBackupCopyWith<_SessionBackup> get copyWith => __$SessionBackupCopyWithImpl<_SessionBackup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionBackupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionBackup&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.homeserver, homeserver) || other.homeserver == homeserver)&&(identical(other.userID, userID) || other.userID == userID)&&(identical(other.deviceID, deviceID) || other.deviceID == deviceID)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,homeserver,userID,deviceID,deviceName);

@override
String toString() {
  return 'SessionBackup(accessToken: $accessToken, homeserver: $homeserver, userID: $userID, deviceID: $deviceID, deviceName: $deviceName)';
}


}

/// @nodoc
abstract mixin class _$SessionBackupCopyWith<$Res> implements $SessionBackupCopyWith<$Res> {
  factory _$SessionBackupCopyWith(_SessionBackup value, $Res Function(_SessionBackup) _then) = __$SessionBackupCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, Uri homeserver, String userID, String deviceID, String deviceName
});




}
/// @nodoc
class __$SessionBackupCopyWithImpl<$Res>
    implements _$SessionBackupCopyWith<$Res> {
  __$SessionBackupCopyWithImpl(this._self, this._then);

  final _SessionBackup _self;
  final $Res Function(_SessionBackup) _then;

/// Create a copy of SessionBackup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? homeserver = null,Object? userID = null,Object? deviceID = null,Object? deviceName = null,}) {
  return _then(_SessionBackup(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,homeserver: null == homeserver ? _self.homeserver : homeserver // ignore: cast_nullable_to_non_nullable
as Uri,userID: null == userID ? _self.userID : userID // ignore: cast_nullable_to_non_nullable
as String,deviceID: null == deviceID ? _self.deviceID : deviceID // ignore: cast_nullable_to_non_nullable
as String,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
