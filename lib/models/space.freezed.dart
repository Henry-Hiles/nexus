// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'space.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Space {

 Room get roomData; Image? get avatar;
/// Create a copy of Space
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceCopyWith<Space> get copyWith => _$SpaceCopyWithImpl<Space>(this as Space, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Space&&(identical(other.roomData, roomData) || other.roomData == roomData)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}


@override
int get hashCode => Object.hash(runtimeType,roomData,avatar);

@override
String toString() {
  return 'Space(roomData: $roomData, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class $SpaceCopyWith<$Res>  {
  factory $SpaceCopyWith(Space value, $Res Function(Space) _then) = _$SpaceCopyWithImpl;
@useResult
$Res call({
 Room roomData, Image? avatar
});




}
/// @nodoc
class _$SpaceCopyWithImpl<$Res>
    implements $SpaceCopyWith<$Res> {
  _$SpaceCopyWithImpl(this._self, this._then);

  final Space _self;
  final $Res Function(Space) _then;

/// Create a copy of Space
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomData = null,Object? avatar = freezed,}) {
  return _then(_self.copyWith(
roomData: null == roomData ? _self.roomData : roomData // ignore: cast_nullable_to_non_nullable
as Room,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Image?,
  ));
}

}


/// Adds pattern-matching-related methods to [Space].
extension SpacePatterns on Space {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Space value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Space() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Space value)  $default,){
final _that = this;
switch (_that) {
case _Space():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Space value)?  $default,){
final _that = this;
switch (_that) {
case _Space() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Room roomData,  Image? avatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Space() when $default != null:
return $default(_that.roomData,_that.avatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Room roomData,  Image? avatar)  $default,) {final _that = this;
switch (_that) {
case _Space():
return $default(_that.roomData,_that.avatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Room roomData,  Image? avatar)?  $default,) {final _that = this;
switch (_that) {
case _Space() when $default != null:
return $default(_that.roomData,_that.avatar);case _:
  return null;

}
}

}

/// @nodoc


class _Space implements Space {
  const _Space({required this.roomData, required this.avatar});
  

@override final  Room roomData;
@override final  Image? avatar;

/// Create a copy of Space
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceCopyWith<_Space> get copyWith => __$SpaceCopyWithImpl<_Space>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Space&&(identical(other.roomData, roomData) || other.roomData == roomData)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}


@override
int get hashCode => Object.hash(runtimeType,roomData,avatar);

@override
String toString() {
  return 'Space(roomData: $roomData, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class _$SpaceCopyWith<$Res> implements $SpaceCopyWith<$Res> {
  factory _$SpaceCopyWith(_Space value, $Res Function(_Space) _then) = __$SpaceCopyWithImpl;
@override @useResult
$Res call({
 Room roomData, Image? avatar
});




}
/// @nodoc
class __$SpaceCopyWithImpl<$Res>
    implements _$SpaceCopyWith<$Res> {
  __$SpaceCopyWithImpl(this._self, this._then);

  final _Space _self;
  final $Res Function(_Space) _then;

/// Create a copy of Space
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomData = null,Object? avatar = freezed,}) {
  return _then(_Space(
roomData: null == roomData ? _self.roomData : roomData // ignore: cast_nullable_to_non_nullable
as Room,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Image?,
  ));
}


}

// dart format on
