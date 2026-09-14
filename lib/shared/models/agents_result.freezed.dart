// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agents_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SummaryResult {

 String get documentId; String get summary; String get model; double get latencyMs;
/// Create a copy of SummaryResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SummaryResultCopyWith<SummaryResult> get copyWith => _$SummaryResultCopyWithImpl<SummaryResult>(this as SummaryResult, _$identity);

  /// Serializes this SummaryResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SummaryResult&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.model, model) || other.model == model)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,summary,model,latencyMs);

@override
String toString() {
  return 'SummaryResult(documentId: $documentId, summary: $summary, model: $model, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class $SummaryResultCopyWith<$Res>  {
  factory $SummaryResultCopyWith(SummaryResult value, $Res Function(SummaryResult) _then) = _$SummaryResultCopyWithImpl;
@useResult
$Res call({
 String documentId, String summary, String model, double latencyMs
});




}
/// @nodoc
class _$SummaryResultCopyWithImpl<$Res>
    implements $SummaryResultCopyWith<$Res> {
  _$SummaryResultCopyWithImpl(this._self, this._then);

  final SummaryResult _self;
  final $Res Function(SummaryResult) _then;

/// Create a copy of SummaryResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? summary = null,Object? model = null,Object? latencyMs = null,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SummaryResult].
extension SummaryResultPatterns on SummaryResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SummaryResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SummaryResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SummaryResult value)  $default,){
final _that = this;
switch (_that) {
case _SummaryResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SummaryResult value)?  $default,){
final _that = this;
switch (_that) {
case _SummaryResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  String summary,  String model,  double latencyMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SummaryResult() when $default != null:
return $default(_that.documentId,_that.summary,_that.model,_that.latencyMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  String summary,  String model,  double latencyMs)  $default,) {final _that = this;
switch (_that) {
case _SummaryResult():
return $default(_that.documentId,_that.summary,_that.model,_that.latencyMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  String summary,  String model,  double latencyMs)?  $default,) {final _that = this;
switch (_that) {
case _SummaryResult() when $default != null:
return $default(_that.documentId,_that.summary,_that.model,_that.latencyMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SummaryResult implements SummaryResult {
  const _SummaryResult({required this.documentId, required this.summary, required this.model, required this.latencyMs});
  factory _SummaryResult.fromJson(Map<String, dynamic> json) => _$SummaryResultFromJson(json);

@override final  String documentId;
@override final  String summary;
@override final  String model;
@override final  double latencyMs;

/// Create a copy of SummaryResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SummaryResultCopyWith<_SummaryResult> get copyWith => __$SummaryResultCopyWithImpl<_SummaryResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SummaryResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SummaryResult&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.model, model) || other.model == model)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,summary,model,latencyMs);

@override
String toString() {
  return 'SummaryResult(documentId: $documentId, summary: $summary, model: $model, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class _$SummaryResultCopyWith<$Res> implements $SummaryResultCopyWith<$Res> {
  factory _$SummaryResultCopyWith(_SummaryResult value, $Res Function(_SummaryResult) _then) = __$SummaryResultCopyWithImpl;
@override @useResult
$Res call({
 String documentId, String summary, String model, double latencyMs
});




}
/// @nodoc
class __$SummaryResultCopyWithImpl<$Res>
    implements _$SummaryResultCopyWith<$Res> {
  __$SummaryResultCopyWithImpl(this._self, this._then);

  final _SummaryResult _self;
  final $Res Function(_SummaryResult) _then;

/// Create a copy of SummaryResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? summary = null,Object? model = null,Object? latencyMs = null,}) {
  return _then(_SummaryResult(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$AssociationItem {

 String get documentId; String get title; List<String> get tags; String get reason; String get signal;
/// Create a copy of AssociationItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssociationItemCopyWith<AssociationItem> get copyWith => _$AssociationItemCopyWithImpl<AssociationItem>(this as AssociationItem, _$identity);

  /// Serializes this AssociationItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssociationItem&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.signal, signal) || other.signal == signal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,title,const DeepCollectionEquality().hash(tags),reason,signal);

@override
String toString() {
  return 'AssociationItem(documentId: $documentId, title: $title, tags: $tags, reason: $reason, signal: $signal)';
}


}

/// @nodoc
abstract mixin class $AssociationItemCopyWith<$Res>  {
  factory $AssociationItemCopyWith(AssociationItem value, $Res Function(AssociationItem) _then) = _$AssociationItemCopyWithImpl;
@useResult
$Res call({
 String documentId, String title, List<String> tags, String reason, String signal
});




}
/// @nodoc
class _$AssociationItemCopyWithImpl<$Res>
    implements $AssociationItemCopyWith<$Res> {
  _$AssociationItemCopyWithImpl(this._self, this._then);

  final AssociationItem _self;
  final $Res Function(AssociationItem) _then;

/// Create a copy of AssociationItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? title = null,Object? tags = null,Object? reason = null,Object? signal = null,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,signal: null == signal ? _self.signal : signal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AssociationItem].
extension AssociationItemPatterns on AssociationItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssociationItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssociationItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssociationItem value)  $default,){
final _that = this;
switch (_that) {
case _AssociationItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssociationItem value)?  $default,){
final _that = this;
switch (_that) {
case _AssociationItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  String title,  List<String> tags,  String reason,  String signal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssociationItem() when $default != null:
return $default(_that.documentId,_that.title,_that.tags,_that.reason,_that.signal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  String title,  List<String> tags,  String reason,  String signal)  $default,) {final _that = this;
switch (_that) {
case _AssociationItem():
return $default(_that.documentId,_that.title,_that.tags,_that.reason,_that.signal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  String title,  List<String> tags,  String reason,  String signal)?  $default,) {final _that = this;
switch (_that) {
case _AssociationItem() when $default != null:
return $default(_that.documentId,_that.title,_that.tags,_that.reason,_that.signal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssociationItem implements AssociationItem {
  const _AssociationItem({required this.documentId, required this.title, required final  List<String> tags, required this.reason, required this.signal}): _tags = tags;
  factory _AssociationItem.fromJson(Map<String, dynamic> json) => _$AssociationItemFromJson(json);

@override final  String documentId;
@override final  String title;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String reason;
@override final  String signal;

/// Create a copy of AssociationItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssociationItemCopyWith<_AssociationItem> get copyWith => __$AssociationItemCopyWithImpl<_AssociationItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssociationItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssociationItem&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.signal, signal) || other.signal == signal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,title,const DeepCollectionEquality().hash(_tags),reason,signal);

@override
String toString() {
  return 'AssociationItem(documentId: $documentId, title: $title, tags: $tags, reason: $reason, signal: $signal)';
}


}

/// @nodoc
abstract mixin class _$AssociationItemCopyWith<$Res> implements $AssociationItemCopyWith<$Res> {
  factory _$AssociationItemCopyWith(_AssociationItem value, $Res Function(_AssociationItem) _then) = __$AssociationItemCopyWithImpl;
@override @useResult
$Res call({
 String documentId, String title, List<String> tags, String reason, String signal
});




}
/// @nodoc
class __$AssociationItemCopyWithImpl<$Res>
    implements _$AssociationItemCopyWith<$Res> {
  __$AssociationItemCopyWithImpl(this._self, this._then);

  final _AssociationItem _self;
  final $Res Function(_AssociationItem) _then;

/// Create a copy of AssociationItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? title = null,Object? tags = null,Object? reason = null,Object? signal = null,}) {
  return _then(_AssociationItem(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,signal: null == signal ? _self.signal : signal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AssociationsResult {

 String get documentId; List<AssociationItem> get associations; String get model; double get latencyMs;
/// Create a copy of AssociationsResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssociationsResultCopyWith<AssociationsResult> get copyWith => _$AssociationsResultCopyWithImpl<AssociationsResult>(this as AssociationsResult, _$identity);

  /// Serializes this AssociationsResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssociationsResult&&(identical(other.documentId, documentId) || other.documentId == documentId)&&const DeepCollectionEquality().equals(other.associations, associations)&&(identical(other.model, model) || other.model == model)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,const DeepCollectionEquality().hash(associations),model,latencyMs);

@override
String toString() {
  return 'AssociationsResult(documentId: $documentId, associations: $associations, model: $model, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class $AssociationsResultCopyWith<$Res>  {
  factory $AssociationsResultCopyWith(AssociationsResult value, $Res Function(AssociationsResult) _then) = _$AssociationsResultCopyWithImpl;
@useResult
$Res call({
 String documentId, List<AssociationItem> associations, String model, double latencyMs
});




}
/// @nodoc
class _$AssociationsResultCopyWithImpl<$Res>
    implements $AssociationsResultCopyWith<$Res> {
  _$AssociationsResultCopyWithImpl(this._self, this._then);

  final AssociationsResult _self;
  final $Res Function(AssociationsResult) _then;

/// Create a copy of AssociationsResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentId = null,Object? associations = null,Object? model = null,Object? latencyMs = null,}) {
  return _then(_self.copyWith(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,associations: null == associations ? _self.associations : associations // ignore: cast_nullable_to_non_nullable
as List<AssociationItem>,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [AssociationsResult].
extension AssociationsResultPatterns on AssociationsResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssociationsResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssociationsResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssociationsResult value)  $default,){
final _that = this;
switch (_that) {
case _AssociationsResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssociationsResult value)?  $default,){
final _that = this;
switch (_that) {
case _AssociationsResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String documentId,  List<AssociationItem> associations,  String model,  double latencyMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssociationsResult() when $default != null:
return $default(_that.documentId,_that.associations,_that.model,_that.latencyMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String documentId,  List<AssociationItem> associations,  String model,  double latencyMs)  $default,) {final _that = this;
switch (_that) {
case _AssociationsResult():
return $default(_that.documentId,_that.associations,_that.model,_that.latencyMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String documentId,  List<AssociationItem> associations,  String model,  double latencyMs)?  $default,) {final _that = this;
switch (_that) {
case _AssociationsResult() when $default != null:
return $default(_that.documentId,_that.associations,_that.model,_that.latencyMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssociationsResult implements AssociationsResult {
  const _AssociationsResult({required this.documentId, required final  List<AssociationItem> associations, required this.model, required this.latencyMs}): _associations = associations;
  factory _AssociationsResult.fromJson(Map<String, dynamic> json) => _$AssociationsResultFromJson(json);

@override final  String documentId;
 final  List<AssociationItem> _associations;
@override List<AssociationItem> get associations {
  if (_associations is EqualUnmodifiableListView) return _associations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_associations);
}

@override final  String model;
@override final  double latencyMs;

/// Create a copy of AssociationsResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssociationsResultCopyWith<_AssociationsResult> get copyWith => __$AssociationsResultCopyWithImpl<_AssociationsResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssociationsResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssociationsResult&&(identical(other.documentId, documentId) || other.documentId == documentId)&&const DeepCollectionEquality().equals(other._associations, _associations)&&(identical(other.model, model) || other.model == model)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documentId,const DeepCollectionEquality().hash(_associations),model,latencyMs);

@override
String toString() {
  return 'AssociationsResult(documentId: $documentId, associations: $associations, model: $model, latencyMs: $latencyMs)';
}


}

/// @nodoc
abstract mixin class _$AssociationsResultCopyWith<$Res> implements $AssociationsResultCopyWith<$Res> {
  factory _$AssociationsResultCopyWith(_AssociationsResult value, $Res Function(_AssociationsResult) _then) = __$AssociationsResultCopyWithImpl;
@override @useResult
$Res call({
 String documentId, List<AssociationItem> associations, String model, double latencyMs
});




}
/// @nodoc
class __$AssociationsResultCopyWithImpl<$Res>
    implements _$AssociationsResultCopyWith<$Res> {
  __$AssociationsResultCopyWithImpl(this._self, this._then);

  final _AssociationsResult _self;
  final $Res Function(_AssociationsResult) _then;

/// Create a copy of AssociationsResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentId = null,Object? associations = null,Object? model = null,Object? latencyMs = null,}) {
  return _then(_AssociationsResult(
documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,associations: null == associations ? _self._associations : associations // ignore: cast_nullable_to_non_nullable
as List<AssociationItem>,model: null == model ? _self.model : model // ignore: cast_nullable_to_non_nullable
as String,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
