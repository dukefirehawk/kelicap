// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'dart:collection';

import 'observable.dart' show Observable;
import 'observable_list.dart' show ObservableList;
import 'observable_map.dart' show ObservableMap;

/// Converts the [Iterable] or [Map] to an [ObservableList] or [ObservableMap],
/// respectively. This is a convenience function to make it easier to convert
/// literals into the corresponding observable collection type.
///
/// **Deprecated**: Use [toObservableList] or [toObservableMap] instead for
/// better static typing and type safety. This function returns `dynamic` types
/// which loses generic type information.
///
/// For better static typing, use either [toObservableList] or
/// [toObservableMap] instead of this function.
///
/// If [value] is not one of those collection types, or is already [Observable],
/// it will be returned unmodified.
///
/// If [value] is a [Map], the resulting value will use the appropriate kind of
/// backing map: either [HashMap], [LinkedHashMap], or [SplayTreeMap].
///
/// By default this performs a deep conversion, but you can set [deep] to false
/// for a shallow conversion. This does not handle circular data structures.
/// If a conversion is peformed, mutations are only observed to the result of
/// this function. Changing the original collection will not affect it.
// TODO(jmesserly): ObservableSet?
@Deprecated('Use toObservableList<T>() or toObservableMap<K, V>() instead')
dynamic toObservable(dynamic value, {bool deep = true}) =>
    deep ? _toObservableDeep(value) : _toObservableShallow(value);

/// Converts the [Iterable] to an [ObservableList].
///
/// If [value] is already [Observable], it will be returned unmodified.
///
/// By default this performs a deep conversion, but you can set [deep] to false
/// for a shallow conversion. This does not handle circular data structures.
/// If a conversion is peformed, mutations are only observed to the result of
/// this function. Changing the original collection will not affect it.
ObservableList<T> toObservableList<T>(Iterable<T> value, {bool deep = true}) {
  if (value is ObservableList<T>) return value;
  if (deep) {
    var result = ObservableList<T>();
    for (var element in value) {
      result.add(_toObservableDeep(element) as T);
    }
    return result;
  } else {
    return ObservableList<T>.from(value);
  }
}

/// Converts the [Map] to an [ObservableMap].
///
/// If [value] is already [Observable], it will be returned unmodified.
///
/// The returned value will use the appropriate kind of backing map: either
/// [HashMap], [LinkedHashMap], or [SplayTreeMap].
///
/// By default this performs a deep conversion, but you can set [deep] to false
/// for a shallow conversion. This does not handle circular data structures.
/// If a conversion is peformed, mutations are only observed to the result of
/// this function. Changing the original collection will not affect it.
ObservableMap<K, V> toObservableMap<K, V>(Map<K, V> value, {bool deep = true}) {
  if (value is ObservableMap<K, V>) return value;
  if (deep) {
    var result = ObservableMap<K, V>();
    value.forEach((k, v) {
      result[_toObservableDeep(k) as K] = _toObservableDeep(v) as V;
    });
    return result;
  } else {
    return ObservableMap<K, V>.from(value);
  }
}

dynamic _toObservableShallow(dynamic value) {
  if (value is Observable) return value;

  if (value is Map) {
    return ObservableMap<dynamic, dynamic>.from(value);
  }

  if (value is Iterable) {
    return ObservableList<dynamic>.from(value);
  }

  return value;
}

dynamic _toObservableDeep(dynamic value) {
  if (value is Observable) return value;

  if (value is Map) return _toObservableDeepMap(value);

  if (value is Iterable) return _toObservableDeepIterable(value);

  return value;
}

ObservableMap _toObservableDeepMap(Map<dynamic, dynamic> value) {
  var result = ObservableMap<dynamic, dynamic>();
  value.forEach((k, v) {
    result[_toObservableDeep(k)] = _toObservableDeep(v);
  });
  return result;
}

ObservableList _toObservableDeepIterable(Iterable<dynamic> value) {
  var result = ObservableList<dynamic>();
  for (var element in value) {
    result.add(_toObservableDeep(element));
  }
  return result;
}

class TypedMap<K, V> {
  final Map<K, V> map;

  TypedMap(this.map);

  // You always have direct access to K and V here without hacks
  Type get keyType => K;
  Type get valueType => V;

  R executeWithTypes<R>(R Function<TK, TV>(Map<TK, TV> typedMap) action) {
    return action<K, V>(map);
  }
}
