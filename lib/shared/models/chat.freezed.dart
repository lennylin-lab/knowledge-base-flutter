// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatRequest {

 String get question; int get limit;// Absent on the wire == null server-side; omitting the key keeps the
// first-question request identical to the pre-sessions wire shape.
@JsonKey(includeIfNull: false) String? get sessionId;
/// Create a copy of ChatRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatRequestCopyWith<ChatRequest> get copyWith => _$ChatRequestCopyWithImpl<ChatRequest>(this as ChatRequest, _$identity);

  /// Serializes this ChatRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatRequest&&(identical(other.question, question) || other.question == question)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,limit,sessionId);

@override
String toString() {
  return 'ChatRequest(question: $question, limit: $limit, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $ChatRequestCopyWith<$Res>  {
  factory $ChatRequestCopyWith(ChatRequest value, $Res Function(ChatRequest) _then) = _$ChatRequestCopyWithImpl;
@useResult
$Res call({
 String question, int limit,@JsonKey(includeIfNull: false) String? sessionId
});




}
/// @nodoc
class _$ChatRequestCopyWithImpl<$Res>
    implements $ChatRequestCopyWith<$Res> {
  _$ChatRequestCopyWithImpl(this._self, this._then);

  final ChatRequest _self;
  final $Res Function(ChatRequest) _then;

/// Create a copy of ChatRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? question = null,Object? limit = null,Object? sessionId = freezed,}) {
  return _then(_self.copyWith(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatRequest].
extension ChatRequestPatterns on ChatRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatRequest value)  $default,){
final _that = this;
switch (_that) {
case _ChatRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatRequest value)?  $default,){
final _that = this;
switch (_that) {
case _ChatRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String question,  int limit, @JsonKey(includeIfNull: false)  String? sessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatRequest() when $default != null:
return $default(_that.question,_that.limit,_that.sessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String question,  int limit, @JsonKey(includeIfNull: false)  String? sessionId)  $default,) {final _that = this;
switch (_that) {
case _ChatRequest():
return $default(_that.question,_that.limit,_that.sessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String question,  int limit, @JsonKey(includeIfNull: false)  String? sessionId)?  $default,) {final _that = this;
switch (_that) {
case _ChatRequest() when $default != null:
return $default(_that.question,_that.limit,_that.sessionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatRequest implements ChatRequest {
  const _ChatRequest({required this.question, this.limit = 8, @JsonKey(includeIfNull: false) this.sessionId});
  factory _ChatRequest.fromJson(Map<String, dynamic> json) => _$ChatRequestFromJson(json);

@override final  String question;
@override@JsonKey() final  int limit;
// Absent on the wire == null server-side; omitting the key keeps the
// first-question request identical to the pre-sessions wire shape.
@override@JsonKey(includeIfNull: false) final  String? sessionId;

/// Create a copy of ChatRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatRequestCopyWith<_ChatRequest> get copyWith => __$ChatRequestCopyWithImpl<_ChatRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatRequest&&(identical(other.question, question) || other.question == question)&&(identical(other.limit, limit) || other.limit == limit)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,limit,sessionId);

@override
String toString() {
  return 'ChatRequest(question: $question, limit: $limit, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$ChatRequestCopyWith<$Res> implements $ChatRequestCopyWith<$Res> {
  factory _$ChatRequestCopyWith(_ChatRequest value, $Res Function(_ChatRequest) _then) = __$ChatRequestCopyWithImpl;
@override @useResult
$Res call({
 String question, int limit,@JsonKey(includeIfNull: false) String? sessionId
});




}
/// @nodoc
class __$ChatRequestCopyWithImpl<$Res>
    implements _$ChatRequestCopyWith<$Res> {
  __$ChatRequestCopyWithImpl(this._self, this._then);

  final _ChatRequest _self;
  final $Res Function(_ChatRequest) _then;

/// Create a copy of ChatRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? question = null,Object? limit = null,Object? sessionId = freezed,}) {
  return _then(_ChatRequest(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$RunStarted {

 String get runId;@JsonKey(unknownEnumValue: SearchMode.bm25) SearchMode get mode; String? get sessionId;
/// Create a copy of RunStarted
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunStartedCopyWith<RunStarted> get copyWith => _$RunStartedCopyWithImpl<RunStarted>(this as RunStarted, _$identity);

  /// Serializes this RunStarted to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunStarted&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,mode,sessionId);

@override
String toString() {
  return 'RunStarted(runId: $runId, mode: $mode, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $RunStartedCopyWith<$Res>  {
  factory $RunStartedCopyWith(RunStarted value, $Res Function(RunStarted) _then) = _$RunStartedCopyWithImpl;
@useResult
$Res call({
 String runId,@JsonKey(unknownEnumValue: SearchMode.bm25) SearchMode mode, String? sessionId
});




}
/// @nodoc
class _$RunStartedCopyWithImpl<$Res>
    implements $RunStartedCopyWith<$Res> {
  _$RunStartedCopyWithImpl(this._self, this._then);

  final RunStarted _self;
  final $Res Function(RunStarted) _then;

/// Create a copy of RunStarted
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? mode = null,Object? sessionId = freezed,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SearchMode,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RunStarted].
extension RunStartedPatterns on RunStarted {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RunStarted value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RunStarted() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RunStarted value)  $default,){
final _that = this;
switch (_that) {
case _RunStarted():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RunStarted value)?  $default,){
final _that = this;
switch (_that) {
case _RunStarted() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId, @JsonKey(unknownEnumValue: SearchMode.bm25)  SearchMode mode,  String? sessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RunStarted() when $default != null:
return $default(_that.runId,_that.mode,_that.sessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId, @JsonKey(unknownEnumValue: SearchMode.bm25)  SearchMode mode,  String? sessionId)  $default,) {final _that = this;
switch (_that) {
case _RunStarted():
return $default(_that.runId,_that.mode,_that.sessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId, @JsonKey(unknownEnumValue: SearchMode.bm25)  SearchMode mode,  String? sessionId)?  $default,) {final _that = this;
switch (_that) {
case _RunStarted() when $default != null:
return $default(_that.runId,_that.mode,_that.sessionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RunStarted extends RunStarted {
  const _RunStarted({required this.runId, @JsonKey(unknownEnumValue: SearchMode.bm25) required this.mode, this.sessionId}): super._();
  factory _RunStarted.fromJson(Map<String, dynamic> json) => _$RunStartedFromJson(json);

@override final  String runId;
@override@JsonKey(unknownEnumValue: SearchMode.bm25) final  SearchMode mode;
@override final  String? sessionId;

/// Create a copy of RunStarted
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunStartedCopyWith<_RunStarted> get copyWith => __$RunStartedCopyWithImpl<_RunStarted>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RunStartedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RunStarted&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,mode,sessionId);

@override
String toString() {
  return 'RunStarted(runId: $runId, mode: $mode, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$RunStartedCopyWith<$Res> implements $RunStartedCopyWith<$Res> {
  factory _$RunStartedCopyWith(_RunStarted value, $Res Function(_RunStarted) _then) = __$RunStartedCopyWithImpl;
@override @useResult
$Res call({
 String runId,@JsonKey(unknownEnumValue: SearchMode.bm25) SearchMode mode, String? sessionId
});




}
/// @nodoc
class __$RunStartedCopyWithImpl<$Res>
    implements _$RunStartedCopyWith<$Res> {
  __$RunStartedCopyWithImpl(this._self, this._then);

  final _RunStarted _self;
  final $Res Function(_RunStarted) _then;

/// Create a copy of RunStarted
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? mode = null,Object? sessionId = freezed,}) {
  return _then(_RunStarted(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as SearchMode,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SourcesEvent {

 List<SearchHit> get items;
/// Create a copy of SourcesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourcesEventCopyWith<SourcesEvent> get copyWith => _$SourcesEventCopyWithImpl<SourcesEvent>(this as SourcesEvent, _$identity);

  /// Serializes this SourcesEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourcesEvent&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'SourcesEvent(items: $items)';
}


}

/// @nodoc
abstract mixin class $SourcesEventCopyWith<$Res>  {
  factory $SourcesEventCopyWith(SourcesEvent value, $Res Function(SourcesEvent) _then) = _$SourcesEventCopyWithImpl;
@useResult
$Res call({
 List<SearchHit> items
});




}
/// @nodoc
class _$SourcesEventCopyWithImpl<$Res>
    implements $SourcesEventCopyWith<$Res> {
  _$SourcesEventCopyWithImpl(this._self, this._then);

  final SourcesEvent _self;
  final $Res Function(SourcesEvent) _then;

/// Create a copy of SourcesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<SearchHit>,
  ));
}

}


/// Adds pattern-matching-related methods to [SourcesEvent].
extension SourcesEventPatterns on SourcesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SourcesEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SourcesEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SourcesEvent value)  $default,){
final _that = this;
switch (_that) {
case _SourcesEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SourcesEvent value)?  $default,){
final _that = this;
switch (_that) {
case _SourcesEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SearchHit> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SourcesEvent() when $default != null:
return $default(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SearchHit> items)  $default,) {final _that = this;
switch (_that) {
case _SourcesEvent():
return $default(_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SearchHit> items)?  $default,) {final _that = this;
switch (_that) {
case _SourcesEvent() when $default != null:
return $default(_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SourcesEvent extends SourcesEvent {
  const _SourcesEvent({final  List<SearchHit> items = const <SearchHit>[]}): _items = items,super._();
  factory _SourcesEvent.fromJson(Map<String, dynamic> json) => _$SourcesEventFromJson(json);

 final  List<SearchHit> _items;
@override@JsonKey() List<SearchHit> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of SourcesEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SourcesEventCopyWith<_SourcesEvent> get copyWith => __$SourcesEventCopyWithImpl<_SourcesEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourcesEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SourcesEvent&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'SourcesEvent(items: $items)';
}


}

/// @nodoc
abstract mixin class _$SourcesEventCopyWith<$Res> implements $SourcesEventCopyWith<$Res> {
  factory _$SourcesEventCopyWith(_SourcesEvent value, $Res Function(_SourcesEvent) _then) = __$SourcesEventCopyWithImpl;
@override @useResult
$Res call({
 List<SearchHit> items
});




}
/// @nodoc
class __$SourcesEventCopyWithImpl<$Res>
    implements _$SourcesEventCopyWith<$Res> {
  __$SourcesEventCopyWithImpl(this._self, this._then);

  final _SourcesEvent _self;
  final $Res Function(_SourcesEvent) _then;

/// Create a copy of SourcesEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(_SourcesEvent(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<SearchHit>,
  ));
}


}


/// @nodoc
mixin _$AnswerDelta {

 String get text;
/// Create a copy of AnswerDelta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswerDeltaCopyWith<AnswerDelta> get copyWith => _$AnswerDeltaCopyWithImpl<AnswerDelta>(this as AnswerDelta, _$identity);

  /// Serializes this AnswerDelta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnswerDelta&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'AnswerDelta(text: $text)';
}


}

/// @nodoc
abstract mixin class $AnswerDeltaCopyWith<$Res>  {
  factory $AnswerDeltaCopyWith(AnswerDelta value, $Res Function(AnswerDelta) _then) = _$AnswerDeltaCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$AnswerDeltaCopyWithImpl<$Res>
    implements $AnswerDeltaCopyWith<$Res> {
  _$AnswerDeltaCopyWithImpl(this._self, this._then);

  final AnswerDelta _self;
  final $Res Function(AnswerDelta) _then;

/// Create a copy of AnswerDelta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AnswerDelta].
extension AnswerDeltaPatterns on AnswerDelta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnswerDelta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnswerDelta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnswerDelta value)  $default,){
final _that = this;
switch (_that) {
case _AnswerDelta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnswerDelta value)?  $default,){
final _that = this;
switch (_that) {
case _AnswerDelta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnswerDelta() when $default != null:
return $default(_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text)  $default,) {final _that = this;
switch (_that) {
case _AnswerDelta():
return $default(_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text)?  $default,) {final _that = this;
switch (_that) {
case _AnswerDelta() when $default != null:
return $default(_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnswerDelta extends AnswerDelta {
  const _AnswerDelta({required this.text}): super._();
  factory _AnswerDelta.fromJson(Map<String, dynamic> json) => _$AnswerDeltaFromJson(json);

@override final  String text;

/// Create a copy of AnswerDelta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswerDeltaCopyWith<_AnswerDelta> get copyWith => __$AnswerDeltaCopyWithImpl<_AnswerDelta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnswerDeltaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnswerDelta&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'AnswerDelta(text: $text)';
}


}

/// @nodoc
abstract mixin class _$AnswerDeltaCopyWith<$Res> implements $AnswerDeltaCopyWith<$Res> {
  factory _$AnswerDeltaCopyWith(_AnswerDelta value, $Res Function(_AnswerDelta) _then) = __$AnswerDeltaCopyWithImpl;
@override @useResult
$Res call({
 String text
});




}
/// @nodoc
class __$AnswerDeltaCopyWithImpl<$Res>
    implements _$AnswerDeltaCopyWith<$Res> {
  __$AnswerDeltaCopyWithImpl(this._self, this._then);

  final _AnswerDelta _self;
  final $Res Function(_AnswerDelta) _then;

/// Create a copy of AnswerDelta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(_AnswerDelta(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatDone {

 String get runId; String get outcome; int get toolCalls; double get latencyMs; String? get sessionId;
/// Create a copy of ChatDone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatDoneCopyWith<ChatDone> get copyWith => _$ChatDoneCopyWithImpl<ChatDone>(this as ChatDone, _$identity);

  /// Serializes this ChatDone to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatDone&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.toolCalls, toolCalls) || other.toolCalls == toolCalls)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,outcome,toolCalls,latencyMs,sessionId);

@override
String toString() {
  return 'ChatDone(runId: $runId, outcome: $outcome, toolCalls: $toolCalls, latencyMs: $latencyMs, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $ChatDoneCopyWith<$Res>  {
  factory $ChatDoneCopyWith(ChatDone value, $Res Function(ChatDone) _then) = _$ChatDoneCopyWithImpl;
@useResult
$Res call({
 String runId, String outcome, int toolCalls, double latencyMs, String? sessionId
});




}
/// @nodoc
class _$ChatDoneCopyWithImpl<$Res>
    implements $ChatDoneCopyWith<$Res> {
  _$ChatDoneCopyWithImpl(this._self, this._then);

  final ChatDone _self;
  final $Res Function(ChatDone) _then;

/// Create a copy of ChatDone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? runId = null,Object? outcome = null,Object? toolCalls = null,Object? latencyMs = null,Object? sessionId = freezed,}) {
  return _then(_self.copyWith(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String,toolCalls: null == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as int,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as double,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatDone].
extension ChatDonePatterns on ChatDone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatDone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatDone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatDone value)  $default,){
final _that = this;
switch (_that) {
case _ChatDone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatDone value)?  $default,){
final _that = this;
switch (_that) {
case _ChatDone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String runId,  String outcome,  int toolCalls,  double latencyMs,  String? sessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatDone() when $default != null:
return $default(_that.runId,_that.outcome,_that.toolCalls,_that.latencyMs,_that.sessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String runId,  String outcome,  int toolCalls,  double latencyMs,  String? sessionId)  $default,) {final _that = this;
switch (_that) {
case _ChatDone():
return $default(_that.runId,_that.outcome,_that.toolCalls,_that.latencyMs,_that.sessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String runId,  String outcome,  int toolCalls,  double latencyMs,  String? sessionId)?  $default,) {final _that = this;
switch (_that) {
case _ChatDone() when $default != null:
return $default(_that.runId,_that.outcome,_that.toolCalls,_that.latencyMs,_that.sessionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatDone extends ChatDone {
  const _ChatDone({required this.runId, this.outcome = 'success', this.toolCalls = 0, this.latencyMs = 0, this.sessionId}): super._();
  factory _ChatDone.fromJson(Map<String, dynamic> json) => _$ChatDoneFromJson(json);

@override final  String runId;
@override@JsonKey() final  String outcome;
@override@JsonKey() final  int toolCalls;
@override@JsonKey() final  double latencyMs;
@override final  String? sessionId;

/// Create a copy of ChatDone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatDoneCopyWith<_ChatDone> get copyWith => __$ChatDoneCopyWithImpl<_ChatDone>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatDoneToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatDone&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.toolCalls, toolCalls) || other.toolCalls == toolCalls)&&(identical(other.latencyMs, latencyMs) || other.latencyMs == latencyMs)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,runId,outcome,toolCalls,latencyMs,sessionId);

@override
String toString() {
  return 'ChatDone(runId: $runId, outcome: $outcome, toolCalls: $toolCalls, latencyMs: $latencyMs, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$ChatDoneCopyWith<$Res> implements $ChatDoneCopyWith<$Res> {
  factory _$ChatDoneCopyWith(_ChatDone value, $Res Function(_ChatDone) _then) = __$ChatDoneCopyWithImpl;
@override @useResult
$Res call({
 String runId, String outcome, int toolCalls, double latencyMs, String? sessionId
});




}
/// @nodoc
class __$ChatDoneCopyWithImpl<$Res>
    implements _$ChatDoneCopyWith<$Res> {
  __$ChatDoneCopyWithImpl(this._self, this._then);

  final _ChatDone _self;
  final $Res Function(_ChatDone) _then;

/// Create a copy of ChatDone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? runId = null,Object? outcome = null,Object? toolCalls = null,Object? latencyMs = null,Object? sessionId = freezed,}) {
  return _then(_ChatDone(
runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as String,toolCalls: null == toolCalls ? _self.toolCalls : toolCalls // ignore: cast_nullable_to_non_nullable
as int,latencyMs: null == latencyMs ? _self.latencyMs : latencyMs // ignore: cast_nullable_to_non_nullable
as double,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ChatErrorEvent {

 String get code; String get message;
/// Create a copy of ChatErrorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatErrorEventCopyWith<ChatErrorEvent> get copyWith => _$ChatErrorEventCopyWithImpl<ChatErrorEvent>(this as ChatErrorEvent, _$identity);

  /// Serializes this ChatErrorEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatErrorEvent&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'ChatErrorEvent(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $ChatErrorEventCopyWith<$Res>  {
  factory $ChatErrorEventCopyWith(ChatErrorEvent value, $Res Function(ChatErrorEvent) _then) = _$ChatErrorEventCopyWithImpl;
@useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class _$ChatErrorEventCopyWithImpl<$Res>
    implements $ChatErrorEventCopyWith<$Res> {
  _$ChatErrorEventCopyWithImpl(this._self, this._then);

  final ChatErrorEvent _self;
  final $Res Function(ChatErrorEvent) _then;

/// Create a copy of ChatErrorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatErrorEvent].
extension ChatErrorEventPatterns on ChatErrorEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatErrorEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatErrorEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatErrorEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChatErrorEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatErrorEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChatErrorEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatErrorEvent() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message)  $default,) {final _that = this;
switch (_that) {
case _ChatErrorEvent():
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _ChatErrorEvent() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatErrorEvent extends ChatErrorEvent {
  const _ChatErrorEvent({required this.code, required this.message}): super._();
  factory _ChatErrorEvent.fromJson(Map<String, dynamic> json) => _$ChatErrorEventFromJson(json);

@override final  String code;
@override final  String message;

/// Create a copy of ChatErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatErrorEventCopyWith<_ChatErrorEvent> get copyWith => __$ChatErrorEventCopyWithImpl<_ChatErrorEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatErrorEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatErrorEvent&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'ChatErrorEvent(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ChatErrorEventCopyWith<$Res> implements $ChatErrorEventCopyWith<$Res> {
  factory _$ChatErrorEventCopyWith(_ChatErrorEvent value, $Res Function(_ChatErrorEvent) _then) = __$ChatErrorEventCopyWithImpl;
@override @useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class __$ChatErrorEventCopyWithImpl<$Res>
    implements _$ChatErrorEventCopyWith<$Res> {
  __$ChatErrorEventCopyWithImpl(this._self, this._then);

  final _ChatErrorEvent _self;
  final $Res Function(_ChatErrorEvent) _then;

/// Create a copy of ChatErrorEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(_ChatErrorEvent(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
