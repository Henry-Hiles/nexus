// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'full_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FullRoom {

 Room get roomData; String get title; Image? get avatar;
/// Create a copy of FullRoom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FullRoomCopyWith<FullRoom> get copyWith => _$FullRoomCopyWithImpl<FullRoom>(this as FullRoom, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FullRoom&&(identical(other.roomData, roomData) || other.roomData == roomData)&&(identical(other.title, title) || other.title == title)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}


@override
int get hashCode => Object.hash(runtimeType,roomData,title,avatar);

@override
String toString() {
  return 'FullRoom(roomData: $roomData, title: $title, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class $FullRoomCopyWith<$Res>  {
  factory $FullRoomCopyWith(FullRoom value, $Res Function(FullRoom) _then) = _$FullRoomCopyWithImpl;
@useResult
$Res call({
 Room roomData, String title, Image? avatar
});




}
/// @nodoc
class _$FullRoomCopyWithImpl<$Res>
    implements $FullRoomCopyWith<$Res> {
  _$FullRoomCopyWithImpl(this._self, this._then);

  final FullRoom _self;
  final $Res Function(FullRoom) _then;

/// Create a copy of FullRoom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomData = null,Object? title = null,Object? avatar = freezed,}) {
  return _then(_self.copyWith(
roomData: null == roomData ? _self.roomData : roomData // ignore: cast_nullable_to_non_nullable
as Room,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Image?,
  ));
}

}


/// Adds pattern-matching-related methods to [FullRoom].
extension FullRoomPatterns on FullRoom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FullRoom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FullRoom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FullRoom value)  $default,){
final _that = this;
switch (_that) {
case _FullRoom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FullRoom value)?  $default,){
final _that = this;
switch (_that) {
case _FullRoom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Room roomData,  String title,  Image? avatar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FullRoom() when $default != null:
return $default(_that.roomData,_that.title,_that.avatar);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Room roomData,  String title,  Image? avatar)  $default,) {final _that = this;
switch (_that) {
case _FullRoom():
return $default(_that.roomData,_that.title,_that.avatar);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Room roomData,  String title,  Image? avatar)?  $default,) {final _that = this;
switch (_that) {
case _FullRoom() when $default != null:
return $default(_that.roomData,_that.title,_that.avatar);case _:
  return null;

}
}

}

/// @nodoc


class _FullRoom implements FullRoom {
  const _FullRoom({required this.roomData, required this.title, required this.avatar});
  

@override final  Room roomData;
@override final  String title;
@override final  Image? avatar;

/// Create a copy of FullRoom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FullRoomCopyWith<_FullRoom> get copyWith => __$FullRoomCopyWithImpl<_FullRoom>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FullRoom&&(identical(other.roomData, roomData) || other.roomData == roomData)&&(identical(other.title, title) || other.title == title)&&(identical(other.avatar, avatar) || other.avatar == avatar));
}


@override
int get hashCode => Object.hash(runtimeType,roomData,title,avatar);

@override
String toString() {
  return 'FullRoom(roomData: $roomData, title: $title, avatar: $avatar)';
}


}

/// @nodoc
abstract mixin class _$FullRoomCopyWith<$Res> implements $FullRoomCopyWith<$Res> {
  factory _$FullRoomCopyWith(_FullRoom value, $Res Function(_FullRoom) _then) = __$FullRoomCopyWithImpl;
@override @useResult
$Res call({
 Room roomData, String title, Image? avatar
});




}
/// @nodoc
class __$FullRoomCopyWithImpl<$Res>
    implements _$FullRoomCopyWith<$Res> {
  __$FullRoomCopyWithImpl(this._self, this._then);

  final _FullRoom _self;
  final $Res Function(_FullRoom) _then;

/// Create a copy of FullRoom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomData = null,Object? title = null,Object? avatar = freezed,}) {
  return _then(_FullRoom(
roomData: null == roomData ? _self.roomData : roomData // ignore: cast_nullable_to_non_nullable
as Room,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Image?,
  ));
}


}

// dart format on
