/*
	Licensed to the Apache Software Foundation (ASF) under one or more
	contributor license agreements.  See the NOTICE file distributed with
	this work for additional information regarding copyright ownership.
	The ASF licenses this file to You under the Apache License, Version 2.0
	(the "License"); you may not use this file except in compliance with
	the License.  You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

	AMF JavaScript library by Emil Malinov https://github.com/emilkm/amfjs
 */

package feathers.amfio;

import openfl.errors.Error;
import openfl.net.ObjectEncoding;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import openfl.utils.IExternalizable;
#if !flash
import openfl.utils.IDataInput;
#end

/**
	Read raw AMF data from a `ByteArray`.

	```haxe
	var reader = new AMFReader(byteArray);
	var data = reader.readObject();
	```
**/
class AMFReader #if !flash implements IDataInput #end {
	private static final AMF0_AMF3:UInt = 0x11;
	private static final AMF0_NUMBER:UInt = 0x0;
	private static final AMF0_BOOLEAN:UInt = 0x1;
	private static final AMF0_STRING:UInt = 0x2;
	private static final AMF0_OBJECT:UInt = 0x3;
	/*private static final AMF0_MOVIECLIP:UInt =  0x4; NOT USED */
	private static final AMF0_NULL:UInt = 0x05;
	private static final AMF0_UNDEFINED:UInt = 0x06;
	private static final AMF0_REFERENCE:UInt = 0x07;
	private static final AMF0_ECMA_ARRAY:UInt = 0x08; // includes non-numeric keys
	private static final AMF0_OBJECT_END:UInt = 0x09;
	private static final AMF0_STRICT_ARRAY:UInt = 0x0A; // only numeric keys (this does not seem to be used for client-side serialization)
	private static final AMF0_DATE:UInt = 0x0B;
	private static final AMF0_LONG_STRING:UInt = 0x0C;
	private static final AMF0_UNSUPPORTED:UInt = 0x0D;
	/*private static final AMF0_RECORDSET:UInt = 0x0E; NOT USED */
	private static final AMF0_XMLDOCUMENT:UInt = 0x0F;
	private static final AMF0_TYPED_OBJECT:UInt = 0x10;

	private static final AMF3_OBJECT_ENCODING:UInt = 0x03;
	private static final AMF3_UNDEFINED:UInt = 0x00;
	private static final AMF3_NULL:UInt = 0x01;
	private static final AMF3_BOOLEAN_FALSE:UInt = 0x02;
	private static final AMF3_BOOLEAN_TRUE:UInt = 0x03;
	private static final AMF3_INTEGER:UInt = 0x04;
	private static final AMF3_DOUBLE:UInt = 0x05;
	private static final AMF3_STRING:UInt = 0x06;
	private static final AMF3_XMLDOCUMENT:UInt = 0x07;
	private static final AMF3_DATE:UInt = 0x08;
	private static final AMF3_ARRAY:UInt = 0x09;
	private static final AMF3_OBJECT:UInt = 0x0A;
	private static final AMF3_XML:UInt = 0x0B;
	private static final AMF3_BYTEARRAY:UInt = 0x0C;
	private static final AMF3_VECTOR_INT:UInt = 0x0D;
	private static final AMF3_VECTOR_UINT:UInt = 0x0E;
	private static final AMF3_VECTOR_DOUBLE:UInt = 0x0F;
	private static final AMF3_VECTOR_OBJECT:UInt = 0x10;
	private static final AMF3_DICTIONARY:UInt = 0x11;

	private static final UINT29_MASK:UInt = 0x1FFFFFFF;
	private static final INT28_MAX_VALUE:Int = 268435455;
	private static final INT28_MIN_VALUE:Int = -268435456;
	private static final EMPTY_STRING:String = "";

	private static function getAliasByClass(theClass:Dynamic):String {
		#if (openfl >= "9.2.0")
		var registeredClassAliases = @:privateAccess openfl.Lib.__registeredClassAliases;
		for (key => value in registeredClassAliases) {
			if (value == theClass) {
				return key;
			}
		}
		#end
		return null;
	}

	public function new(targetReference:ByteArray) {
		target = targetReference;
		reset();
	}

	private var switchedToAMF3:Bool = false;

	private var objects:Array<Dynamic>;
	private var traits:Array<Dynamic>;
	private var strings:Array<Dynamic>;

	private var target:ByteArray;

	@:flash.property
	public var endian(get, set):Endian;

	private function get_endian():Endian {
		return target.endian;
	}

	private function set_endian(value:Endian):Endian {
		target.endian = value;
		return target.endian;
	}

	public var objectEncoding:ObjectEncoding = AMF3;

	@:flash.property
	public var bytesAvailable(get, never):Int;

	private function get_bytesAvailable():Int {
		return target.bytesAvailable;
	}

	public function reset():Void {
		objects = [];
		traits = [];
		strings = [];
		switchedToAMF3 = false;
	}

	public function readByte():Int {
		return target.readByte();
	}

	public function readUnsignedByte():UInt {
		return target.readUnsignedByte();
	}

	public function readBoolean():Bool {
		return target.readBoolean();
	}

	public function readShort():Int {
		return target.readShort();
	}

	public function readUnsignedShort():UInt {
		return target.readUnsignedShort();
	}

	public function readInt():Int {
		return target.readInt();
	}

	public function readUnsignedInt():Int {
		return target.readUnsignedInt();
	}

	public function readFloat():Float {
		return target.readFloat();
	}

	public function readDouble():Float {
		return target.readDouble();
	}

	public function readUInt29():Int {
		final read = readUnsignedByte;
		var b:UInt = read() & 255;
		if (b < 128) {
			return b;
		}
		var value:UInt = (b & 127) << 7;
		b = read() & 255;
		if (b < 128)
			return (value | b);
		value = (value | (b & 127)) << 7;
		b = read() & 255;
		if (b < 128)
			return (value | b);
		value = (value | (b & 127)) << 8;
		b = read() & 255;
		return (value | b);
	}

	public function readObject():Dynamic {
		target.objectEncoding = objectEncoding;
		if (objectEncoding == AMF0) {
			return readAmf0Object();
		} else {
			return readAmf3Object();
		}
	}

	public function readUTF():String {
		return target.readUTF();
	}

	public function readUTFBytes(length:UInt):String {
		return target.readUTFBytes(length);
	}

	public function readMultiByte(length:UInt, charSet:String):String {
		throw new Error("readMultiByte not supported");
	}

	public function readBytes(bytes:ByteArray, offset:UInt = 0, length:UInt = 0):Void {
		target.readBytes(bytes, offset, length);
	}

	public function readAmf0Object():Dynamic {
		if (switchedToAMF3) {
			return readAmf3Object();
		} else {
			var amfType:UInt = readUnsignedByte();
			if (amfType == AMF0_AMF3) {
				switchedToAMF3 = true;
				return readAmf3Object();
			} else {
				return readAmf0ObjectValue(amfType);
			}
		}
	}

	public function readAmf3Object():Dynamic {
		var amfType:UInt = readUnsignedByte();
		return readAmf3ObjectValue(amfType);
	}

	public function readAmf3XML():Dynamic {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0)
			return getObject(ref >> 1);
		else {
			var len:UInt = (ref >> 1);
			var stringSource:String = readUTFBytes(len);
			#if flash
			var xml = new flash.xml.XML(stringSource);
			rememberObject(xml);
			return xml;
			#else
			var xml = Xml.parse(stringSource);
			rememberObject(xml);
			return xml;
			#end
		}
	}

	public function readAmf3String():String {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0) {
			return getString(ref >> 1);
		} else {
			var len:UInt = (ref >> 1);
			if (len == 0) {
				return EMPTY_STRING;
			}
			var str:String = readUTFBytes(len);
			rememberString(str);
			return str;
		}
	}

	private function rememberString(v:String):Void {
		strings.push(v);
	}

	private function getString(v:UInt):String {
		return strings[v];
	}

	private function getObject(v:UInt):Dynamic {
		return objects[v];
	}

	private function getTraits(v:UInt):AMFTraits {
		return traits[v];
	}

	private function rememberTraits(v:AMFTraits):Void {
		traits.push(v);
	}

	private function rememberObject(v:Dynamic):Void {
		objects.push(v);
	}

	private function readTraits(ref:UInt):AMFTraits {
		var ti:AMFTraits;
		if ((ref & 3) == 1) {
			ti = getTraits(ref >> 2);
			return ti;
		} else {
			ti = new AMFTraits();
			ti.externalizable = ((ref & 4) == 4);
			ti.isDynamic = ((ref & 8) == 8);
			ti.count = (ref >> 4);
			var className:String = readAmf3String();
			if (className != null && className != "") {
				ti.alias = className;
			}

			for (i in 0...ti.count) {
				ti.props.push(readAmf3String());
			}

			rememberTraits(ti);
			return ti;
		}
	}

	private function readAmf3Dictionary():Dynamic {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0) {
			// retrieve object from object reference table
			return getObject(ref >> 1);
		} else {
			var len = ref >> 1;
			var weakKeys = readBoolean();
			// TODO: mode that creates a real flash.utils.Dictionary
			// var obj = new openfl.utils.Dictionary<Dynamic, Dynamic>(weakKeys);
			var obj = new AMFDictionary<Dynamic, Dynamic>(weakKeys);
			rememberObject(obj);
			for (i in 0...len) {
				var key = readAmf3Object();
				obj[key] = readAmf3Object();
			}
			return obj;
		}
	}

	private function readScriptObject():Dynamic {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0) {
			// retrieve object from object reference table
			return getObject(ref >> 1);
		} else {
			var decodedTraits:AMFTraits = readTraits(ref);
			var obj:Dynamic;
			var localTraits:AMFTraits = null;
			if (decodedTraits.alias != null && decodedTraits.alias.length > 0) {
				var c:Class<Dynamic> = null;
				#if (openfl >= "9.2.0")
				c = openfl.Lib.getClassByAlias(decodedTraits.alias);
				#elseif flash
				c = untyped __global__["flash.net.getClassByAlias"](decodedTraits.alias);
				#end
				if (c != null) {
					obj = Type.createInstance(c, []);
					localTraits = getLocalTraitsInfo(obj);
				} else {
					obj = {};
				}
			} else {
				obj = {};
			}
			rememberObject(obj);
			if (decodedTraits.externalizable) {
				obj.readExternal(this);
			} else {
				final l:UInt = decodedTraits.props.length;
				var hasProp:Bool;
				for (i in 0...l) {
					var fieldValue:Dynamic = readObject();
					var prop:String = decodedTraits.props[i];
					hasProp = localTraits != null && (localTraits.hasProp(prop) || localTraits.isDynamic || localTraits.isTransient(prop));
					if (hasProp) {
						Reflect.field(localTraits.getterSetters, prop).setValue(obj, fieldValue);
					} else {
						if (localTraits == null) {
							Reflect.setField(obj, prop, fieldValue);
						} else {
							// @todo add debug-only logging for error checks (e.g. ReferenceError: Error #1074: Illegal write to read-only property)
							#if debug
							trace('ReferenceError: Error #1056: Cannot create property ' + prop + ' on ' + localTraits.qName);
							#end
						}
					}
				}
				if (decodedTraits.isDynamic) {
					while (true) {
						var name:String = readAmf3String();
						if (name == null || name.length == 0) {
							break;
						}
						Reflect.setField(obj, name, readObject());
					}
				}
			}
			return obj;
		}
	}

	private function getLocalTraitsInfo(instance:Dynamic):AMFTraits {
		// var classInfo:Dynamic = instance.ROYALE_CLASS_INFO;
		// var originalClassInfo:Dynamic;
		var localTraits:AMFTraits;
		var instanceClass = Type.getClass(instance);

		if (instanceClass != null) {
			localTraits = new AMFTraits();
			var alias:String = getAliasByClass(instanceClass);
			if (alias != null)
				localTraits.alias = alias;
			else
				localTraits.alias = "";
			localTraits.qName = Type.getClassName(instanceClass);
			localTraits.isDynamic = false;
			localTraits.externalizable = (instance is IExternalizable);

			if (localTraits.externalizable) {
				localTraits.count = 0;
			} else {
				var props:Array<String> = [];
				for (instanceField in Type.getInstanceFields(instanceClass)) {
					if (Type.typeof(Reflect.field(instance, instanceField)) == TFunction) {
						if (StringTools.startsWith(instanceField, "get_")) {
							var propName = instanceField.substr(4);
							props.push(propName);
							Reflect.setField(localTraits.getterSetters, propName, AMFTraits.createInstanceAccessorGetterSetter(propName));
						}
						continue;
					}
					Reflect.setField(localTraits.getterSetters, instanceField, AMFTraits.createInstanceAccessorGetterSetter(instanceField));
					props.push(instanceField);
				}
				localTraits.props = props;
				// var accessChecks:Dynamic = {};
				// var c:Dynamic = instance;
				// while (classInfo) {
				// 	var reflectionInfo:Dynamic = c.ROYALE_REFLECTION_INFO();
				// 	populateSerializableMembers(reflectionInfo, accessChecks, localTraits);
				// 	if (!c.constructor.superClass_ || !c.constructor.superClass_.ROYALE_CLASS_INFO)
				// 		break;
				// 	classInfo = c.constructor.superClass_.ROYALE_CLASS_INFO;
				// 	c = c.constructor.superClass_;
				// }
				// sometimes flash native seriazliation double-counts props and outputs some props data twice.
				// this can happen with overrides (it was noticed with Transient overrides)
				// it may mean that js amf output can sometimes be more compact, but should always deserialize to the same result.
				localTraits.count = localTraits.props.length;
				// not required, but useful when testing:
				// localTraits.props.sort();
			}
			// cache in the classInfo for faster lookups next time
			// originalClassInfo.localTraits = localTraits;
		} else {
			// assume dynamic, anon object
			if (Type.typeof(instance) == TObject) {
				localTraits = AMFTraits.getBaseObjectTraits();
			} else {
				// could be a class object
				var anonFields:Array<String> = [];
				for (key in Reflect.fields(instance)) {
					if (key != "") {
						anonFields.push(key);
					}
				}
				localTraits = AMFTraits.getDynObjectTraits(anonFields);
			}
			// not required, but useful when testing:
			// localTraits.props.sort();
		}
		return localTraits;
	}

	public function readAmf3Array():Dynamic {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0)
			return getObject(ref >> 1);
		var denseLength:UInt = (ref >> 1);
		var array:Array<Dynamic> = [];
		// we might need to replace the Array with an AMFEcmaArray if there
		// are any string keys found, so keep the index
		var rememberedObjectIndex = objects.length;
		rememberObject(array);
		var ecmaKeys:Dynamic = null;
		while (true) {
			var name:String = readAmf3String();
			if (name == null || name.length == 0)
				break;
			// associative keys first
			if (ecmaKeys == null) {
				ecmaKeys = {};
			}
			Reflect.setField(ecmaKeys, name, readObject());
		}
		// then dense array keys
		for (i in 0...denseLength) {
			array[i] = readObject();
		}
		if (ecmaKeys == null) {
			return array;
		}
		var ecmaArray:AMFEcmaArray<Dynamic> = array;
		objects[rememberedObjectIndex] = ecmaArray;
		for (field in Reflect.fields(ecmaKeys)) {
			// Reflect.setField() doesn't work here because the fields
			// are stored in a private variable
			ecmaArray[field] = Reflect.field(ecmaKeys, field);
		}
		return ecmaArray;
	}

	public function readAmf3Date():Date {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0)
			return getObject(ref >> 1);
		var time:Float = readDouble();
		var date:Date = Date.fromTime(time);
		rememberObject(date);
		return date;
	}

	public function readByteArray():ByteArray {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0)
			return getObject(ref >> 1);
		else {
			var len:UInt = (ref >> 1);
			var bytes = new ByteArray(len);
			target.readBytes(bytes, 0, len);
			rememberObject(bytes);
			return bytes;
		}
	}

	private function readAmf3Vector(amfType:UInt):Dynamic {
		var ref:UInt = readUInt29();
		if ((ref & 1) == 0)
			return getObject(ref >> 1);
		var len:UInt = (ref >> 1);
		var fixed:Bool = readBoolean();
		if (amfType == AMF3_VECTOR_OBJECT) {
			var className:String = readAmf3String(); // className
			if (className == "") {
				className = 'Object';
			} else {
				try {
					var c:Class<Dynamic> = null;
					#if (openfl >= "9.2.0")
					c = openfl.Lib.getClassByAlias(className);
					#elseif flash
					c = untyped __global__["flash.net.getClassByAlias"](className);
					#end
					className = openfl.Lib.getQualifiedClassName(c);
				} catch (e:Error) {
					className = 'Object';
				}
			}
			var vector = new openfl.Vector<{}>(len, fixed);
			for (i in 0...len)
				vector[i] = readObject();
			rememberObject(vector);
			return vector;
		} else if (amfType == AMF3_VECTOR_INT) {
			var vector = new openfl.Vector<Int>(len, fixed);
			for (i in 0...len)
				vector[i] = readInt();
			rememberObject(vector);
			return vector;
		} else if (amfType == AMF3_VECTOR_UINT) {
			var vector = new openfl.Vector<UInt>(len, fixed);
			for (i in 0...len)
				vector[i] = readUnsignedInt();
			rememberObject(vector);
			return vector;
		} else if (amfType == AMF3_VECTOR_DOUBLE) {
			var vector = new openfl.Vector<Float>(len, fixed);
			for (i in 0...len)
				vector[i] = readDouble();
			rememberObject(vector);
			return vector;
		} else {
			throw new Error("Unknown vector type: " + amfType);
		}
	}

	private function readAmf3ObjectValue(amfType:UInt):Dynamic {
		var value:Dynamic = null;
		var u:UInt;

		switch (amfType) {
			case AMF3_STRING:
				value = readAmf3String();
			case AMF3_OBJECT:
				try {
					value = readScriptObject();
				} catch (e:Dynamic) {
					// trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
					throw new Error("Failed to deserialize: " + e);
				}
			case AMF3_ARRAY:
				value = readAmf3Array();
			case AMF3_BOOLEAN_FALSE:
				value = false;
			case AMF3_BOOLEAN_TRUE:
				value = true;
			case AMF3_DICTIONARY:
				value = readAmf3Dictionary();
			case AMF3_INTEGER:
				u = readUInt29();
				// Symmetric with writing an integer to fix sign bits for
				// negative values...
				value = (u << 3) >> 3;
			case AMF3_DOUBLE:
				value = readDouble();
			case AMF3_UNDEFINED:
				#if html5
				value = js.Lib.undefined;
				#elseif flash
				value = untyped __global__["undefined"];
				#else
				value = null;
				#end
			case AMF3_NULL:
			// null is already assigned by default
			case AMF3_DATE:
				value = readAmf3Date();
			case AMF3_BYTEARRAY:
				value = readByteArray();
			case AMF3_XML:
				value = readAmf3XML();
			case AMF3_XMLDOCUMENT:
				throw new Error('XMLDocument AMF3 type not supported');
			case AMF3_VECTOR_INT:
				value = readAmf3Vector(amfType);
			case AMF3_VECTOR_UINT:
				value = readAmf3Vector(amfType);
			case AMF3_VECTOR_DOUBLE:
				value = readAmf3Vector(amfType);
			case AMF3_VECTOR_OBJECT:
				value = readAmf3Vector(amfType);
			default:
				throw new Error("Unsupported AMF type: " + amfType);
		}
		return value;
	}

	private function readAmf0ObjectValue(amfType:UInt):Dynamic {
		var value:Dynamic = null;

		switch (amfType) {
			case AMF0_NUMBER:
				value = readDouble();
			case AMF0_BOOLEAN:
				value = readUnsignedByte() == 1 ? true : false;
			case AMF0_STRING:
				// readUTF reads the unsigned short (U16) length as well
				value = readUTF();
			case AMF0_OBJECT:
				value = readAMF0ScriptObject(null);
			case AMF0_NULL:
				value = null;
			case AMF0_UNDEFINED:
				#if html5
				value = js.Lib.undefined;
				#elseif flash
				value = untyped __global__["undefined"];
				#else
				value = null;
				#end
			case AMF0_REFERENCE:
				value = getObject(readUnsignedShort());
			case AMF0_ECMA_ARRAY:
				value = readAMF0Array(true);
			case AMF0_OBJECT_END:
				throw new Error('unexpected'); // this should already be encountered during Object deserialization
			case AMF0_STRICT_ARRAY:
				value = readAMF0Array(false);
			case AMF0_DATE:
				value = readAMF0Date();
			case AMF0_LONG_STRING:
				var len:UInt = readUnsignedInt();
				value = readUTFBytes(len);
			case AMF0_XMLDOCUMENT:
				throw new Error('XMLDocument AMF0 type not supported');
			case AMF0_TYPED_OBJECT:
				var className:String = readUTF();
				value = readAMF0ScriptObject(className);
			default:
				throw new Error("Unsupported AMF type: " + amfType);
		}
		return value;
	}

	private function readAMF0ScriptObject(alias:String):Dynamic {
		var obj:Dynamic = null;
		var localTraits:AMFTraits = null;
		if (alias != null && alias.length > 0) {
			var c:Class<Dynamic> = null;
			#if (openfl >= "9.2.0")
			c = openfl.Lib.getClassByAlias(alias);
			#elseif flash
			c = untyped __global__["flash.net.getClassByAlias"](alias);
			#end
			if (c != null) {
				obj = Type.createInstance(c, []);
				localTraits = getLocalTraitsInfo(obj);
			}
		}
		if (obj == null) {
			obj = {};
			localTraits = AMFTraits.getBaseObjectTraits();
		}

		rememberObject(obj);
		var more:Bool = true;
		while (more) {
			var key:String = readUTF();
			if (key == "") {
				more = false;
			} else {
				var fieldValue:Dynamic = readAmf0Object();
				var hasProp = localTraits != null && (localTraits.hasProp(key) || localTraits.isTransient(key));
				if (hasProp) {
					Reflect.field(localTraits.getterSetters, key).setValue(obj, fieldValue);
				} else if (localTraits.isDynamic) {
					Reflect.setField(obj, key, fieldValue);
				} else {
					// @todo
					trace('unknown field ', key);
					#if debug
					trace('ReferenceError: Error #1056: Cannot create property ' + key + ' on ' + localTraits.qName);
					#end
				}
			}
		}

		var check:UInt = readUnsignedByte();
		if (check != AMF0_OBJECT_END) {
			throw new Error('unexpected. should be AMF0_OBJECT_END');
		}
		return obj;
	}

	private function readAMF0Array(ecma:Bool):Dynamic {
		var len:UInt = readUnsignedInt();
		var array:Array<Any> = [];
		// we might need to replace the Array with an AMFEcmaArray if there
		// are any string keys found, so keep the index
		var rememberedObjectIndex = objects.length;
		rememberObject(array);
		var ecmaKeys:Dynamic = null;
		if (ecma) {
			var more:Bool = true;
			while (more) {
				var key:String = readUTF();
				if (key == "") {
					more = false;
				} else {
					var index = Std.parseInt(key);
					if (index == null) {
						if (ecmaKeys == null) {
							ecmaKeys = {};
						}
						Reflect.setField(ecmaKeys, key, readAmf0Object());
					} else {
						array[index] = readAmf0Object();
					}
				}
			}
			var byte:UInt = readUnsignedByte();
			if (byte != AMF0_OBJECT_END)
				throw new Error('unexpected. should be AMF0_OBJECT_END');
			if (ecmaKeys != null) {
				var ecmaArray:AMFEcmaArray<Dynamic> = array;
				objects[rememberedObjectIndex] = ecmaArray;
				for (field in Reflect.fields(ecmaKeys)) {
					// Reflect.setField() doesn't work here because the fields
					// are stored in a private variable
					ecmaArray[field] = Reflect.field(ecmaKeys, field);
				}
				return ecmaArray;
			}
		} else {
			for (i in 0...len) {
				array[i] = readAmf0Object();
			}
		}
		return array;
	}

	private function readAMF0Date():Date {
		var time:Float = readDouble();
		var date:Date = Date.fromTime(time);
		rememberObject(date);
		// skip the S16 timezone data (not used)
		readShort();
		return date;
	}
}
