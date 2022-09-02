/*
	AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import haxe.DynamicAccess;

/**
	Stores data from the AMF associative array type. Unlike Haxe arrays, AS3
	and ECMAScript aarrays can hold both integer and string keys.
**/
@:transitive
@:forward
abstract AMFEcmaArray<T>(AMFEcmaArrayData<T>) from AMFEcmaArrayData<T> to AMFEcmaArrayData<T> {
	/**
		Creates a new `AMFEcmaArray` instance.
	**/
	public function new() {
		this = new AMFEcmaArrayData<T>();
	}

	/**
		Converts an `Array` into an `AMFEcmaArray`.
	**/
	@:from
	private inline static function fromArray<T>(array:Array<T>):AMFEcmaArray<T> {
		return cast new AMFEcmaArrayData(array);
	}

	/**
		Converts an `AMFEcmaArray` into an `Array`, but removes the associative
		string keys.
	**/
	@:to
	private inline function toArray():Array<T> {
		return @:privateAccess this.indices;
	}

	/**
		Gets a value using array `[]` access with an integer key.
	**/
	@:arrayAccess
	public inline function getInt(index:Int):T {
		return @:privateAccess this.indices[index];
	}

	/**
		Gets a value using array `[]` access with a string key.
	**/
	@:arrayAccess
	public inline function getString(key:String):Dynamic {
		return Reflect.field(@:privateAccess this.fields, key);
	}

	/**
		Sets a value using array `[]` access with an integer key.
	**/
	@:arrayAccess
	public inline function setInt(index:Int, value:T):T {
		return @:privateAccess this.indices[index] = value;
	}

	/**
		Sets a value using array `[]` access with a string key.
	**/
	@:arrayAccess
	public inline function setString(key:String, value:Dynamic):Dynamic {
		Reflect.setField(@:privateAccess this.fields, key, value);
		return Reflect.field(@:privateAccess this.fields, key);
	}
}

/**
	Stores data for the `AMFEcmaArray` abstract.
**/
class AMFEcmaArrayData<T> {
	private var fields:DynamicAccess<Dynamic>;
	private var indices:Array<T>;

	/**
		Creates a new `AMFEcmaArrayData` instance.
	**/
	public function new(?indices:Array<T>, ?fields:Dynamic) {
		if (indices == null) {
			indices = [];
		}
		if (fields == null) {
			fields = {};
		}
		this.indices = indices;
		this.fields = fields;
	}

	/**
		@see [`Array length`](https://api.haxe.org/Array.html#length)
	**/
	public var length(get, never):Int;

	private function get_length():Int {
		return this.indices.length;
	}

	/**
		@see [`Array concat()`](https://api.haxe.org/Array.html#concat)
	**/
	public inline function concat(other:Array<T>):Array<T> {
		// ECMAScript does not copy string keys, so don't return an AMFEcmaArray
		return this.indices.concat(other);
	}

	/**
		@see [`Array join()`](https://api.haxe.org/Array.html#join)
	**/
	public function join(sep:String):String {
		return this.indices.join(sep);
	}

	/**
		@see [`Array pop()`](https://api.haxe.org/Array.html#pop)
	**/
	public inline function pop():Null<T> {
		return this.indices.pop();
	}

	/**
		@see [`Array push()`](https://api.haxe.org/Array.html#push)
	**/
	public inline function push(x:T):Int {
		return this.indices.push(x);
	}

	/**
		@see [`Array reverse()`](https://api.haxe.org/Array.html#reverse)
	**/
	public function reverse():Void {
		this.indices.reverse();
	}

	/**
		@see [`Array shift()`](https://api.haxe.org/Array.html#shift)
	**/
	public inline function shift():Null<T> {
		return this.indices.shift();
	}

	/**
		@see [`Array slice()`](https://api.haxe.org/Array.html#slice)
	**/
	public inline function slice(pos:Int, ?end:Int):Array<T> {
		return this.indices.slice(pos, end);
	}

	/**
		@see [`Array sort()`](https://api.haxe.org/Array.html#sort)
	**/
	public inline function sort(f:T->T->Int):Void {
		this.indices.sort(f);
	}

