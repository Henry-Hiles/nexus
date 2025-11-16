// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'homeserver.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Homeserver {

 String get name; String get description; Uri get url; String get iconUrl;
/// Create a copy of Homeserver
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeserverCopyWith<Homeserver> get copyWith => _$HomeserverCopyWithImpl<Homeserver>(this as Homeserver, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Homeserver&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,url,iconUrl);

@override
String toString() {
  return 'Homeserver(name: $name, description: $description, url: $url, iconUrl: $iconUrl)';
}


}

/// @nodoc
abstract mixin class $HomeserverCopyWith<$Res>  {
  factory $HomeserverCopyWith(Homeserver value, $Res Function(Homeserver) _then) = _$HomeserverCopyWithImpl;
@useResult
$Res call({
 String name, String description, Uri url, String iconUrl
});




}
/// @nodoc
class _$HomeserverCopyWithImpl<$Res>
    implements $HomeserverCopyWith<$Res> {
  _$HomeserverCopyWithImpl(this._self, this._then);

  final Homeserver _self;
  final $Res Function(Homeserver) _then;

/// Create a copy of Homeserver
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? description = null,Object? url = null,Object? iconUrl = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,iconUrl: null == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Homeserver].
extension HomeserverPatterns on Homeserver {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Homeserver value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Homeserver() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Homeserver value)  $default,){
final _that = this;
switch (_that) {
case _Homeserver():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Homeserver value)?  $default,){
final _that = this;
switch (_that) {
case _Homeserver() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String description,  Uri url,  String iconUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Homeserver() when $default != null:
return $default(_that.name,_that.description,_that.url,_that.iconUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String description,  Uri url,  String iconUrl)  $default,) {final _that = this;
switch (_that) {
case _Homeserver():
return $default(_that.name,_that.description,_that.url,_that.iconUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String description,  Uri url,  String iconUrl)?  $default,) {final _that = this;
switch (_that) {
case _Homeserver() when $default != null:
return $default(_that.name,_that.description,_that.url,_that.iconUrl);case _:
  return null;

}
}

}

/// @nodoc


class _Homeserver implements Homeserver {
  const _Homeserver({required this.name, required this.description, required this.url, required this.iconUrl});
  

@override final  String name;
@override final  String description;
@override final  Uri url;
@override final  String iconUrl;

/// Create a copy of Homeserver
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeserverCopyWith<_Homeserver> get copyWith => __$HomeserverCopyWithImpl<_Homeserver>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Homeserver&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.url, url) || other.url == url)&&(identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,url,iconUrl);

@override
String toString() {
  return 'Homeserver(name: $name, description: $description, url: $url, iconUrl: $iconUrl)';
}


}

/// @nodoc
abstract mixin class _$HomeserverCopyWith<$Res> implements $HomeserverCopyWith<$Res> {
  factory _$HomeserverCopyWith(_Homeserver value, $Res Function(_Homeserver) _then) = __$HomeserverCopyWithImpl;
@override @useResult
$Res call({
 String name, String description, Uri url, String iconUrl
});




}
/// @nodoc
class __$HomeserverCopyWithImpl<$Res>
    implements _$HomeserverCopyWith<$Res> {
  __$HomeserverCopyWithImpl(this._self, this._then);

  final _Homeserver _self;
  final $Res Function(_Homeserver) _then;

/// Create a copy of Homeserver
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = null,Object? url = null,Object? iconUrl = null,}) {
  return _then(_Homeserver(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Uri,iconUrl: null == iconUrl ? _self.iconUrl : iconUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
