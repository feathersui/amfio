/*
	Feathers UI AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import openfl.utils.Dictionary;

@:transitive
@:forward
abstract AMFDictionary<K, V>(AMFDictionaryData<K, V>) from AMFDictionaryData<K, V> to AMFDictionaryData<K, V> {
	public function new(weakKeys:Bool = false) {
		this = new AMFDictionaryData<K, V>(weakKeys);
	}

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

class AMFDictionaryData<K, V> {
	private var keys:Array<K>;
	private var values:Array<V>;
	private var weakKeys:Bool;

	public function new(weakKeys:Bool = false) {
		this.weakKeys = weakKeys;
		keys = [];
		values = [];
	}

	public function remove(key:K):Bool {
		var index = keys.indexOf(key);
		if (index == -1) {
			return false;
		}
		values.splice(index, 1);
		return true;
	}

	public inline function iterator():Iterator<K> {
		return this.keys.iterator();
	}

	public inline function keyValueIterator():AMFDictionaryKeyValueIterator<K, V> {
		return new AMFDictionaryKeyValueIterator(this.keys.iterator(), this.values.iterator());
	}
}

class AMFDictionaryKeyValueIterator<K, V> {
	private var keyIterator:Iterator<K>;
	private var valueIterator:Iterator<V>;

	public function new(keyIterator:Iterator<K>, valueIterator:Iterator<V>) {
		this.keyIterator = keyIterator;
		this.valueIterator = valueIterator;
	}

	public function hasNext():Bool {
		return keyIterator.hasNext();
	}

	public function next():{key:Dynamic, value:Dynamic} {
		var key = keyIterator.next();
		var value = valueIterator.next();
		return {key: key, value: value};
	}
}