	/**
		@see [`Array splice()`](https://api.haxe.org/Array.html#splice)
	**/
	public inline function splice(pos:Int, len:Int):Array<T> {
		return this.indices.splice(pos, len);
	}

	/**
		@see [`Array toString()`](https://api.haxe.org/Array.html#toString)
	**/
	public inline function toString():String {
		return this.indices.toString();
	}

	/**
		@see [`Array unshift()`](https://api.haxe.org/Array.html#unshift)
	**/
	public inline function unshift(x:T):Void {
		this.indices.unshift(x);
	}

	/**
		@see [`Array insert()`](https://api.haxe.org/Array.html#insert)
	**/
	public inline function insert(pos:Int, x:T):Void {
		this.indices.insert(pos, x);
	}

	/**
		@see [`Array remove()`](https://api.haxe.org/Array.html#remove)
	**/
	public inline function remove(x:T):Bool {
		return this.indices.remove(x);
	}

	#if (haxe_ver > 4.1)
	/**
		@see [`Array contains()`](https://api.haxe.org/Array.html#contains)
	**/
	public inline function contains(x:T):Bool {
		return this.indices.contains(x);
	}
	#end

	/**
		@see [`Array indexOf()`](https://api.haxe.org/Array.html#indexOf)
	**/
	public inline function indexOf(x:T, ?fromIndex:Int):Int {
		return this.indices.indexOf(x, fromIndex);
	}

	/**
		@see [`Array lastIndexOf()`](https://api.haxe.org/Array.html#lastIndexOf)
	**/
	public inline function lastIndexOf(x:T, ?fromIndex:Int):Int {
		#if (flash || html5)
		return this.indices.lastIndexOf(x, 0x7FFFFFFF);
		#else
		return this.indices.lastIndexOf(x, fromIndex);
		#end
	}

	/**
		@see [`Array copy()`](https://api.haxe.org/Array.html#copy)
	**/
	public inline function copy():AMFEcmaArray<T> {
		return cast new AMFEcmaArrayData(this.indices.copy(), this.fields.copy());
	}

	/**
		Creates an iterator for the values of the `AMFEcmaArray`.
	**/
	public inline function iterator():Iterator<T> {
		return this.indices.iterator();
	}

	#if (haxe_ver >= 4.1)
	/**
		Creates a key-value iterator for the `AMFEcmaArray`.
	**/
	public inline function keyValueIterator():AMFEcmaArrayKeyValueIterator {
		return new AMFEcmaArrayKeyValueIterator(this);
	}
	#end

	/**
		@see [`Array map()`](https://api.haxe.org/Array.html#map)
	**/
	public inline function map<S>(f:T->S):Array<S> {
		return this.indices.map(f);
	}

	/**
		@see [`Array filter()`](https://api.haxe.org/Array.html#filter)
	**/
	public inline function filter(f:T->Bool):Array<T> {
		return this.indices.filter(f);
	}

	/**
		@see [`Array resize()`](https://api.haxe.org/Array.html#resize)
	**/
	public inline function resize(len:Int):Void {
		this.indices.resize(len);
	}
}

#if (haxe_ver > 4.1)
/**
	This iterator is used when `keyValueIterator()` is called on an
	`AMFEcmaArray` instance.
**/
class AMFEcmaArrayKeyValueIterator {
	private var indiciesIterator:KeyValueIterator<Dynamic, Dynamic>;
	private var fieldsIterator:KeyValueIterator<Dynamic, Dynamic>;

	/**
		Creates a new `AMFEcmaArrayKeyValueIterator` instance.
	**/
	public function new(array:AMFEcmaArrayData<Dynamic>) {
		this.indiciesIterator = @:privateAccess array.indices.keyValueIterator();
		this.fieldsIterator = @:privateAccess array.fields.keyValueIterator();
	}

	/**
		@see [`Iterator hasNext()`](https://api.haxe.org/Iterator.html#hasNext)
	**/
	public function hasNext():Bool {
		return indiciesIterator.hasNext() || fieldsIterator.hasNext();
	}

	/**
		@see [`Iterator next()`](https://api.haxe.org/Iterator.html#next)
	**/
	public function next():{key:Dynamic, value:Dynamic} {
		if (indiciesIterator.hasNext()) {
			return indiciesIterator.next();
		}
		return fieldsIterator.next();
	}
}
#end
