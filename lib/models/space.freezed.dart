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

 String get title; List<FullRoom> get children; Client get client; bool get fake; Uri? get avatar; Icon? get icon;
/// Create a copy of Space
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpaceCopyWith<Space> get copyWith => _$SpaceCopyWithImpl<Space>(this as Space, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Space&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.children, children)&&(identical(other.client, client) || other.client == client)&&(identical(other.fake, fake) || other.fake == fake)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(children),client,fake,avatar,icon);

@override
String toString() {
  return 'Space(title: $title, children: $children, client: $client, fake: $fake, avatar: $avatar, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $SpaceCopyWith<$Res>  {
  factory $SpaceCopyWith(Space value, $Res Function(Space) _then) = _$SpaceCopyWithImpl;
@useResult
$Res call({
 String title, List<FullRoom> children, Client client, bool fake, Uri? avatar, Icon? icon
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
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? children = null,Object? client = null,Object? fake = null,Object? avatar = freezed,Object? icon = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<FullRoom>,client: null == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as Client,fake: null == fake ? _self.fake : fake // ignore: cast_nullable_to_non_nullable
as bool,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Uri?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as Icon?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  List<FullRoom> children,  Client client,  bool fake,  Uri? avatar,  Icon? icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Space() when $default != null:
return $default(_that.title,_that.children,_that.client,_that.fake,_that.avatar,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  List<FullRoom> children,  Client client,  bool fake,  Uri? avatar,  Icon? icon)  $default,) {final _that = this;
switch (_that) {
case _Space():
return $default(_that.title,_that.children,_that.client,_that.fake,_that.avatar,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  List<FullRoom> children,  Client client,  bool fake,  Uri? avatar,  Icon? icon)?  $default,) {final _that = this;
switch (_that) {
case _Space() when $default != null:
return $default(_that.title,_that.children,_that.client,_that.fake,_that.avatar,_that.icon);case _:
  return null;

}
}

}

/// @nodoc


class _Space implements Space {
  const _Space({required this.title, required final  List<FullRoom> children, required this.client, this.fake = false, this.avatar, this.icon}): _children = children;
  

@override final  String title;
 final  List<FullRoom> _children;
@override List<FullRoom> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}

@override final  Client client;
@override@JsonKey() final  bool fake;
@override final  Uri? avatar;
@override final  Icon? icon;

/// Create a copy of Space
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SpaceCopyWith<_Space> get copyWith => __$SpaceCopyWithImpl<_Space>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Space&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._children, _children)&&(identical(other.client, client) || other.client == client)&&(identical(other.fake, fake) || other.fake == fake)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_children),client,fake,avatar,icon);

@override
String toString() {
  return 'Space(title: $title, children: $children, client: $client, fake: $fake, avatar: $avatar, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$SpaceCopyWith<$Res> implements $SpaceCopyWith<$Res> {
  factory _$SpaceCopyWith(_Space value, $Res Function(_Space) _then) = __$SpaceCopyWithImpl;
@override @useResult
$Res call({
 String title, List<FullRoom> children, Client client, bool fake, Uri? avatar, Icon? icon
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
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? children = null,Object? client = null,Object? fake = null,Object? avatar = freezed,Object? icon = freezed,}) {
  return _then(_Space(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<FullRoom>,client: null == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as Client,fake: null == fake ? _self.fake : fake // ignore: cast_nullable_to_non_nullable
as bool,avatar: freezed == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as Uri?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as Icon?,
  ));
}


}

// dart format on
