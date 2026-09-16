// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DraftContent {

 String get content; String? get title;
/// Create a copy of DraftContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DraftContentCopyWith<DraftContent> get copyWith => _$DraftContentCopyWithImpl<DraftContent>(this as DraftContent, _$identity);

  /// Serializes this DraftContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DraftContent&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,title);

@override
String toString() {
  return 'DraftContent(content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class $DraftContentCopyWith<$Res>  {
  factory $DraftContentCopyWith(DraftContent value, $Res Function(DraftContent) _then) = _$DraftContentCopyWithImpl;
@useResult
$Res call({
 String content, String? title
});




}
/// @nodoc
class _$DraftContentCopyWithImpl<$Res>
    implements $DraftContentCopyWith<$Res> {
  _$DraftContentCopyWithImpl(this._self, this._then);

  final DraftContent _self;
  final $Res Function(DraftContent) _then;

/// Create a copy of DraftContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? title = freezed,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DraftContent].
extension DraftContentPatterns on DraftContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DraftContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DraftContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DraftContent value)  $default,){
final _that = this;
switch (_that) {
case _DraftContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DraftContent value)?  $default,){
final _that = this;
switch (_that) {
case _DraftContent() when $default != null:
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
case _DraftContent() when $default != null:
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
case _DraftContent():
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
case _DraftContent() when $default != null:
return $default(_that.content,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DraftContent implements DraftContent {
  const _DraftContent({required this.content, this.title});
  factory _DraftContent.fromJson(Map<String, dynamic> json) => _$DraftContentFromJson(json);

@override final  String content;
@override final  String? title;

/// Create a copy of DraftContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DraftContentCopyWith<_DraftContent> get copyWith => __$DraftContentCopyWithImpl<_DraftContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DraftContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DraftContent&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,content,title);

@override
String toString() {
  return 'DraftContent(content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class _$DraftContentCopyWith<$Res> implements $DraftContentCopyWith<$Res> {
  factory _$DraftContentCopyWith(_DraftContent value, $Res Function(_DraftContent) _then) = __$DraftContentCopyWithImpl;
@override @useResult
$Res call({
 String content, String? title
});




}
/// @nodoc
class __$DraftContentCopyWithImpl<$Res>
    implements _$DraftContentCopyWith<$Res> {
  __$DraftContentCopyWithImpl(this._self, this._then);

  final _DraftContent _self;
  final $Res Function(_DraftContent) _then;

/// Create a copy of DraftContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? title = freezed,}) {
  return _then(_DraftContent(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OperationCreate {

 String get documentId; String get baseDocumentVersion; DraftContent get draft; String? get idempotencyKey;
/// Create a copy of OperationCreate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationCreateCopyWith<OperationCreate> get copyWith => _$OperationCreateCopyWithImpl<OperationCreate>(this as OperationCreate, _$identity);

  /// Serializes this OperationCreate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationCreate&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.baseDocumentVersion, baseDocumentVersion) || other.baseDocumentVersion == baseDocumentVersion)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,baseDocumentVersion,draft,idempotencyKey);

@override
String toString() {
  return 'OperationCreate(documentId: $documentId, baseDocumentVersion: $baseDocumentVersion, draft: $draft, idempotencyKey: $idempotencyKey)';
}


}

/// @nodoc
abstract mixin class $OperationCreateCopyWith<$Res>  {
  factory $OperationCreateCopyWith(OperationCreate value, $Res Function(OperationCreate) _then) = _$OperationCreateCopyWithImpl;
@useResult
$Res call({
 String documentId, String baseDocumentVersion, DraftContent draft, String? idempotencyKey
});


$DraftContentCopyWith<$Res> get draft;

}
/// @nodoc
class _$OperationCreateCopyWithImpl<$Res>
    implements $OperationCreateCopyWith<$Res> {
  _$OperationCreateCopyWithImpl(this._self, this._then);

  final OperationCreate _self;
  final $Res Function(OperationCreate) _then;

/// Create a copy of OperationCreate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? baseDocumentVersion = null,Object? draft = null,Object? idempotencyKey = freezed,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,baseDocumentVersion: null == baseDocumentVersion ? _self.baseDocumentVersion : baseDocumentVersion // ignore: cast_nullable_to_non_nullable
as String,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as DraftContent,idempotencyKey: freezed == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of OperationCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftContentCopyWith<$Res> get draft {
  
  return $DraftContentCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [OperationCreate].
extension OperationCreatePatterns on OperationCreate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationCreate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationCreate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationCreate value)  $default,){
final _that = this;
switch (_that) {
case _OperationCreate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationCreate value)?  $default,){
final _that = this;
switch (_that) {
case _OperationCreate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  String baseDocumentVersion,  DraftContent draft,  String? idempotencyKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationCreate() when $default != null:
return $default(_that.documentId,_that.baseDocumentVersion,_that.draft,_that.idempotencyKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  String baseDocumentVersion,  DraftContent draft,  String? idempotencyKey)  $default,) {final _that = this;
switch (_that) {
case _OperationCreate():
return $default(_that.documentId,_that.baseDocumentVersion,_that.draft,_that.idempotencyKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  String baseDocumentVersion,  DraftContent draft,  String? idempotencyKey)?  $default,) {final _that = this;
switch (_that) {
case _OperationCreate() when $default != null:
return $default(_that.documentId,_that.baseDocumentVersion,_that.draft,_that.idempotencyKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OperationCreate implements OperationCreate {
  const _OperationCreate({required this.documentId, required this.baseDocumentVersion, required this.draft, this.idempotencyKey});
  factory _OperationCreate.fromJson(Map<String, dynamic> json) => _$OperationCreateFromJson(json);

@override final  String documentId;
@override final  String baseDocumentVersion;
@override final  DraftContent draft;
@override final  String? idempotencyKey;

/// Create a copy of OperationCreate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationCreateCopyWith<_OperationCreate> get copyWith => __$OperationCreateCopyWithImpl<_OperationCreate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OperationCreateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationCreate&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.baseDocumentVersion, baseDocumentVersion) || other.baseDocumentVersion == baseDocumentVersion)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,baseDocumentVersion,draft,idempotencyKey);

@override
String toString() {
  return 'OperationCreate(documentId: $documentId, baseDocumentVersion: $baseDocumentVersion, draft: $draft, idempotencyKey: $idempotencyKey)';
}


}

/// @nodoc
abstract mixin class _$OperationCreateCopyWith<$Res> implements $OperationCreateCopyWith<$Res> {
  factory _$OperationCreateCopyWith(_OperationCreate value, $Res Function(_OperationCreate) _then) = __$OperationCreateCopyWithImpl;
@override @useResult
$Res call({
 String documentId, String baseDocumentVersion, DraftContent draft, String? idempotencyKey
});


@override $DraftContentCopyWith<$Res> get draft;

}
/// @nodoc
class __$OperationCreateCopyWithImpl<$Res>
    implements _$OperationCreateCopyWith<$Res> {
  __$OperationCreateCopyWithImpl(this._self, this._then);

  final _OperationCreate _self;
  final $Res Function(_OperationCreate) _then;

/// Create a copy of OperationCreate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? baseDocumentVersion = null,Object? draft = null,Object? idempotencyKey = freezed,}) {
  return _then(_OperationCreate(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,baseDocumentVersion: null == baseDocumentVersion ? _self.baseDocumentVersion : baseDocumentVersion // ignore: cast_nullable_to_non_nullable
as String,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as DraftContent,idempotencyKey: freezed == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of OperationCreate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftContentCopyWith<$Res> get draft {
  
  return $DraftContentCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// @nodoc
mixin _$OperationReadDetail {

 String get id; String? get documentId; String? get baseDocumentVersion;@JsonKey(unknownEnumValue: OperationState.failed) OperationState get state; String? get idempotencyKey; String get createdAt; String get updatedAt; DraftContent? get draft; Map<String, dynamic>? get result; Map<String, dynamic>? get error;
/// Create a copy of OperationReadDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationReadDetailCopyWith<OperationReadDetail> get copyWith => _$OperationReadDetailCopyWithImpl<OperationReadDetail>(this as OperationReadDetail, _$identity);

  /// Serializes this OperationReadDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationReadDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.baseDocumentVersion, baseDocumentVersion) || other.baseDocumentVersion == baseDocumentVersion)&&(identical(other.state, state) || other.state == state)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.draft, draft) || other.draft == draft)&&const DeepCollectionEquality().equals(other.result, result)&&const DeepCollectionEquality().equals(other.error, error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,baseDocumentVersion,state,idempotencyKey,createdAt,updatedAt,draft,const DeepCollectionEquality().hash(result),const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'OperationReadDetail(id: $id, documentId: $documentId, baseDocumentVersion: $baseDocumentVersion, state: $state, idempotencyKey: $idempotencyKey, createdAt: $createdAt, updatedAt: $updatedAt, draft: $draft, result: $result, error: $error)';
}


}

/// @nodoc
abstract mixin class $OperationReadDetailCopyWith<$Res>  {
  factory $OperationReadDetailCopyWith(OperationReadDetail value, $Res Function(OperationReadDetail) _then) = _$OperationReadDetailCopyWithImpl;
@useResult
$Res call({
 String id, String? documentId, String? baseDocumentVersion,@JsonKey(unknownEnumValue: OperationState.failed) OperationState state, String? idempotencyKey, String createdAt, String updatedAt, DraftContent? draft, Map<String, dynamic>? result, Map<String, dynamic>? error
});


$DraftContentCopyWith<$Res>? get draft;

}
/// @nodoc
class _$OperationReadDetailCopyWithImpl<$Res>
    implements $OperationReadDetailCopyWith<$Res> {
  _$OperationReadDetailCopyWithImpl(this._self, this._then);

  final OperationReadDetail _self;
  final $Res Function(OperationReadDetail) _then;

/// Create a copy of OperationReadDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? documentId = freezed,Object? baseDocumentVersion = freezed,Object? state = null,Object? idempotencyKey = freezed,Object? createdAt = null,Object? updatedAt = null,Object? draft = freezed,Object? result = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,baseDocumentVersion: freezed == baseDocumentVersion ? _self.baseDocumentVersion : baseDocumentVersion // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OperationState,idempotencyKey: freezed == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as DraftContent?,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}
/// Create a copy of OperationReadDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftContentCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $DraftContentCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [OperationReadDetail].
extension OperationReadDetailPatterns on OperationReadDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationReadDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationReadDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationReadDetail value)  $default,){
final _that = this;
switch (_that) {
case _OperationReadDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationReadDetail value)?  $default,){
final _that = this;
switch (_that) {
case _OperationReadDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? documentId,  String? baseDocumentVersion, @JsonKey(unknownEnumValue: OperationState.failed)  OperationState state,  String? idempotencyKey,  String createdAt,  String updatedAt,  DraftContent? draft,  Map<String, dynamic>? result,  Map<String, dynamic>? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationReadDetail() when $default != null:
return $default(_that.id,_that.documentId,_that.baseDocumentVersion,_that.state,_that.idempotencyKey,_that.createdAt,_that.updatedAt,_that.draft,_that.result,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? documentId,  String? baseDocumentVersion, @JsonKey(unknownEnumValue: OperationState.failed)  OperationState state,  String? idempotencyKey,  String createdAt,  String updatedAt,  DraftContent? draft,  Map<String, dynamic>? result,  Map<String, dynamic>? error)  $default,) {final _that = this;
switch (_that) {
case _OperationReadDetail():
return $default(_that.id,_that.documentId,_that.baseDocumentVersion,_that.state,_that.idempotencyKey,_that.createdAt,_that.updatedAt,_that.draft,_that.result,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? documentId,  String? baseDocumentVersion, @JsonKey(unknownEnumValue: OperationState.failed)  OperationState state,  String? idempotencyKey,  String createdAt,  String updatedAt,  DraftContent? draft,  Map<String, dynamic>? result,  Map<String, dynamic>? error)?  $default,) {final _that = this;
switch (_that) {
case _OperationReadDetail() when $default != null:
return $default(_that.id,_that.documentId,_that.baseDocumentVersion,_that.state,_that.idempotencyKey,_that.createdAt,_that.updatedAt,_that.draft,_that.result,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OperationReadDetail implements OperationReadDetail {
  const _OperationReadDetail({required this.id, this.documentId, this.baseDocumentVersion, @JsonKey(unknownEnumValue: OperationState.failed) required this.state, this.idempotencyKey, required this.createdAt, required this.updatedAt, this.draft, final  Map<String, dynamic>? result, final  Map<String, dynamic>? error}): _result = result,_error = error;
  factory _OperationReadDetail.fromJson(Map<String, dynamic> json) => _$OperationReadDetailFromJson(json);

@override final  String id;
@override final  String? documentId;
@override final  String? baseDocumentVersion;
@override@JsonKey(unknownEnumValue: OperationState.failed) final  OperationState state;
@override final  String? idempotencyKey;
@override final  String createdAt;
@override final  String updatedAt;
@override final  DraftContent? draft;
 final  Map<String, dynamic>? _result;
@override Map<String, dynamic>? get result {
  final value = _result;
  if (value == null) return null;
  if (_result is EqualUnmodifiableMapView) return _result;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _error;
@override Map<String, dynamic>? get error {
  final value = _error;
  if (value == null) return null;
  if (_error is EqualUnmodifiableMapView) return _error;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of OperationReadDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationReadDetailCopyWith<_OperationReadDetail> get copyWith => __$OperationReadDetailCopyWithImpl<_OperationReadDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OperationReadDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationReadDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.baseDocumentVersion, baseDocumentVersion) || other.baseDocumentVersion == baseDocumentVersion)&&(identical(other.state, state) || other.state == state)&&(identical(other.idempotencyKey, idempotencyKey) || other.idempotencyKey == idempotencyKey)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.draft, draft) || other.draft == draft)&&const DeepCollectionEquality().equals(other._result, _result)&&const DeepCollectionEquality().equals(other._error, _error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,baseDocumentVersion,state,idempotencyKey,createdAt,updatedAt,draft,const DeepCollectionEquality().hash(_result),const DeepCollectionEquality().hash(_error));

@override
String toString() {
  return 'OperationReadDetail(id: $id, documentId: $documentId, baseDocumentVersion: $baseDocumentVersion, state: $state, idempotencyKey: $idempotencyKey, createdAt: $createdAt, updatedAt: $updatedAt, draft: $draft, result: $result, error: $error)';
}


}

/// @nodoc
abstract mixin class _$OperationReadDetailCopyWith<$Res> implements $OperationReadDetailCopyWith<$Res> {
  factory _$OperationReadDetailCopyWith(_OperationReadDetail value, $Res Function(_OperationReadDetail) _then) = __$OperationReadDetailCopyWithImpl;
@override @useResult
$Res call({
 String id, String? documentId, String? baseDocumentVersion,@JsonKey(unknownEnumValue: OperationState.failed) OperationState state, String? idempotencyKey, String createdAt, String updatedAt, DraftContent? draft, Map<String, dynamic>? result, Map<String, dynamic>? error
});


@override $DraftContentCopyWith<$Res>? get draft;

}
/// @nodoc
class __$OperationReadDetailCopyWithImpl<$Res>
    implements _$OperationReadDetailCopyWith<$Res> {
  __$OperationReadDetailCopyWithImpl(this._self, this._then);

  final _OperationReadDetail _self;
  final $Res Function(_OperationReadDetail) _then;

/// Create a copy of OperationReadDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? documentId = freezed,Object? baseDocumentVersion = freezed,Object? state = null,Object? idempotencyKey = freezed,Object? createdAt = null,Object? updatedAt = null,Object? draft = freezed,Object? result = freezed,Object? error = freezed,}) {
  return _then(_OperationReadDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: freezed == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String?,baseDocumentVersion: freezed == baseDocumentVersion ? _self.baseDocumentVersion : baseDocumentVersion // ignore: cast_nullable_to_non_nullable
as String?,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as OperationState,idempotencyKey: freezed == idempotencyKey ? _self.idempotencyKey : idempotencyKey // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as DraftContent?,result: freezed == result ? _self._result : result // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,error: freezed == error ? _self._error : error // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

/// Create a copy of OperationReadDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftContentCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $DraftContentCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// @nodoc
mixin _$OperationTransition {

@JsonKey(includeIfNull: false) DraftContent? get draft;
/// Create a copy of OperationTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OperationTransitionCopyWith<OperationTransition> get copyWith => _$OperationTransitionCopyWithImpl<OperationTransition>(this as OperationTransition, _$identity);

  /// Serializes this OperationTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OperationTransition&&(identical(other.draft, draft) || other.draft == draft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'OperationTransition(draft: $draft)';
}


}

/// @nodoc
abstract mixin class $OperationTransitionCopyWith<$Res>  {
  factory $OperationTransitionCopyWith(OperationTransition value, $Res Function(OperationTransition) _then) = _$OperationTransitionCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) DraftContent? draft
});


$DraftContentCopyWith<$Res>? get draft;

}
/// @nodoc
class _$OperationTransitionCopyWithImpl<$Res>
    implements $OperationTransitionCopyWith<$Res> {
  _$OperationTransitionCopyWithImpl(this._self, this._then);

  final OperationTransition _self;
  final $Res Function(OperationTransition) _then;

/// Create a copy of OperationTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draft = freezed,}) {
  return _then(_self.copyWith(
draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as DraftContent?,
  ));
}
/// Create a copy of OperationTransition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftContentCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $DraftContentCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// Adds pattern-matching-related methods to [OperationTransition].
extension OperationTransitionPatterns on OperationTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OperationTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OperationTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OperationTransition value)  $default,){
final _that = this;
switch (_that) {
case _OperationTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OperationTransition value)?  $default,){
final _that = this;
switch (_that) {
case _OperationTransition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  DraftContent? draft)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OperationTransition() when $default != null:
return $default(_that.draft);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  DraftContent? draft)  $default,) {final _that = this;
switch (_that) {
case _OperationTransition():
return $default(_that.draft);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  DraftContent? draft)?  $default,) {final _that = this;
switch (_that) {
case _OperationTransition() when $default != null:
return $default(_that.draft);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OperationTransition implements OperationTransition {
  const _OperationTransition({@JsonKey(includeIfNull: false) this.draft});
  factory _OperationTransition.fromJson(Map<String, dynamic> json) => _$OperationTransitionFromJson(json);

@override@JsonKey(includeIfNull: false) final  DraftContent? draft;

/// Create a copy of OperationTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OperationTransitionCopyWith<_OperationTransition> get copyWith => __$OperationTransitionCopyWithImpl<_OperationTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OperationTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OperationTransition&&(identical(other.draft, draft) || other.draft == draft));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,draft);

@override
String toString() {
  return 'OperationTransition(draft: $draft)';
}


}

/// @nodoc
abstract mixin class _$OperationTransitionCopyWith<$Res> implements $OperationTransitionCopyWith<$Res> {
  factory _$OperationTransitionCopyWith(_OperationTransition value, $Res Function(_OperationTransition) _then) = __$OperationTransitionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) DraftContent? draft
});


@override $DraftContentCopyWith<$Res>? get draft;

}
/// @nodoc
class __$OperationTransitionCopyWithImpl<$Res>
    implements _$OperationTransitionCopyWith<$Res> {
  __$OperationTransitionCopyWithImpl(this._self, this._then);

  final _OperationTransition _self;
  final $Res Function(_OperationTransition) _then;

/// Create a copy of OperationTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = freezed,}) {
  return _then(_OperationTransition(
draft: freezed == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as DraftContent?,
  ));
}

/// Create a copy of OperationTransition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DraftContentCopyWith<$Res>? get draft {
    if (_self.draft == null) {
    return null;
  }

  return $DraftContentCopyWith<$Res>(_self.draft!, (value) {
    return _then(_self.copyWith(draft: value));
  });
}
}


/// @nodoc
mixin _$ApplyRequest {

@JsonKey(includeIfNull: false) String? get expectedBaseDocumentVersion;
/// Create a copy of ApplyRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplyRequestCopyWith<ApplyRequest> get copyWith => _$ApplyRequestCopyWithImpl<ApplyRequest>(this as ApplyRequest, _$identity);

  /// Serializes this ApplyRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplyRequest&&(identical(other.expectedBaseDocumentVersion, expectedBaseDocumentVersion) || other.expectedBaseDocumentVersion == expectedBaseDocumentVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,expectedBaseDocumentVersion);

@override
String toString() {
  return 'ApplyRequest(expectedBaseDocumentVersion: $expectedBaseDocumentVersion)';
}


}

/// @nodoc
abstract mixin class $ApplyRequestCopyWith<$Res>  {
  factory $ApplyRequestCopyWith(ApplyRequest value, $Res Function(ApplyRequest) _then) = _$ApplyRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? expectedBaseDocumentVersion
});




}
/// @nodoc
class _$ApplyRequestCopyWithImpl<$Res>
    implements $ApplyRequestCopyWith<$Res> {
  _$ApplyRequestCopyWithImpl(this._self, this._then);

  final ApplyRequest _self;
  final $Res Function(ApplyRequest) _then;

/// Create a copy of ApplyRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? expectedBaseDocumentVersion = freezed,}) {
  return _then(_self.copyWith(
expectedBaseDocumentVersion: freezed == expectedBaseDocumentVersion ? _self.expectedBaseDocumentVersion : expectedBaseDocumentVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApplyRequest].
extension ApplyRequestPatterns on ApplyRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplyRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplyRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplyRequest value)  $default,){
final _that = this;
switch (_that) {
case _ApplyRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplyRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ApplyRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? expectedBaseDocumentVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplyRequest() when $default != null:
return $default(_that.expectedBaseDocumentVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? expectedBaseDocumentVersion)  $default,) {final _that = this;
switch (_that) {
case _ApplyRequest():
return $default(_that.expectedBaseDocumentVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? expectedBaseDocumentVersion)?  $default,) {final _that = this;
switch (_that) {
case _ApplyRequest() when $default != null:
return $default(_that.expectedBaseDocumentVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApplyRequest implements ApplyRequest {
  const _ApplyRequest({@JsonKey(includeIfNull: false) this.expectedBaseDocumentVersion});
  factory _ApplyRequest.fromJson(Map<String, dynamic> json) => _$ApplyRequestFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? expectedBaseDocumentVersion;

/// Create a copy of ApplyRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplyRequestCopyWith<_ApplyRequest> get copyWith => __$ApplyRequestCopyWithImpl<_ApplyRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApplyRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplyRequest&&(identical(other.expectedBaseDocumentVersion, expectedBaseDocumentVersion) || other.expectedBaseDocumentVersion == expectedBaseDocumentVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,expectedBaseDocumentVersion);

@override
String toString() {
  return 'ApplyRequest(expectedBaseDocumentVersion: $expectedBaseDocumentVersion)';
}


}

/// @nodoc
abstract mixin class _$ApplyRequestCopyWith<$Res> implements $ApplyRequestCopyWith<$Res> {
  factory _$ApplyRequestCopyWith(_ApplyRequest value, $Res Function(_ApplyRequest) _then) = __$ApplyRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? expectedBaseDocumentVersion
});




}
/// @nodoc
class __$ApplyRequestCopyWithImpl<$Res>
    implements _$ApplyRequestCopyWith<$Res> {
  __$ApplyRequestCopyWithImpl(this._self, this._then);

  final _ApplyRequest _self;
  final $Res Function(_ApplyRequest) _then;

/// Create a copy of ApplyRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? expectedBaseDocumentVersion = freezed,}) {
  return _then(_ApplyRequest(
expectedBaseDocumentVersion: freezed == expectedBaseDocumentVersion ? _self.expectedBaseDocumentVersion : expectedBaseDocumentVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RevisionRead {

 String get id; String get documentId; String? get operationId; String get title; List<String> get tags; String get createdAt;
/// Create a copy of RevisionRead
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevisionReadCopyWith<RevisionRead> get copyWith => _$RevisionReadCopyWithImpl<RevisionRead>(this as RevisionRead, _$identity);

  /// Serializes this RevisionRead to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevisionRead&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,operationId,title,const DeepCollectionEquality().hash(tags),createdAt);

@override
String toString() {
  return 'RevisionRead(id: $id, documentId: $documentId, operationId: $operationId, title: $title, tags: $tags, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RevisionReadCopyWith<$Res>  {
  factory $RevisionReadCopyWith(RevisionRead value, $Res Function(RevisionRead) _then) = _$RevisionReadCopyWithImpl;
@useResult
$Res call({
 String id, String documentId, String? operationId, String title, List<String> tags, String createdAt
});




}
/// @nodoc
class _$RevisionReadCopyWithImpl<$Res>
    implements $RevisionReadCopyWith<$Res> {
  _$RevisionReadCopyWithImpl(this._self, this._then);

  final RevisionRead _self;
  final $Res Function(RevisionRead) _then;

/// Create a copy of RevisionRead
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? documentId = null,Object? operationId = freezed,Object? title = null,Object? tags = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,operationId: freezed == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RevisionRead].
extension RevisionReadPatterns on RevisionRead {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevisionRead value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevisionRead() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevisionRead value)  $default,){
final _that = this;
switch (_that) {
case _RevisionRead():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevisionRead value)?  $default,){
final _that = this;
switch (_that) {
case _RevisionRead() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String documentId,  String? operationId,  String title,  List<String> tags,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevisionRead() when $default != null:
return $default(_that.id,_that.documentId,_that.operationId,_that.title,_that.tags,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String documentId,  String? operationId,  String title,  List<String> tags,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _RevisionRead():
return $default(_that.id,_that.documentId,_that.operationId,_that.title,_that.tags,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String documentId,  String? operationId,  String title,  List<String> tags,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _RevisionRead() when $default != null:
return $default(_that.id,_that.documentId,_that.operationId,_that.title,_that.tags,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevisionRead implements RevisionRead {
  const _RevisionRead({required this.id, required this.documentId, this.operationId, required this.title, required final  List<String> tags, required this.createdAt}): _tags = tags;
  factory _RevisionRead.fromJson(Map<String, dynamic> json) => _$RevisionReadFromJson(json);

@override final  String id;
@override final  String documentId;
@override final  String? operationId;
@override final  String title;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String createdAt;

/// Create a copy of RevisionRead
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevisionReadCopyWith<_RevisionRead> get copyWith => __$RevisionReadCopyWithImpl<_RevisionRead>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevisionReadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevisionRead&&(identical(other.id, id) || other.id == id)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,documentId,operationId,title,const DeepCollectionEquality().hash(_tags),createdAt);

@override
String toString() {
  return 'RevisionRead(id: $id, documentId: $documentId, operationId: $operationId, title: $title, tags: $tags, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RevisionReadCopyWith<$Res> implements $RevisionReadCopyWith<$Res> {
  factory _$RevisionReadCopyWith(_RevisionRead value, $Res Function(_RevisionRead) _then) = __$RevisionReadCopyWithImpl;
@override @useResult
$Res call({
 String id, String documentId, String? operationId, String title, List<String> tags, String createdAt
});




}
/// @nodoc
class __$RevisionReadCopyWithImpl<$Res>
    implements _$RevisionReadCopyWith<$Res> {
  __$RevisionReadCopyWithImpl(this._self, this._then);

  final _RevisionRead _self;
  final $Res Function(_RevisionRead) _then;

/// Create a copy of RevisionRead
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? documentId = null,Object? operationId = freezed,Object? title = null,Object? tags = null,Object? createdAt = null,}) {
  return _then(_RevisionRead(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,operationId: freezed == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DocumentInResult {

 String get id; String get title; List<String> get tags;@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus get indexStatus; String get updatedAt;
/// Create a copy of DocumentInResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentInResultCopyWith<DocumentInResult> get copyWith => _$DocumentInResultCopyWithImpl<DocumentInResult>(this as DocumentInResult, _$identity);

  /// Serializes this DocumentInResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentInResult&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.indexStatus, indexStatus) || other.indexStatus == indexStatus)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(tags),indexStatus,updatedAt);

@override
String toString() {
  return 'DocumentInResult(id: $id, title: $title, tags: $tags, indexStatus: $indexStatus, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DocumentInResultCopyWith<$Res>  {
  factory $DocumentInResultCopyWith(DocumentInResult value, $Res Function(DocumentInResult) _then) = _$DocumentInResultCopyWithImpl;
@useResult
$Res call({
 String id, String title, List<String> tags,@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus indexStatus, String updatedAt
});




}
/// @nodoc
class _$DocumentInResultCopyWithImpl<$Res>
    implements $DocumentInResultCopyWith<$Res> {
  _$DocumentInResultCopyWithImpl(this._self, this._then);

  final DocumentInResult _self;
  final $Res Function(DocumentInResult) _then;

/// Create a copy of DocumentInResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? indexStatus = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,indexStatus: null == indexStatus ? _self.indexStatus : indexStatus // ignore: cast_nullable_to_non_nullable
as IndexStatus,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentInResult].
extension DocumentInResultPatterns on DocumentInResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentInResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentInResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentInResult value)  $default,){
final _that = this;
switch (_that) {
case _DocumentInResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentInResult value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentInResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentInResult() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentInResult():
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed)  IndexStatus indexStatus,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentInResult() when $default != null:
return $default(_that.id,_that.title,_that.tags,_that.indexStatus,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentInResult implements DocumentInResult {
  const _DocumentInResult({required this.id, required this.title, required final  List<String> tags, @JsonKey(unknownEnumValue: IndexStatus.failed) required this.indexStatus, required this.updatedAt}): _tags = tags;
  factory _DocumentInResult.fromJson(Map<String, dynamic> json) => _$DocumentInResultFromJson(json);

@override final  String id;
@override final  String title;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey(unknownEnumValue: IndexStatus.failed) final  IndexStatus indexStatus;
@override final  String updatedAt;

/// Create a copy of DocumentInResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentInResultCopyWith<_DocumentInResult> get copyWith => __$DocumentInResultCopyWithImpl<_DocumentInResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentInResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentInResult&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.indexStatus, indexStatus) || other.indexStatus == indexStatus)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_tags),indexStatus,updatedAt);

@override
String toString() {
  return 'DocumentInResult(id: $id, title: $title, tags: $tags, indexStatus: $indexStatus, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentInResultCopyWith<$Res> implements $DocumentInResultCopyWith<$Res> {
  factory _$DocumentInResultCopyWith(_DocumentInResult value, $Res Function(_DocumentInResult) _then) = __$DocumentInResultCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, List<String> tags,@JsonKey(unknownEnumValue: IndexStatus.failed) IndexStatus indexStatus, String updatedAt
});




}
/// @nodoc
class __$DocumentInResultCopyWithImpl<$Res>
    implements _$DocumentInResultCopyWith<$Res> {
  __$DocumentInResultCopyWithImpl(this._self, this._then);

  final _DocumentInResult _self;
  final $Res Function(_DocumentInResult) _then;

/// Create a copy of DocumentInResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? tags = null,Object? indexStatus = null,Object? updatedAt = null,}) {
  return _then(_DocumentInResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,indexStatus: null == indexStatus ? _self.indexStatus : indexStatus // ignore: cast_nullable_to_non_nullable
as IndexStatus,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ApplyResult {

 OperationReadDetail get operation; RevisionRead get revision; DocumentInResult get document;
/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplyResultCopyWith<ApplyResult> get copyWith => _$ApplyResultCopyWithImpl<ApplyResult>(this as ApplyResult, _$identity);

  /// Serializes this ApplyResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplyResult&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.document, document) || other.document == document));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operation,revision,document);

@override
String toString() {
  return 'ApplyResult(operation: $operation, revision: $revision, document: $document)';
}


}

/// @nodoc
abstract mixin class $ApplyResultCopyWith<$Res>  {
  factory $ApplyResultCopyWith(ApplyResult value, $Res Function(ApplyResult) _then) = _$ApplyResultCopyWithImpl;
@useResult
$Res call({
 OperationReadDetail operation, RevisionRead revision, DocumentInResult document
});


$OperationReadDetailCopyWith<$Res> get operation;$RevisionReadCopyWith<$Res> get revision;$DocumentInResultCopyWith<$Res> get document;

}
/// @nodoc
class _$ApplyResultCopyWithImpl<$Res>
    implements $ApplyResultCopyWith<$Res> {
  _$ApplyResultCopyWithImpl(this._self, this._then);

  final ApplyResult _self;
  final $Res Function(ApplyResult) _then;

/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operation = null,Object? revision = null,Object? document = null,}) {
  return _then(_self.copyWith(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as OperationReadDetail,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as RevisionRead,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as DocumentInResult,
  ));
}
/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OperationReadDetailCopyWith<$Res> get operation {
  
  return $OperationReadDetailCopyWith<$Res>(_self.operation, (value) {
    return _then(_self.copyWith(operation: value));
  });
}/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevisionReadCopyWith<$Res> get revision {
  
  return $RevisionReadCopyWith<$Res>(_self.revision, (value) {
    return _then(_self.copyWith(revision: value));
  });
}/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentInResultCopyWith<$Res> get document {
  
  return $DocumentInResultCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}


/// Adds pattern-matching-related methods to [ApplyResult].
extension ApplyResultPatterns on ApplyResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplyResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplyResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplyResult value)  $default,){
final _that = this;
switch (_that) {
case _ApplyResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplyResult value)?  $default,){
final _that = this;
switch (_that) {
case _ApplyResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OperationReadDetail operation,  RevisionRead revision,  DocumentInResult document)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplyResult() when $default != null:
return $default(_that.operation,_that.revision,_that.document);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OperationReadDetail operation,  RevisionRead revision,  DocumentInResult document)  $default,) {final _that = this;
switch (_that) {
case _ApplyResult():
return $default(_that.operation,_that.revision,_that.document);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OperationReadDetail operation,  RevisionRead revision,  DocumentInResult document)?  $default,) {final _that = this;
switch (_that) {
case _ApplyResult() when $default != null:
return $default(_that.operation,_that.revision,_that.document);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ApplyResult implements ApplyResult {
  const _ApplyResult({required this.operation, required this.revision, required this.document});
  factory _ApplyResult.fromJson(Map<String, dynamic> json) => _$ApplyResultFromJson(json);

@override final  OperationReadDetail operation;
@override final  RevisionRead revision;
@override final  DocumentInResult document;

/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplyResultCopyWith<_ApplyResult> get copyWith => __$ApplyResultCopyWithImpl<_ApplyResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ApplyResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplyResult&&(identical(other.operation, operation) || other.operation == operation)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.document, document) || other.document == document));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operation,revision,document);

@override
String toString() {
  return 'ApplyResult(operation: $operation, revision: $revision, document: $document)';
}


}

/// @nodoc
abstract mixin class _$ApplyResultCopyWith<$Res> implements $ApplyResultCopyWith<$Res> {
  factory _$ApplyResultCopyWith(_ApplyResult value, $Res Function(_ApplyResult) _then) = __$ApplyResultCopyWithImpl;
@override @useResult
$Res call({
 OperationReadDetail operation, RevisionRead revision, DocumentInResult document
});


@override $OperationReadDetailCopyWith<$Res> get operation;@override $RevisionReadCopyWith<$Res> get revision;@override $DocumentInResultCopyWith<$Res> get document;

}
/// @nodoc
class __$ApplyResultCopyWithImpl<$Res>
    implements _$ApplyResultCopyWith<$Res> {
  __$ApplyResultCopyWithImpl(this._self, this._then);

  final _ApplyResult _self;
  final $Res Function(_ApplyResult) _then;

/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operation = null,Object? revision = null,Object? document = null,}) {
  return _then(_ApplyResult(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as OperationReadDetail,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as RevisionRead,document: null == document ? _self.document : document // ignore: cast_nullable_to_non_nullable
as DocumentInResult,
  ));
}

/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OperationReadDetailCopyWith<$Res> get operation {
  
  return $OperationReadDetailCopyWith<$Res>(_self.operation, (value) {
    return _then(_self.copyWith(operation: value));
  });
}/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevisionReadCopyWith<$Res> get revision {
  
  return $RevisionReadCopyWith<$Res>(_self.revision, (value) {
    return _then(_self.copyWith(revision: value));
  });
}/// Create a copy of ApplyResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DocumentInResultCopyWith<$Res> get document {
  
  return $DocumentInResultCopyWith<$Res>(_self.document, (value) {
    return _then(_self.copyWith(document: value));
  });
}
}

// dart format on
