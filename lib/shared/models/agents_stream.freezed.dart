// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agents_stream.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AgentRunStarted {

 String get runId; String get kind; String get documentId;
/// Create a copy of AgentRunStarted
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentRunStartedCopyWith<AgentRunStarted> get copyWith => _$AgentRunStartedCopyWithImpl<AgentRunStarted>(this as AgentRunStarted, _$identity);

  /// Serializes this AgentRunStarted to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentRunStarted&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.documentId, documentId) || other.documentId == documentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,kind,documentId);

@override
String toString() {
  return 'AgentRunStarted(runId: $runId, kind: $kind, documentId: $documentId)';
}


}

/// @nodoc
abstract mixin class $AgentRunStartedCopyWith<$Res>  {
  factory $AgentRunStartedCopyWith(AgentRunStarted value, $Res Function(AgentRunStarted) _then) = _$AgentRunStartedCopyWithImpl;
@useResult
$Res call({
 String runId, String kind, String documentId
});




}
/// @nodoc
class _$AgentRunStartedCopyWithImpl<$Res>
    implements $AgentRunStartedCopyWith<$Res> {
  _$AgentRunStartedCopyWithImpl(this._self, this._then);

  final AgentRunStarted _self;
  final $Res Function(AgentRunStarted) _then;

/// Create a copy of AgentRunStarted
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? kind = null,Object? documentId = null,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentRunStarted].
extension AgentRunStartedPatterns on AgentRunStarted {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentRunStarted value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentRunStarted() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentRunStarted value)  $default,){
final _that = this;
switch (_that) {
case _AgentRunStarted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentRunStarted value)?  $default,){
final _that = this;
switch (_that) {
case _AgentRunStarted() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String kind,  String documentId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentRunStarted() when $default != null:
return $default(_that.runId,_that.kind,_that.documentId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String kind,  String documentId)  $default,) {final _that = this;
switch (_that) {
case _AgentRunStarted():
return $default(_that.runId,_that.kind,_that.documentId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String kind,  String documentId)?  $default,) {final _that = this;
switch (_that) {
case _AgentRunStarted() when $default != null:
return $default(_that.runId,_that.kind,_that.documentId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentRunStarted extends AgentRunStarted {
  const _AgentRunStarted({required this.runId, required this.kind, required this.documentId}): super._();
  factory _AgentRunStarted.fromJson(Map<String, dynamic> json) => _$AgentRunStartedFromJson(json);

@override final  String runId;
@override final  String kind;
@override final  String documentId;

/// Create a copy of AgentRunStarted
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentRunStartedCopyWith<_AgentRunStarted> get copyWith => __$AgentRunStartedCopyWithImpl<_AgentRunStarted>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentRunStartedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentRunStarted&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.documentId, documentId) || other.documentId == documentId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,kind,documentId);

@override
String toString() {
  return 'AgentRunStarted(runId: $runId, kind: $kind, documentId: $documentId)';
}


}

/// @nodoc
abstract mixin class _$AgentRunStartedCopyWith<$Res> implements $AgentRunStartedCopyWith<$Res> {
  factory _$AgentRunStartedCopyWith(_AgentRunStarted value, $Res Function(_AgentRunStarted) _then) = __$AgentRunStartedCopyWithImpl;
@override @useResult
$Res call({
 String runId, String kind, String documentId
});




}
/// @nodoc
class __$AgentRunStartedCopyWithImpl<$Res>
    implements _$AgentRunStartedCopyWith<$Res> {
  __$AgentRunStartedCopyWithImpl(this._self, this._then);

  final _AgentRunStarted _self;
  final $Res Function(_AgentRunStarted) _then;

/// Create a copy of AgentRunStarted
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? kind = null,Object? documentId = null,}) {
  return _then(_AgentRunStarted(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SummaryProgress {

 String get phase; int get passIndex; int get passesTotal;
/// Create a copy of SummaryProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SummaryProgressCopyWith<SummaryProgress> get copyWith => _$SummaryProgressCopyWithImpl<SummaryProgress>(this as SummaryProgress, _$identity);

  /// Serializes this SummaryProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SummaryProgress&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.passIndex, passIndex) || other.passIndex == passIndex)&&(identical(other.passesTotal, passesTotal) || other.passesTotal == passesTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,passIndex,passesTotal);

@override
String toString() {
  return 'SummaryProgress(phase: $phase, passIndex: $passIndex, passesTotal: $passesTotal)';
}


}

/// @nodoc
abstract mixin class $SummaryProgressCopyWith<$Res>  {
  factory $SummaryProgressCopyWith(SummaryProgress value, $Res Function(SummaryProgress) _then) = _$SummaryProgressCopyWithImpl;
@useResult
$Res call({
 String phase, int passIndex, int passesTotal
});




}
/// @nodoc
class _$SummaryProgressCopyWithImpl<$Res>
    implements $SummaryProgressCopyWith<$Res> {
  _$SummaryProgressCopyWithImpl(this._self, this._then);

  final SummaryProgress _self;
  final $Res Function(SummaryProgress) _then;

/// Create a copy of SummaryProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? passIndex = null,Object? passesTotal = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,passIndex: null == passIndex ? _self.passIndex : passIndex // ignore: cast_nullable_to_non_nullable
as int,passesTotal: null == passesTotal ? _self.passesTotal : passesTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SummaryProgress].
extension SummaryProgressPatterns on SummaryProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SummaryProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SummaryProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SummaryProgress value)  $default,){
final _that = this;
switch (_that) {
case _SummaryProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SummaryProgress value)?  $default,){
final _that = this;
switch (_that) {
case _SummaryProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phase,  int passIndex,  int passesTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SummaryProgress() when $default != null:
return $default(_that.phase,_that.passIndex,_that.passesTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phase,  int passIndex,  int passesTotal)  $default,) {final _that = this;
switch (_that) {
case _SummaryProgress():
return $default(_that.phase,_that.passIndex,_that.passesTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phase,  int passIndex,  int passesTotal)?  $default,) {final _that = this;
switch (_that) {
case _SummaryProgress() when $default != null:
return $default(_that.phase,_that.passIndex,_that.passesTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SummaryProgress extends SummaryProgress {
  const _SummaryProgress({required this.phase, required this.passIndex, required this.passesTotal}): super._();
  factory _SummaryProgress.fromJson(Map<String, dynamic> json) => _$SummaryProgressFromJson(json);

@override final  String phase;
@override final  int passIndex;
@override final  int passesTotal;

/// Create a copy of SummaryProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SummaryProgressCopyWith<_SummaryProgress> get copyWith => __$SummaryProgressCopyWithImpl<_SummaryProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SummaryProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SummaryProgress&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.passIndex, passIndex) || other.passIndex == passIndex)&&(identical(other.passesTotal, passesTotal) || other.passesTotal == passesTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,passIndex,passesTotal);

@override
String toString() {
  return 'SummaryProgress(phase: $phase, passIndex: $passIndex, passesTotal: $passesTotal)';
}


}

/// @nodoc
abstract mixin class _$SummaryProgressCopyWith<$Res> implements $SummaryProgressCopyWith<$Res> {
  factory _$SummaryProgressCopyWith(_SummaryProgress value, $Res Function(_SummaryProgress) _then) = __$SummaryProgressCopyWithImpl;
@override @useResult
$Res call({
 String phase, int passIndex, int passesTotal
});




}
/// @nodoc
class __$SummaryProgressCopyWithImpl<$Res>
    implements _$SummaryProgressCopyWith<$Res> {
  __$SummaryProgressCopyWithImpl(this._self, this._then);

  final _SummaryProgress _self;
  final $Res Function(_SummaryProgress) _then;

/// Create a copy of SummaryProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? passIndex = null,Object? passesTotal = null,}) {
  return _then(_SummaryProgress(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,passIndex: null == passIndex ? _self.passIndex : passIndex // ignore: cast_nullable_to_non_nullable
as int,passesTotal: null == passesTotal ? _self.passesTotal : passesTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AgentSummaryDeltaEvent {

 String get runId; String get text;
/// Create a copy of AgentSummaryDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentSummaryDeltaEventCopyWith<AgentSummaryDeltaEvent> get copyWith => _$AgentSummaryDeltaEventCopyWithImpl<AgentSummaryDeltaEvent>(this as AgentSummaryDeltaEvent, _$identity);

  /// Serializes this AgentSummaryDeltaEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentSummaryDeltaEvent&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,text);

@override
String toString() {
  return 'AgentSummaryDeltaEvent(runId: $runId, text: $text)';
}


}

/// @nodoc
abstract mixin class $AgentSummaryDeltaEventCopyWith<$Res>  {
  factory $AgentSummaryDeltaEventCopyWith(AgentSummaryDeltaEvent value, $Res Function(AgentSummaryDeltaEvent) _then) = _$AgentSummaryDeltaEventCopyWithImpl;
@useResult
$Res call({
 String runId, String text
});




}
/// @nodoc
class _$AgentSummaryDeltaEventCopyWithImpl<$Res>
    implements $AgentSummaryDeltaEventCopyWith<$Res> {
  _$AgentSummaryDeltaEventCopyWithImpl(this._self, this._then);

  final AgentSummaryDeltaEvent _self;
  final $Res Function(AgentSummaryDeltaEvent) _then;

/// Create a copy of AgentSummaryDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? text = null,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentSummaryDeltaEvent].
extension AgentSummaryDeltaEventPatterns on AgentSummaryDeltaEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentSummaryDeltaEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentSummaryDeltaEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentSummaryDeltaEvent value)  $default,){
final _that = this;
switch (_that) {
case _AgentSummaryDeltaEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentSummaryDeltaEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AgentSummaryDeltaEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentSummaryDeltaEvent() when $default != null:
return $default(_that.runId,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String text)  $default,) {final _that = this;
switch (_that) {
case _AgentSummaryDeltaEvent():
return $default(_that.runId,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String text)?  $default,) {final _that = this;
switch (_that) {
case _AgentSummaryDeltaEvent() when $default != null:
return $default(_that.runId,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentSummaryDeltaEvent extends AgentSummaryDeltaEvent {
  const _AgentSummaryDeltaEvent({required this.runId, required this.text}): super._();
  factory _AgentSummaryDeltaEvent.fromJson(Map<String, dynamic> json) => _$AgentSummaryDeltaEventFromJson(json);

@override final  String runId;
@override final  String text;

/// Create a copy of AgentSummaryDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentSummaryDeltaEventCopyWith<_AgentSummaryDeltaEvent> get copyWith => __$AgentSummaryDeltaEventCopyWithImpl<_AgentSummaryDeltaEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentSummaryDeltaEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentSummaryDeltaEvent&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,text);

@override
String toString() {
  return 'AgentSummaryDeltaEvent(runId: $runId, text: $text)';
}


}

/// @nodoc
abstract mixin class _$AgentSummaryDeltaEventCopyWith<$Res> implements $AgentSummaryDeltaEventCopyWith<$Res> {
  factory _$AgentSummaryDeltaEventCopyWith(_AgentSummaryDeltaEvent value, $Res Function(_AgentSummaryDeltaEvent) _then) = __$AgentSummaryDeltaEventCopyWithImpl;
@override @useResult
$Res call({
 String runId, String text
});




}
/// @nodoc
class __$AgentSummaryDeltaEventCopyWithImpl<$Res>
    implements _$AgentSummaryDeltaEventCopyWith<$Res> {
  __$AgentSummaryDeltaEventCopyWithImpl(this._self, this._then);

  final _AgentSummaryDeltaEvent _self;
  final $Res Function(_AgentSummaryDeltaEvent) _then;

/// Create a copy of AgentSummaryDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? text = null,}) {
  return _then(_AgentSummaryDeltaEvent(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AgentAssociationItemEvent {

 String get runId; int get position; String get documentId; String get title; List<String> get tags; String get reason; String get signal;
/// Create a copy of AgentAssociationItemEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentAssociationItemEventCopyWith<AgentAssociationItemEvent> get copyWith => _$AgentAssociationItemEventCopyWithImpl<AgentAssociationItemEvent>(this as AgentAssociationItemEvent, _$identity);

  /// Serializes this AgentAssociationItemEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentAssociationItemEvent&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.position, position) || other.position == position)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.signal, signal) || other.signal == signal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,position,documentId,title,const DeepCollectionEquality().hash(tags),reason,signal);

@override
String toString() {
  return 'AgentAssociationItemEvent(runId: $runId, position: $position, documentId: $documentId, title: $title, tags: $tags, reason: $reason, signal: $signal)';
}


}

/// @nodoc
abstract mixin class $AgentAssociationItemEventCopyWith<$Res>  {
  factory $AgentAssociationItemEventCopyWith(AgentAssociationItemEvent value, $Res Function(AgentAssociationItemEvent) _then) = _$AgentAssociationItemEventCopyWithImpl;
@useResult
$Res call({
 String runId, int position, String documentId, String title, List<String> tags, String reason, String signal
});




}
/// @nodoc
class _$AgentAssociationItemEventCopyWithImpl<$Res>
    implements $AgentAssociationItemEventCopyWith<$Res> {
  _$AgentAssociationItemEventCopyWithImpl(this._self, this._then);

  final AgentAssociationItemEvent _self;
  final $Res Function(AgentAssociationItemEvent) _then;

/// Create a copy of AgentAssociationItemEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? position = null,Object? documentId = null,Object? title = null,Object? tags = null,Object? reason = null,Object? signal = null,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,signal: null == signal ? _self.signal : signal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentAssociationItemEvent].
extension AgentAssociationItemEventPatterns on AgentAssociationItemEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentAssociationItemEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentAssociationItemEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentAssociationItemEvent value)  $default,){
final _that = this;
switch (_that) {
case _AgentAssociationItemEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentAssociationItemEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AgentAssociationItemEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  int position,  String documentId,  String title,  List<String> tags,  String reason,  String signal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentAssociationItemEvent() when $default != null:
return $default(_that.runId,_that.position,_that.documentId,_that.title,_that.tags,_that.reason,_that.signal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  int position,  String documentId,  String title,  List<String> tags,  String reason,  String signal)  $default,) {final _that = this;
switch (_that) {
case _AgentAssociationItemEvent():
return $default(_that.runId,_that.position,_that.documentId,_that.title,_that.tags,_that.reason,_that.signal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  int position,  String documentId,  String title,  List<String> tags,  String reason,  String signal)?  $default,) {final _that = this;
switch (_that) {
case _AgentAssociationItemEvent() when $default != null:
return $default(_that.runId,_that.position,_that.documentId,_that.title,_that.tags,_that.reason,_that.signal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentAssociationItemEvent extends AgentAssociationItemEvent {
  const _AgentAssociationItemEvent({required this.runId, required this.position, required this.documentId, required this.title, required final  List<String> tags, required this.reason, required this.signal}): _tags = tags,super._();
  factory _AgentAssociationItemEvent.fromJson(Map<String, dynamic> json) => _$AgentAssociationItemEventFromJson(json);

@override final  String runId;
@override final  int position;
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

/// Create a copy of AgentAssociationItemEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentAssociationItemEventCopyWith<_AgentAssociationItemEvent> get copyWith => __$AgentAssociationItemEventCopyWithImpl<_AgentAssociationItemEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentAssociationItemEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentAssociationItemEvent&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.position, position) || other.position == position)&&(identical(other.documentId, documentId) || other.documentId == documentId)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.signal, signal) || other.signal == signal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,position,documentId,title,const DeepCollectionEquality().hash(_tags),reason,signal);

@override
String toString() {
  return 'AgentAssociationItemEvent(runId: $runId, position: $position, documentId: $documentId, title: $title, tags: $tags, reason: $reason, signal: $signal)';
}


}

/// @nodoc
abstract mixin class _$AgentAssociationItemEventCopyWith<$Res> implements $AgentAssociationItemEventCopyWith<$Res> {
  factory _$AgentAssociationItemEventCopyWith(_AgentAssociationItemEvent value, $Res Function(_AgentAssociationItemEvent) _then) = __$AgentAssociationItemEventCopyWithImpl;
@override @useResult
$Res call({
 String runId, int position, String documentId, String title, List<String> tags, String reason, String signal
});




}
/// @nodoc
class __$AgentAssociationItemEventCopyWithImpl<$Res>
    implements _$AgentAssociationItemEventCopyWith<$Res> {
  __$AgentAssociationItemEventCopyWithImpl(this._self, this._then);

  final _AgentAssociationItemEvent _self;
  final $Res Function(_AgentAssociationItemEvent) _then;

/// Create a copy of AgentAssociationItemEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? position = null,Object? documentId = null,Object? title = null,Object? tags = null,Object? reason = null,Object? signal = null,}) {
  return _then(_AgentAssociationItemEvent(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,documentId: null == documentId ? _self.documentId : documentId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,signal: null == signal ? _self.signal : signal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AgentDraftDeltaEvent {

 String get runId; String get delta;
/// Create a copy of AgentDraftDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentDraftDeltaEventCopyWith<AgentDraftDeltaEvent> get copyWith => _$AgentDraftDeltaEventCopyWithImpl<AgentDraftDeltaEvent>(this as AgentDraftDeltaEvent, _$identity);

  /// Serializes this AgentDraftDeltaEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentDraftDeltaEvent&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.delta, delta) || other.delta == delta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,delta);

@override
String toString() {
  return 'AgentDraftDeltaEvent(runId: $runId, delta: $delta)';
}


}

/// @nodoc
abstract mixin class $AgentDraftDeltaEventCopyWith<$Res>  {
  factory $AgentDraftDeltaEventCopyWith(AgentDraftDeltaEvent value, $Res Function(AgentDraftDeltaEvent) _then) = _$AgentDraftDeltaEventCopyWithImpl;
@useResult
$Res call({
 String runId, String delta
});




}
/// @nodoc
class _$AgentDraftDeltaEventCopyWithImpl<$Res>
    implements $AgentDraftDeltaEventCopyWith<$Res> {
  _$AgentDraftDeltaEventCopyWithImpl(this._self, this._then);

  final AgentDraftDeltaEvent _self;
  final $Res Function(AgentDraftDeltaEvent) _then;

/// Create a copy of AgentDraftDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? delta = null,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentDraftDeltaEvent].
extension AgentDraftDeltaEventPatterns on AgentDraftDeltaEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentDraftDeltaEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentDraftDeltaEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentDraftDeltaEvent value)  $default,){
final _that = this;
switch (_that) {
case _AgentDraftDeltaEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentDraftDeltaEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AgentDraftDeltaEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String delta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentDraftDeltaEvent() when $default != null:
return $default(_that.runId,_that.delta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String delta)  $default,) {final _that = this;
switch (_that) {
case _AgentDraftDeltaEvent():
return $default(_that.runId,_that.delta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String delta)?  $default,) {final _that = this;
switch (_that) {
case _AgentDraftDeltaEvent() when $default != null:
return $default(_that.runId,_that.delta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentDraftDeltaEvent extends AgentDraftDeltaEvent {
  const _AgentDraftDeltaEvent({required this.runId, required this.delta}): super._();
  factory _AgentDraftDeltaEvent.fromJson(Map<String, dynamic> json) => _$AgentDraftDeltaEventFromJson(json);

@override final  String runId;
@override final  String delta;

/// Create a copy of AgentDraftDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentDraftDeltaEventCopyWith<_AgentDraftDeltaEvent> get copyWith => __$AgentDraftDeltaEventCopyWithImpl<_AgentDraftDeltaEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentDraftDeltaEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentDraftDeltaEvent&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.delta, delta) || other.delta == delta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,delta);

@override
String toString() {
  return 'AgentDraftDeltaEvent(runId: $runId, delta: $delta)';
}


}

/// @nodoc
abstract mixin class _$AgentDraftDeltaEventCopyWith<$Res> implements $AgentDraftDeltaEventCopyWith<$Res> {
  factory _$AgentDraftDeltaEventCopyWith(_AgentDraftDeltaEvent value, $Res Function(_AgentDraftDeltaEvent) _then) = __$AgentDraftDeltaEventCopyWithImpl;
@override @useResult
$Res call({
 String runId, String delta
});




}
/// @nodoc
class __$AgentDraftDeltaEventCopyWithImpl<$Res>
    implements _$AgentDraftDeltaEventCopyWith<$Res> {
  __$AgentDraftDeltaEventCopyWithImpl(this._self, this._then);

  final _AgentDraftDeltaEvent _self;
  final $Res Function(_AgentDraftDeltaEvent) _then;

/// Create a copy of AgentDraftDeltaEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? delta = null,}) {
  return _then(_AgentDraftDeltaEvent(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,delta: null == delta ? _self.delta : delta // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AgentDraftEvent {

 String get operationId; String get state; String get content; String? get title;
/// Create a copy of AgentDraftEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentDraftEventCopyWith<AgentDraftEvent> get copyWith => _$AgentDraftEventCopyWithImpl<AgentDraftEvent>(this as AgentDraftEvent, _$identity);

  /// Serializes this AgentDraftEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentDraftEvent&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.state, state) || other.state == state)&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,state,content,title);

@override
String toString() {
  return 'AgentDraftEvent(operationId: $operationId, state: $state, content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class $AgentDraftEventCopyWith<$Res>  {
  factory $AgentDraftEventCopyWith(AgentDraftEvent value, $Res Function(AgentDraftEvent) _then) = _$AgentDraftEventCopyWithImpl;
@useResult
$Res call({
 String operationId, String state, String content, String? title
});




}
/// @nodoc
class _$AgentDraftEventCopyWithImpl<$Res>
    implements $AgentDraftEventCopyWith<$Res> {
  _$AgentDraftEventCopyWithImpl(this._self, this._then);

  final AgentDraftEvent _self;
  final $Res Function(AgentDraftEvent) _then;

/// Create a copy of AgentDraftEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? operationId = null,Object? state = null,Object? content = null,Object? title = freezed,}) {
  return _then(_self.copyWith(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentDraftEvent].
extension AgentDraftEventPatterns on AgentDraftEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentDraftEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentDraftEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentDraftEvent value)  $default,){
final _that = this;
switch (_that) {
case _AgentDraftEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentDraftEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AgentDraftEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String operationId,  String state,  String content,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentDraftEvent() when $default != null:
return $default(_that.operationId,_that.state,_that.content,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String operationId,  String state,  String content,  String? title)  $default,) {final _that = this;
switch (_that) {
case _AgentDraftEvent():
return $default(_that.operationId,_that.state,_that.content,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String operationId,  String state,  String content,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _AgentDraftEvent() when $default != null:
return $default(_that.operationId,_that.state,_that.content,_that.title);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentDraftEvent extends AgentDraftEvent {
  const _AgentDraftEvent({required this.operationId, required this.state, required this.content, this.title}): super._();
  factory _AgentDraftEvent.fromJson(Map<String, dynamic> json) => _$AgentDraftEventFromJson(json);

@override final  String operationId;
@override final  String state;
@override final  String content;
@override final  String? title;

/// Create a copy of AgentDraftEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentDraftEventCopyWith<_AgentDraftEvent> get copyWith => __$AgentDraftEventCopyWithImpl<_AgentDraftEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentDraftEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentDraftEvent&&(identical(other.operationId, operationId) || other.operationId == operationId)&&(identical(other.state, state) || other.state == state)&&(identical(other.content, content) || other.content == content)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,operationId,state,content,title);

@override
String toString() {
  return 'AgentDraftEvent(operationId: $operationId, state: $state, content: $content, title: $title)';
}


}

/// @nodoc
abstract mixin class _$AgentDraftEventCopyWith<$Res> implements $AgentDraftEventCopyWith<$Res> {
  factory _$AgentDraftEventCopyWith(_AgentDraftEvent value, $Res Function(_AgentDraftEvent) _then) = __$AgentDraftEventCopyWithImpl;
@override @useResult
$Res call({
 String operationId, String state, String content, String? title
});




}
/// @nodoc
class __$AgentDraftEventCopyWithImpl<$Res>
    implements _$AgentDraftEventCopyWith<$Res> {
  __$AgentDraftEventCopyWithImpl(this._self, this._then);

  final _AgentDraftEvent _self;
  final $Res Function(_AgentDraftEvent) _then;

/// Create a copy of AgentDraftEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? operationId = null,Object? state = null,Object? content = null,Object? title = freezed,}) {
  return _then(_AgentDraftEvent(
operationId: null == operationId ? _self.operationId : operationId // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AgentErrorEvent {

 String get code; String get message;@JsonKey(includeIfNull: false) int? get statusCode;
/// Create a copy of AgentErrorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AgentErrorEventCopyWith<AgentErrorEvent> get copyWith => _$AgentErrorEventCopyWithImpl<AgentErrorEvent>(this as AgentErrorEvent, _$identity);

  /// Serializes this AgentErrorEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AgentErrorEvent&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,statusCode);

@override
String toString() {
  return 'AgentErrorEvent(code: $code, message: $message, statusCode: $statusCode)';
}


}

/// @nodoc
abstract mixin class $AgentErrorEventCopyWith<$Res>  {
  factory $AgentErrorEventCopyWith(AgentErrorEvent value, $Res Function(AgentErrorEvent) _then) = _$AgentErrorEventCopyWithImpl;
@useResult
$Res call({
 String code, String message,@JsonKey(includeIfNull: false) int? statusCode
});




}
/// @nodoc
class _$AgentErrorEventCopyWithImpl<$Res>
    implements $AgentErrorEventCopyWith<$Res> {
  _$AgentErrorEventCopyWithImpl(this._self, this._then);

  final AgentErrorEvent _self;
  final $Res Function(AgentErrorEvent) _then;

/// Create a copy of AgentErrorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? statusCode = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AgentErrorEvent].
extension AgentErrorEventPatterns on AgentErrorEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AgentErrorEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AgentErrorEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AgentErrorEvent value)  $default,){
final _that = this;
switch (_that) {
case _AgentErrorEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AgentErrorEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AgentErrorEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message, @JsonKey(includeIfNull: false)  int? statusCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AgentErrorEvent() when $default != null:
return $default(_that.code,_that.message,_that.statusCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message, @JsonKey(includeIfNull: false)  int? statusCode)  $default,) {final _that = this;
switch (_that) {
case _AgentErrorEvent():
return $default(_that.code,_that.message,_that.statusCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message, @JsonKey(includeIfNull: false)  int? statusCode)?  $default,) {final _that = this;
switch (_that) {
case _AgentErrorEvent() when $default != null:
return $default(_that.code,_that.message,_that.statusCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AgentErrorEvent extends AgentErrorEvent {
  const _AgentErrorEvent({required this.code, required this.message, @JsonKey(includeIfNull: false) this.statusCode}): super._();
  factory _AgentErrorEvent.fromJson(Map<String, dynamic> json) => _$AgentErrorEventFromJson(json);

@override final  String code;
@override final  String message;
@override@JsonKey(includeIfNull: false) final  int? statusCode;

/// Create a copy of AgentErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AgentErrorEventCopyWith<_AgentErrorEvent> get copyWith => __$AgentErrorEventCopyWithImpl<_AgentErrorEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AgentErrorEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AgentErrorEvent&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,statusCode);

@override
String toString() {
  return 'AgentErrorEvent(code: $code, message: $message, statusCode: $statusCode)';
}


}

/// @nodoc
abstract mixin class _$AgentErrorEventCopyWith<$Res> implements $AgentErrorEventCopyWith<$Res> {
  factory _$AgentErrorEventCopyWith(_AgentErrorEvent value, $Res Function(_AgentErrorEvent) _then) = __$AgentErrorEventCopyWithImpl;
@override @useResult
$Res call({
 String code, String message,@JsonKey(includeIfNull: false) int? statusCode
});




}
/// @nodoc
class __$AgentErrorEventCopyWithImpl<$Res>
    implements _$AgentErrorEventCopyWith<$Res> {
  __$AgentErrorEventCopyWithImpl(this._self, this._then);

  final _AgentErrorEvent _self;
  final $Res Function(_AgentErrorEvent) _then;

/// Create a copy of AgentErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? statusCode = freezed,}) {
  return _then(_AgentErrorEvent(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
