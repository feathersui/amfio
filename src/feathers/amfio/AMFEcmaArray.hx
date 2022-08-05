/*
	Feathers UI AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import haxe.DynamicAccess;
import haxe.iterators.ArrayKeyValueIterator;
import haxe.iterators.DynamicAccessKeyValueIterator;

@:transitive
@:forward
abstract AMFEcmaArray<T>(AMFEcmaArrayData<T>) from AMFEcmaArrayData<T> to AMFEcmaArrayData<T> {
	public function new() {
		this = new AMFEcmaArrayData<T>();
	}

	@:from
	private inline static function fromArray<T>(array:Array<T>):AMFEcmaArray<T> {
		return cast new AMFEcmaArrayData(array);
	}

	@:to
	private inline function toArray():Array<T> {
		return @:privateAccess this.indices;
	}

	@:arrayAccess
	public inline function getInt(index:Int):T {
		return @:privateAccess this.indices[index];
	}

	@:arrayAccess
	public inline function getString(key:String):Dynamic {
		return Reflect.field(@:privateAccess this.fields, key);
	}

	@:arrayAccess
	public inline function setInt(index:Int, value:T):T {
		return @:privateAccess this.indices[index] = value;
	}

	@:arrayAccess
	public inline function setString(key:String, value:Dynamic):Dynamic {
		Reflect.setField(@:privateAccess this.fields, key, value);
		return Reflect.field(@:privateAccess this.fields, key);
	}
}

class AMFEcmaArrayData<T> {
	private var fields:DynamicAccess<Dynamic>;
	private var indices:Array<T>;

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

	public var length(get, never):Int;

	private function get_length():Int {
		return this.indices.length;
	}

	public inline function concat(other:Array<T>):Array<T> {
		// ECMAScript does not copy string keys, so don't return an AMFEcmaArray
		return this.indices.concat(other);
	}

	public function join(sep:String):String {
		return this.indices.join(sep);
	}

	public inline function pop():Null<T> {
		return this.indices.pop();
	}

	public inline function push(x:T):Int {
		return this.indices.push(x);
	}

	public function reverse():Void {
		this.indices.reverse();
	}

	public inline function shift():Null<T> {
		return this.indices.shift();
	}

	public inline function slice(pos:Int, ?end:Int):Array<T> {
		return this.indices.slice(pos, end);
	}

	public inline function sort(f:T->T->Int):Void {
		this.indices.sort(f);
	}

	public inline function splice(pos:Int, len:Int):Array<T> {
		return this.indices.splice(pos, len);
	}

	public inline function toString():String {
		return this.indices.toString();
	}

	public inline function unshift(x:T):Void {
		this.indices.unshift(x);
	}

	public inline function insert(pos:Int, x:T):Void {
		this.indices.insert(pos, x);
	}

	public inline function remove(x:T):Bool {
		return this.indices.remove(x);
	}

	public inline function contains(x:T):Bool {
		return this.indices.contains(x);
	}

	public inline function indexOf(x:T, ?fromIndex:Int):Int {
		return this.indices.indexOf(x, fromIndex);
	}

	public inline function lastIndexOf(x:T, ?fromIndex:Int):Int {
		#if (flash || html5)
		return this.indices.lastIndexOf(x, 0x7FFFFFFF);
		#else
		return this.indices.lastIndexOf(x, fromIndex);
		#end
	}

	public inline function copy():AMFEcmaArray<T> {
		return cast new AMFEcmaArrayData(this.indices.copy(), this.fields.copy());
	}

	public inline function iterator():Iterator<T> {
		return this.indices.iterator();
	}

	public inline function keyValueIterator():AMFEcmaArrayKeyValueIterator {
		return new AMFEcmaArrayKeyValueIterator(this.indices.keyValueIterator(), this.fields.keyValueIterator());
	}

	public inline function map<S>(f:T->S):Array<S> {
		return this.indices.map(f);
	}

	public inline function filter(f:T->Bool):Array<T> {
		return this.indices.filter(f);
	}

	public inline function resize(len:Int):Void {
		this.indices.resize(len);
	}
}

class AMFEcmaArrayKeyValueIterator {
	private var indiciesIterator:KeyValueIterator<Dynamic, Dynamic>;
	private var fieldsIterator:KeyValueIterator<Dynamic, Dynamic>;

	public function new(indiciesIterator:KeyValueIterator<Dynamic, Dynamic>, fieldsIterator:KeyValueIterator<Dynamic, Dynamic>) {
		this.indiciesIterator = indiciesIterator;
		this.fieldsIterator = fieldsIterator;
	}

	public function hasNext():Bool {
		return indiciesIterator.hasNext() || fieldsIterator.hasNext();
	}

	public function next():{key:Dynamic, value:Dynamic} {
		if (indiciesIterator.hasNext()) {
			return indiciesIterator.next();
		}
		return fieldsIterator.next();
	}
}
