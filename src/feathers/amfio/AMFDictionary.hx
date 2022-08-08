/*
	AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import openfl.utils.Dictionary;

/**
	Stores data from the AMF dictionary type, which is similar to a map. Unlike
	Haxe maps, AMF dictionaries can hold a mix of data types.
**/
@:transitive
@:forward
abstract AMFDictionary<K, V>(AMFDictionaryData<K, V>) from AMFDictionaryData<K, V> to AMFDictionaryData<K, V> {
	/**
		Creates a new `AMFDictionary` instance.
	**/
	public function new(weakKeys:Bool = false) {
		this = new AMFDictionaryData<K, V>(weakKeys);
	}

	/**
		Converts an `openfl.utils.Dictionary` into an `AMFDictionary`.
	**/
	@:from
	private inline static function fromDictionary<K, V>(dict:Dictionary<K, V>) {
		var newDict = new AMFDictionaryData<K, V>(false);
		var keys = @:privateAccess newDict.keys;
		var values = @:privateAccess newDict.values;
		for (key in dict) {
			keys.push(key);
			values.push(dict[key]);
		}
		return cast newDict;
	}

	/**
		Converts a map into an `AMFDictionary`.
	**/
	@:from
	private inline static function fromMap<K, V>(map:Map<K, V>) {
		var dict = new AMFDictionaryData<K, V>(false);
		var keys = @:privateAccess dict.keys;
		var values = @:privateAccess dict.values;
		for (key => value in map) {
			keys.push(key);
			values.push(value);
		}
		return cast dict;
	}

	/**
		Gets a value using array `[]` access.
	**/
	@:arrayAccess
	public inline function get(key:K):V {
		var keys = @:privateAccess this.keys;
		var values = @:privateAccess this.values;
		var index = keys.indexOf(key);
		if (index == -1) {
			return null;
		}
		return values[index];
	}

	/**
		Sets a value using array `[]` access.
	**/
	@:arrayAccess
	public inline function set(key:K, value:V):V {
		var keys = @:privateAccess this.keys;
		var values = @:privateAccess this.values;
		var index = keys.indexOf(key);
		if (index == -1) {
			index = keys.length;
			keys.push(key);
			values.push(value);
			return value;
		}
		values[index] = value;
		return value;
	}
}

/**
	Stores data for the `AMFDictionary` abstract.
**/
class AMFDictionaryData<K, V> {
	private var keys:Array<K>;
	private var values:Array<V>;
	private var weakKeys:Bool;

	/**
		Creates a new `AMFDictionaryData` instance.
	**/
	public function new(weakKeys:Bool = false) {
		this.weakKeys = weakKeys;
		keys = [];
		values = [];
	}

	/**
		Removes a key from the dictionary.
	**/
	public function remove(key:K):Bool {
		var index = keys.indexOf(key);
		if (index == -1) {
			return false;
		}
		values.splice(index, 1);
		return true;
	}

	/**
		Creates an iterator for the keys of the `AMFDictionary`.
	**/
	public inline function iterator():Iterator<K> {
		return this.keys.iterator();
	}

	/**
		Creates a key-value iterator for the `AMFDictionary`.
	**/
	public inline function keyValueIterator():AMFDictionaryKeyValueIterator<K, V> {
		return new AMFDictionaryKeyValueIterator(this);
	}
}

/**
	This iterator is used when `keyValueIterator()` is called on an
	`AMFDictionary` instance.
**/
class AMFDictionaryKeyValueIterator<K, V> {
	private var keyIterator:Iterator<K>;
	private var valueIterator:Iterator<V>;

	/**
		Creates a new `AMFDictionaryKeyValueIterator` object with the given
		arguments.
	**/
	public function new(dictionary:AMFDictionary<K, V>) {
		this.keyIterator = @:privateAccess dictionary.keys.iterator();
		this.valueIterator = @:privateAccess dictionary.values.iterator();
	}

	/**
		@see [`Iterator hasNext()`](https://api.haxe.org/Iterator.html#hasNext)
	**/
	public function hasNext():Bool {
		return keyIterator.hasNext();
	}

	/**
		@see [`Iterator next()`](https://api.haxe.org/Iterator.html#next)
	**/
	public function next():{key:Dynamic, value:Dynamic} {
		var key = keyIterator.next();
		var value = valueIterator.next();
		return {key: key, value: value};
	}
}
