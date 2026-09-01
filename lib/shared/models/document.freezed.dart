// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentCreate {

 String get content; String? get title;
/// Create a copy of DocumentCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentCreateCopyWith<DocumentCreate> get copyWith => _$DocumentCreateCopyWithImpl<DocumentCreate>(this as DocumentCreate, _$identity);

  /// Serializes this DocumentCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentCreate&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,title);

@override
String toString() {
  return 'DocumentCreate(content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class $DocumentCreateCopyWith<$Res>  {
  factory $DocumentCreateCopyWith(DocumentCreate value, $Res Function(DocumentCreate) _then) = _$DocumentCreateCopyWithImpl;
@useResult
$Res call({
 String content, String? title
});




}
/// @nodoc
class _$DocumentCreateCopyWithImpl<$Res>
    implements $DocumentCreateCopyWith<$Res> {
  _$DocumentCreateCopyWithImpl(this._self, this._then);

  final DocumentCreate _self;
  final $Res Function(DocumentCreate) _then;

/// Create a copy of DocumentCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? title = freezed,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentCreate].
extension DocumentCreatePatterns on DocumentCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentCreate value)  $default,){
final _that = this;
switch (_that) {
case _DocumentCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentCreate value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String content,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentCreate() when $default != null:
return $default(_that.content,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String content,  String? title)  $default,) {final _that = this;
switch (_that) {
case _DocumentCreate():
return $default(_that.content,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String content,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _DocumentCreate() when $default != null:
return $default(_that.content,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentCreate implements DocumentCreate {
  const _DocumentCreate({required this.content, this.title});
  factory _DocumentCreate.fromJson(Map<String, dynamic> json) => _$DocumentCreateFromJson(json);

@override final  String content;
@override final  String? title;

/// Create a copy of DocumentCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentCreateCopyWith<_DocumentCreate> get copyWith => __$DocumentCreateCopyWithImpl<_DocumentCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentCreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentCreate&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,title);

@override
String toString() {
  return 'DocumentCreate(content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class _$DocumentCreateCopyWith<$Res> implements $DocumentCreateCopyWith<$Res> {
  factory _$DocumentCreateCopyWith(_DocumentCreate value, $Res Function(_DocumentCreate) _then) = __$DocumentCreateCopyWithImpl;
@override @useResult
$Res call({
 String content, String? title
});




}
/// @nodoc
class __$DocumentCreateCopyWithImpl<$Res>
    implements _$DocumentCreateCopyWith<$Res> {
  __$DocumentCreateCopyWithImpl(this._self, this._then);

  final _DocumentCreate _self;
  final $Res Function(_DocumentCreate) _then;

/// Create a copy of DocumentCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? title = freezed,}) {
  return _then(_DocumentCreate(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DocumentUpdate {

 String? get content; String? get title;
/// Create a copy of DocumentUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentUpdateCopyWith<DocumentUpdate> get copyWith => _$DocumentUpdateCopyWithImpl<DocumentUpdate>(this as DocumentUpdate, _$identity);

  /// Serializes this DocumentUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentUpdate&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,title);

@override
String toString() {
  return 'DocumentUpdate(content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class $DocumentUpdateCopyWith<$Res>  {
  factory $DocumentUpdateCopyWith(DocumentUpdate value, $Res Function(DocumentUpdate) _then) = _$DocumentUpdateCopyWithImpl;
@useResult
$Res call({
 String? content, String? title
});




}
/// @nodoc
class _$DocumentUpdateCopyWithImpl<$Res>
    implements $DocumentUpdateCopyWith<$Res> {
  _$DocumentUpdateCopyWithImpl(this._self, this._then);

  final DocumentUpdate _self;
  final $Res Function(DocumentUpdate) _then;

/// Create a copy of DocumentUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = freezed,Object? title = freezed,}) {
  return _then(_self.copyWith(
content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentUpdate].
extension DocumentUpdatePatterns on DocumentUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentUpdate value)  $default,){
final _that = this;
switch (_that) {
case _DocumentUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? content,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentUpdate() when $default != null:
return $default(_that.content,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? content,  String? title)  $default,) {final _that = this;
switch (_that) {
case _DocumentUpdate():
return $default(_that.content,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? content,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _DocumentUpdate() when $default != null:
return $default(_that.content,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentUpdate implements DocumentUpdate {
  const _DocumentUpdate({this.content, this.title});
  factory _DocumentUpdate.fromJson(Map<String, dynamic> json) => _$DocumentUpdateFromJson(json);

@override final  String? content;
@override final  String? title;

/// Create a copy of DocumentUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentUpdateCopyWith<_DocumentUpdate> get copyWith => __$DocumentUpdateCopyWithImpl<_DocumentUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentUpdate&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,title);

@override
String toString() {
  return 'DocumentUpdate(content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class _$DocumentUpdateCopyWith<$Res> implements $DocumentUpdateCopyWith<$Res> {
  factory _$DocumentUpdateCopyWith(_DocumentUpdate value, $Res Function(_DocumentUpdate) _then) = __$DocumentUpdateCopyWithImpl;
@override @useResult
$Res call({
 String? content, String? title
});




}
/// @nodoc
class __$DocumentUpdateCopyWithImpl<$Res>
    implements _$DocumentUpdateCopyWith<$Res> {
  __$DocumentUpdateCopyWithImpl(this._self, this._then);

  final _DocumentUpdate _self;
  final $Res Function(_DocumentUpdate) _then;

/// Create a copy of DocumentUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = freezed,Object? title = freezed,}) {
  return _then(_DocumentUpdate(
content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DocumentRead {

 String get id; String get title; List<String> get tags;@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus get indexStatus; String get createdAt; String get updatedAt;
/// Create a copy of DocumentRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentReadCopyWith<DocumentRead> get copyWith => _$DocumentReadCopyWithImpl<DocumentRead>(this as DocumentRead, _$identity);

  /// Serializes this DocumentRead to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentRead&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.indexStatus, indexStatus) || other.indexStatus == indexStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(tags),indexStatus,createdAt,updatedAt);

@override
String toString() {
  return 'DocumentRead(id: $id, title: $title, tags: $tags, indexStatus: $indexStatus, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DocumentReadCopyWith<$Res>  {
  factory $DocumentReadCopyWith(DocumentRead value, $Res Function(DocumentRead) _then) = _$DocumentReadCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<String> tags,@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus indexStatus, String createdAt, String updatedAt
});




}
/// @nodoc
class _$DocumentReadCopyWithImpl<$Res>
    implements $DocumentReadCopyWith<$Res> {
  _$DocumentReadCopyWithImpl(this._self, this._then);

  final DocumentRead _self;
  final $Res Function(DocumentRead) _then;

/// Create a copy of DocumentRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? indexStatus = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,indexStatus: null == indexStatus ? _self.indexStatus : indexStatus // ignore: cast_nullable_to_non_nullable
as IndexStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentRead].
extension DocumentReadPatterns on DocumentRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentRead value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentRead() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentRead value)  $default,){
final _that = this;
switch (_that) {
case _DocumentRead():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentRead value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentRead() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentRead() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentRead():
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentRead() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentRead implements DocumentRead {
  const _DocumentRead({required this.id, required this.title, required final  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed) required this.indexStatus, required this.createdAt, required this.updatedAt}): _tags = tags;
  factory _DocumentRead.fromJson(Map<String, dynamic> json) => _$DocumentReadFromJson(json);

@override final  String id;
@override final  String title;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(unknownEnumValue: IndexStatus.failed) final  IndexStatus indexStatus;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of DocumentRead
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentReadCopyWith<_DocumentRead> get copyWith => __$DocumentReadCopyWithImpl<_DocumentRead>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentReadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentRead&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.indexStatus, indexStatus) || other.indexStatus == indexStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_tags),indexStatus,createdAt,updatedAt);

@override
String toString() {
  return 'DocumentRead(id: $id, title: $title, tags: $tags, indexStatus: $indexStatus, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentReadCopyWith<$Res> implements $DocumentReadCopyWith<$Res> {
  factory _$DocumentReadCopyWith(_DocumentRead value, $Res Function(_DocumentRead) _then) = __$DocumentReadCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<String> tags,@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus indexStatus, String createdAt, String updatedAt
});




}
/// @nodoc
class __$DocumentReadCopyWithImpl<$Res>
    implements _$DocumentReadCopyWith<$Res> {
  __$DocumentReadCopyWithImpl(this._self, this._then);

  final _DocumentRead _self;
  final $Res Function(_DocumentRead) _then;

/// Create a copy of DocumentRead
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? indexStatus = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_DocumentRead(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,indexStatus: null == indexStatus ? _self.indexStatus : indexStatus // ignore: cast_nullable_to_non_nullable
as IndexStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DocumentReadDetail {

 String get id; String get title; List<String> get tags;@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus get indexStatus; String get createdAt; String get updatedAt; String get content;
/// Create a copy of DocumentReadDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentReadDetailCopyWith<DocumentReadDetail> get copyWith => _$DocumentReadDetailCopyWithImpl<DocumentReadDetail>(this as DocumentReadDetail, _$identity);

  /// Serializes this DocumentReadDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentReadDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.indexStatus, indexStatus) || other.indexStatus == indexStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(tags),indexStatus,createdAt,updatedAt,content);

@override
String toString() {
  return 'DocumentReadDetail(id: $id, title: $title, tags: $tags, indexStatus: $indexStatus, createdAt: $createdAt, updatedAt: $updatedAt, content: $content)';
}


}

/// @nodoc
abstract mixin class $DocumentReadDetailCopyWith<$Res>  {
  factory $DocumentReadDetailCopyWith(DocumentReadDetail value, $Res Function(DocumentReadDetail) _then) = _$DocumentReadDetailCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<String> tags,@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus indexStatus, String createdAt, String updatedAt, String content
});




}
/// @nodoc
class _$DocumentReadDetailCopyWithImpl<$Res>
    implements $DocumentReadDetailCopyWith<$Res> {
  _$DocumentReadDetailCopyWithImpl(this._self, this._then);

  final DocumentReadDetail _self;
  final $Res Function(DocumentReadDetail) _then;

/// Create a copy of DocumentReadDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? indexStatus = null,Object? createdAt = null,Object? updatedAt = null,Object? content = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,indexStatus: null == indexStatus ? _self.indexStatus : indexStatus // ignore: cast_nullable_to_non_nullable
as IndexStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentReadDetail].
extension DocumentReadDetailPatterns on DocumentReadDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentReadDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentReadDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentReadDetail value)  $default,){
final _that = this;
switch (_that) {
case _DocumentReadDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentReadDetail value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentReadDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String createdAt,  String updatedAt,  String content)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentReadDetail() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.createdAt,_that.updatedAt,_that.content);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String createdAt,  String updatedAt,  String content)  $default,) {final _that = this;
switch (_that) {
case _DocumentReadDetail():
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.createdAt,_that.updatedAt,_that.content);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String createdAt,  String updatedAt,  String content)?  $default,) {final _that = this;
switch (_that) {
case _DocumentReadDetail() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.createdAt,_that.updatedAt,_that.content);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentReadDetail implements DocumentReadDetail {
  const _DocumentReadDetail({required this.id, required this.title, required final  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed) required this.indexStatus, required this.createdAt, required this.updatedAt, required this.content}): _tags = tags;
  factory _DocumentReadDetail.fromJson(Map<String, dynamic> json) => _$DocumentReadDetailFromJson(json);

@override final  String id;
@override final  String title;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(unknownEnumValue: IndexStatus.failed) final  IndexStatus indexStatus;
@override final  String createdAt;
@override final  String updatedAt;
@override final  String content;

/// Create a copy of DocumentReadDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentReadDetailCopyWith<_DocumentReadDetail> get copyWith => __$DocumentReadDetailCopyWithImpl<_DocumentReadDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentReadDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentReadDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.indexStatus, indexStatus) || other.indexStatus == indexStatus)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.content, content) || other.content == content));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_tags),indexStatus,createdAt,updatedAt,content);

@override
String toString() {
  return 'DocumentReadDetail(id: $id, title: $title, tags: $tags, indexStatus: $indexStatus, createdAt: $createdAt, updatedAt: $updatedAt, content: $content)';
}


}

/// @nodoc
abstract mixin class _$DocumentReadDetailCopyWith<$Res> implements $DocumentReadDetailCopyWith<$Res> {
  factory _$DocumentReadDetailCopyWith(_DocumentReadDetail value, $Res Function(_DocumentReadDetail) _then) = __$DocumentReadDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<String> tags,@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus indexStatus, String createdAt, String updatedAt, String content
});




}
/// @nodoc
class __$DocumentReadDetailCopyWithImpl<$Res>
    implements _$DocumentReadDetailCopyWith<$Res> {
  __$DocumentReadDetailCopyWithImpl(this._self, this._then);

  final _DocumentReadDetail _self;
  final $Res Function(_DocumentReadDetail) _then;

/// Create a copy of DocumentReadDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? indexStatus = null,Object? createdAt = null,Object? updatedAt = null,Object? content = null,}) {
  return _then(_DocumentReadDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,indexStatus: null == indexStatus ? _self.indexStatus : indexStatus // ignore: cast_nullable_to_non_nullable
as IndexStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DocumentPage {

 List<DocumentRead> get items; String? get nextCursor;
/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentPageCopyWith<DocumentPage> get copyWith => _$DocumentPageCopyWithImpl<DocumentPage>(this as DocumentPage, _$identity);

  /// Serializes this DocumentPage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor);

@override
String toString() {
  return 'DocumentPage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class $DocumentPageCopyWith<$Res>  {
  factory $DocumentPageCopyWith(DocumentPage value, $Res Function(DocumentPage) _then) = _$DocumentPageCopyWithImpl;
@useResult
$Res call({
 List<DocumentRead> items, String? nextCursor
});




}
/// @nodoc
class _$DocumentPageCopyWithImpl<$Res>
    implements $DocumentPageCopyWith<$Res> {
  _$DocumentPageCopyWithImpl(this._self, this._then);

  final DocumentPage _self;
  final $Res Function(DocumentPage) _then;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<DocumentRead>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentPage].
extension DocumentPagePatterns on DocumentPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentPage value)  $default,){
final _that = this;
switch (_that) {
case _DocumentPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentPage value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DocumentRead> items,  String? nextCursor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DocumentRead> items,  String? nextCursor)  $default,) {final _that = this;
switch (_that) {
case _DocumentPage():
return $default(_that.items,_that.nextCursor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DocumentRead> items,  String? nextCursor)?  $default,) {final _that = this;
switch (_that) {
case _DocumentPage() when $default != null:
return $default(_that.items,_that.nextCursor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentPage implements DocumentPage {
  const _DocumentPage({required final  List<DocumentRead> items, this.nextCursor}): _items = items;
  factory _DocumentPage.fromJson(Map<String, dynamic> json) => _$DocumentPageFromJson(json);

 final  List<DocumentRead> _items;
@override List<DocumentRead> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentPageCopyWith<_DocumentPage> get copyWith => __$DocumentPageCopyWithImpl<_DocumentPage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentPageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor);

@override
String toString() {
  return 'DocumentPage(items: $items, nextCursor: $nextCursor)';
}


}

/// @nodoc
abstract mixin class _$DocumentPageCopyWith<$Res> implements $DocumentPageCopyWith<$Res> {
  factory _$DocumentPageCopyWith(_DocumentPage value, $Res Function(_DocumentPage) _then) = __$DocumentPageCopyWithImpl;
@override @useResult
$Res call({
 List<DocumentRead> items, String? nextCursor
});




}
/// @nodoc
class __$DocumentPageCopyWithImpl<$Res>
    implements _$DocumentPageCopyWith<$Res> {
  __$DocumentPageCopyWithImpl(this._self, this._then);

  final _DocumentPage _self;
  final $Res Function(_DocumentPage) _then;

/// Create a copy of DocumentPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,}) {
  return _then(_DocumentPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<DocumentRead>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
