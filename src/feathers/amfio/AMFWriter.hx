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

import haxe.Constraints.IMap;
import haxe.ds.WeakMap;
import openfl.errors.ArgumentError;
import openfl.errors.Error;
import openfl.net.ObjectEncoding;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import openfl.utils.IExternalizable;
#if (openfl >= "9.2.0")
import openfl.net.IDynamicPropertyOutput;
import openfl.net.IDynamicPropertyWriter;
#elseif flash
import flash.net.IDynamicPropertyOutput;
import flash.net.IDynamicPropertyWriter;
#end
#if !flash
import openfl.utils.IDataOutput;
#end

/**
	Write raw AMF data from a `ByteArray`.

	```haxe
	var myData = {myString: "hello", myFloat: 123.4};
	var writer = new AMFWriter(byteArray);
	writer.writeObject(data);
	```
**/
class AMFWriter #if !flash implements IDataOutput #end#if (flash || openfl >= "9.2.0") implements IDynamicPropertyOutput #end {
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

	private static var _xmlClass:Class<Dynamic> = null;
	private static final nothing:Dynamic = {};

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

	/**
		Creates a new `AMFReader` instance with the given arguments.
	**/
	public function new(targetReference:ByteArray) {
		target = targetReference;
		reset();
	}

	private var switchedToAMF3:Bool = false;

	/**
		@see [`ByteArray endian`](https://api.openfl.org/openfl/utils/ByteArray.html#endian)
	**/
	@:flash.property
	public var endian(get, set):Endian;

	private function get_endian():Endian {
		return target.endian;
	}

	private function set_endian(value:Endian):Endian {
		target.endian = value;
		return target.endian;
	}

	/**
		@see [`ByteArray objectEncoding`](https://api.openfl.org/openfl/utils/ByteArray.html#objectEncoding)
	**/
	public var objectEncoding:ObjectEncoding = AMF3;

	private var target:ByteArray;

	public var dynamicPropertyWriter:#if (flash || openfl >= "9.2.0") IDynamicPropertyWriter #else Dynamic #end;

	private var objects:Array<Dynamic>;
	private var traits:Array<Dynamic>;
	private var strings:Array<Dynamic>;
	private var _numberBytes:ByteArray;

	private var _writingExternal:Bool = false;

	private function getNumberBytes():ByteArray {
		if (_numberBytes == null) {
			_numberBytes = new ByteArray(8);
			_numberBytes.endian = BIG_ENDIAN;
		}
		_numberBytes.position = 0;
		return _numberBytes;
	}

	/**
		Resets the reader to forget any saved objects, strings, traits, or
		switching status between AMF0 and AMF3.
	**/
	public function reset():Void {
		objects = [];
		traits = [];
		strings = [];
		switchedToAMF3 = false;
	}

	/**
		@see [`ByteArray writeByte()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeByte)
	**/
	public function writeByte(byte:Int):Void {
		target.writeByte(byte);
	}

	/**
		@see [`ByteArray writeShort()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeShort)
	**/
	public function writeShort(short:Int):Void {
		target.writeShort(short);
	}

	/**
		Writes a special 29-bit integer type that is supported by AMF.
	**/
	public function writeUInt29(v:UInt):Void {
		if (v < 128) {
			writeByte(v);
		} else if (v < 16384) {
			writeByte(((v >> 7) & 127) | 128);
			writeByte(v & 127);
		} else if (v < 2097152) {
			writeByte(((v >> 14) & 127) | 128);
			writeByte(((v >> 7) & 127) | 128);
			writeByte(v & 127);
		} else if (v < 0x40000000) {
			writeByte(((v >> 22) & 127) | 128);
			writeByte(((v >> 15) & 127) | 128);
			writeByte(((v >> 8) & 127) | 128);
			writeByte(v & 255);
		} else {
			throw "Integer out of range: " + v;
		}
	}

	/**
		@see [`ByteArray writeBoolean()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeBoolean)
	**/
	public function writeBoolean(value:Bool):Void {
		writeByte(value ? 1 : 0);
	}

	/**
		@see [`ByteArray writeUnsignedInt()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeUnsignedInt)
	**/
	public function writeUnsignedInt(val:UInt):Void {
		writeInt(val);
	}

	/**
		@see [`ByteArray writeInt()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeInt)
	**/
	public function writeInt(val:Int):Void {
		target.writeInt(val);
	}

	/**
		@see [`ByteArray writeBytes()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeBytes)
	**/
	public function writeBytes(bytes:ByteArray, offset:UInt = 0, length:UInt = 0):Void {
		target.writeBytes(bytes, offset, length);
	}

	/**
		@see [`ByteArray writeUTF()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeUTF)
	**/
	public function writeUTF(str:String):Void {
		target.writeUTF(str);
	}

	/**
		@see [`ByteArray writeUTFBytes()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeUTFBytes)
	**/
	public function writeUTFBytes(str:String):Void {
		target.writeUTFBytes(str);
	}

	/**
		@see [`ByteArray writeFloat()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeFloat)
	**/
	public function writeFloat(val:Float):Void {
		// always big endian
		var bytes = getNumberBytes();
		bytes.writeFloat(val);
		bytes.position = 0;
		writeBytes(bytes);
	}

	/**
		@see [`ByteArray writeDouble()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeDouble)
	**/
	public function writeDouble(val:Float):Void {
		// always big endian
		var bytes = getNumberBytes();
		bytes.writeDouble(val);
		bytes.position = 0;
		writeByte(bytes.readByte());
		writeByte(bytes.readByte());
		writeByte(bytes.readByte());
		writeByte(bytes.readByte());
		writeByte(bytes.readByte());
		writeByte(bytes.readByte());
		writeByte(bytes.readByte());
		writeByte(bytes.readByte());
	}

	private function writeAMF3_UTF(str:String):Void {
		var strBytes = new ByteArray();
		strBytes.writeUTFBytes(str);
		writeUInt29((strBytes.length << 1) | 1);
		writeBytes(strBytes);
	}

	private function writeAMF3StringWithoutType(v:String):Void {
		if (v.length == 0) {
			writeUInt29(1);
		} else {
			if (!this.amf3StringByReference(v)) {
				writeAMF3_UTF(v);
			}
		}
	}

	private function amf3StringByReference(v:String):Bool {
		final ref:Int = strings.indexOf(v);
		final found:Bool = ref != -1;
		if (found) {
			writeUInt29(ref << 1);
		} else {
			strings.push(v);
		}
		return found;
	}

	private function amf3ObjectByReference(v:Dynamic):Bool {
		final ref:Int = objects.indexOf(v);
		final found:Bool = ref != -1;
		if (found) {
			writeUInt29(ref << 1);
		} else {
			objects.push(v);
		}
		return found;
	}

	private function traitsByReference(props:Array<Dynamic>, alias:String):Bool {
		// @todo review this. Don't think it is necessary to do the long joins with the props
		// maybe alias alone is enough...?
		final s:String = alias + "|" + props.join("|");
		final ref:Int = traits.indexOf(s);
		final found:Bool = ref != -1;
		if (found) {
			writeUInt29((ref << 2) | 1);
		} else {
			traits.push(s);
		}
		return found;
	}

	private function writeAmf3Int(v:Int):Void {
		if (v >= INT28_MIN_VALUE && v <= INT28_MAX_VALUE) {
			v = v & UINT29_MASK;
			writeByte(AMF3_INTEGER);
			writeUInt29(v);
		} else {
			writeByte(AMF3_DOUBLE);
			writeDouble(v);
		}
	}

	private function writeAmf3Date(v:Date):Void {
		writeByte(AMF3_DATE);
		if (!amf3ObjectByReference(v)) {
			writeUInt29(1);
			writeDouble(v.getTime());
		}
	}

	private function filterSerializableMembers(fieldSet:Dynamic, accessChecks:Dynamic, localTraits:AMFTraits, asAccessors:Bool = false,
			excludeTransient:Bool = true):Array<Dynamic> {
		var l:UInt;
		var metas:Array<Dynamic>;
		var exclude:Bool;
		var transient:Bool;
		var fieldName:String;
		final into:Array<Dynamic> = localTraits.props;

		for (fieldName in Reflect.fields(fieldSet)) {
			// exclude all static props
			if (fieldName.charAt(0) == '|')
				continue;
			// exclude all non-public namespaces (identified by '::' between uri and name)
			if (fieldName.indexOf('::') != -1)
				continue;
			var field:Dynamic = Reflect.field(fieldSet, fieldName);
			exclude = false;
			transient = false;
			var alreadyPresent:Bool = into.indexOf(fieldName) != -1;
			if (asAccessors) {
				exclude = field.access != 'readwrite';
				if (exclude && !alreadyPresent) { // <-- if at some level we already have read-write access, then that wins
					// check: does it combine to provide 'readwrite' permissions via accessChecks through inheritance chain
					if (Reflect.field(accessChecks, fieldName) != null && Reflect.field(accessChecks, fieldName) != field.access) {
						// readonly or writeonly overridde at one level and different at another == readwrite
						exclude = false;
					} else {
						if (Reflect.field(accessChecks, fieldName) == null) {
							// cache for subsequent cross-checks as above
							Reflect.setField(accessChecks, fieldName, field.access);
						}
					}
				}
			}
			// if a subclass override does not redeclare the field as transient, then it is already considered explicitly 'non-transient'
			if (!exclude && !alreadyPresent && excludeTransient && field.metadata != null) {
				// we need to mark Transient fields as special case
				metas = field.metadata();
				l = metas.length;
				while ((l--) > 0) {
					if (metas[l].name == 'Transient') {
						transient = true;
						AMFTraits.markTransient(fieldName, localTraits);
						break;
					}
				}
			}
			if (!exclude) {
				// set up null/undefined value lookups for undefined field values (when encoding)
				var nullValues:Dynamic = localTraits.nullValues;
				if (field.type == 'Number') {
					Reflect.setField(nullValues, fieldName, Math.NaN);
				} else if (field.type == 'Boolean') {
					Reflect.setField(nullValues, fieldName, false);
				} else if (field.type == 'int' || field.type == 'uint') {
					Reflect.setField(nullValues, fieldName, 0);
				} else if (field.type == '*') {
					Reflect.setField(nullValues, fieldName, null /* undefined */);
				} else {
					Reflect.setField(nullValues, fieldName, null);
				}
				if (alreadyPresent) {
					into.splice(into.indexOf(fieldName), 1);
				}
				if (!transient)
					into.push(fieldName);
				if (asAccessors) {
					Reflect.setField(localTraits.getterSetters, fieldName, AMFTraits.createInstanceAccessorGetterSetter(fieldName));
				} else {
					// variable
					Reflect.setField(localTraits.getterSetters, fieldName, AMFTraits.createInstanceVariableGetterSetter(field.get_set, field.type));
				}
			}
		}
		return into;
	}

	private function populateSerializableMembers(reflectionInfo:Dynamic, accessChecks:Dynamic, localTraits:AMFTraits):Array<Dynamic> {
		if (reflectionInfo == null) {
			return localTraits.props;
		}
		var fields:Dynamic = reflectionInfo.variables ? reflectionInfo.variables() : nothing;
		filterSerializableMembers(fields, accessChecks, localTraits, false, true);
		fields = reflectionInfo.accessors ? reflectionInfo.accessors() : nothing;
		filterSerializableMembers(fields, accessChecks, localTraits, true, true);
		return localTraits.props;
	}

	private function getLocalTraitsInfo(instance:Dynamic):AMFTraits {
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

	/**
		@see [`ByteArray writeMultiByte()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeMultiByte)
	**/
	public function writeMultiByte(value:String, charSet:String):Void {
		throw new Error("writeMultiByte not supported");
	}

	/**
		@see [`ByteArray writeObject()`](https://api.openfl.org/openfl/utils/ByteArray.html#writeObject)
	**/
	public function writeObject(v:Dynamic):Void {
		if (!this._writingExternal) {
			reset();
		}
		target.objectEncoding = objectEncoding;
		if (objectEncoding == AMF0) {
			writeAmf0Object(v);
		} else if (objectEncoding == AMF3) {
			writeAmf3Object(v);
		} else {
			throw new ArgumentError("Unsupported objectEncoding: " + objectEncoding);
		}
		if (!this._writingExternal) {
			reset();
		}
	}

	private function writeAmf0Object(v:Dynamic):Void {
		if (v == null) {
			#if html5
			if (v == js.Lib.undefined) {
				writeByte(AMF0_UNDEFINED);
			} else {
				writeByte(AMF0_NULL);
			}
			#else
			writeByte(AMF0_NULL);
			#end
			return;
		}
		if (isFunctionValue(v)) {
			// output function value as undefined
			writeByte(AMF0_UNDEFINED);
			return;
		}
		if ((v is String)) {
			var str:String = (v : String);
			if (str == "") {
				writeByte(AMF0_STRING);
				writeByte(0);
				writeByte(0);
			} else {
				var bytes = new ByteArray();
				bytes.writeUTFBytes(str);
				if (bytes.length < 65536) {
					writeByte(AMF0_STRING);
					writeShort(bytes.length);
				} else {
					writeByte(AMF0_LONG_STRING);
					writeUnsignedInt(bytes.length);
				}
				writeBytes(bytes);
			}
		} else if ((v is Float)) {
			var n:Float = v;
			writeByte(AMF0_NUMBER);
			writeDouble(n);
		} else if ((v is Bool)) {
			writeByte(AMF0_BOOLEAN);
			writeByte(v == true ? 1 : 0);
		} else if ((v is Date)) {
			writeAMF0Date((v : Date));
		}
		/*else if (_xmlClass != null && Std.isOfType(v, _xmlClass)) {
			writeAMF0XML(v);
		}*/
		else {
			if ((v is AMFEcmaArray.AMFEcmaArrayData)) {
				writeAMF0Array(v);
			} else if ((v is Array)) {
				writeAMF0Array(v);
			} else {
				writeAMF0ObjectVariant(v);
			}
		}
	}

	private function writeAmf3Object(v:Dynamic):Void {
		if (v == null) {
			#if html5
			if (v == js.Lib.undefined) {
				writeByte(AMF3_UNDEFINED);
			} else {
				writeByte(AMF3_NULL);
			}
			#else
			writeByte(AMF3_NULL);
			#end
			return;
		}
		if (isFunctionValue(v)) {
			// output function value as undefined
			writeByte(AMF3_UNDEFINED);
			return;
		}
		if ((v is String)) {
			writeByte(AMF3_STRING);
			writeAMF3StringWithoutType((v : String));
		} else if ((v is Float)) {
			var n:Float = v;
			if (n == Math.abs(n) && n == Std.int(n)) {
				writeAmf3Int(Std.int(n));
			} else {
				writeByte(AMF3_DOUBLE);
				writeDouble(n);
			}
		} else if ((v is Bool)) {
			writeByte((v == true ? AMF3_BOOLEAN_TRUE : AMF3_BOOLEAN_FALSE));
		} else if ((v is Date)) {
			writeAmf3Date((v : Date));
		} else {
			if ((v is Xml)) {
				writeHaxeXml(v);
			}
			#if flash
			else if ((v is flash.xml.XML)) {
				writeFlashXML(v);
			}
			#end
		else if ((v is AMFEcmaArray.AMFEcmaArrayData)) {
			writeAmf3Array(v);
		} else if ((v is Array)) {
			writeAmf3Array(v);
		} else if ((v is AMFDictionary.AMFDictionaryData)) {
			writeAmf3Dictionary(v);
		} else if ((v is IMap)) {
			writeAmf3Dictionary(v);
		}
			#if flash
			else if ((v is flash.utils.Dictionary)) {
				var dict:openfl.utils.Dictionary<Dynamic, Dynamic> = v;
				writeFlashDictionary(dict);
			}
			#end
		/* else if ((v is Vector)) {
			writeAmf3Vector(cast(v, Vector<Dynamic>));
		}*/
		else {
			writeAmf3ObjectVariant(v);
		}
		}
	}

	#if flash
	private function writeFlashXML(v:flash.xml.XML):Void {
		writeByte(AMF3_XML);
		if (!this.amf3ObjectByReference(v)) {
			var source:String = v.toXMLString();
			writeAMF3_UTF(source);
		}
	}
	#end

	private function writeHaxeXml(v:Xml):Void {
		writeByte(AMF3_XML);
		if (!this.amf3ObjectByReference(v)) {
			var source:String = v.toString();
			writeAMF3_UTF(source);
		}
	}

	private function writeAmf3ObjectVariant(v:Dynamic):Void {
		if ((v is ByteArrayData)) {
			writeByte(AMF3_BYTEARRAY);
			if (!this.amf3ObjectByReference(v)) {
				var byteArray:ByteArray = cast(v, ByteArray);
				var len:UInt = byteArray.length;
				this.writeUInt29((len << 1) | 1);
				writeBytes(byteArray, 0, len);
			}
			return;
		}

		writeByte(AMF3_OBJECT);
		if (!this.amf3ObjectByReference(v)) {
			final localTraits:AMFTraits = getLocalTraitsInfo(v);
			if (localTraits.externalizable && (localTraits.alias == null || localTraits.alias.length == 0)) {
				// in flash player if you try to write an object with no alias that is externalizable it does this:
				throw new Error("ArgumentError: Error #2004: One of the parameters is invalid.");
			}
			writeAMF3TypedObject(v, localTraits);
		}
	}

	/**
		This serialization context is passed as the 2nd parameter to an IDynamicPropertyWriter
		implementation's writeDynamicProperties method call. The resolved properties are written here
		@param name property name
		@param value property value
	**/
	public function writeDynamicProperty(name:String, value:Dynamic):Void {
		if (objectEncoding == AMF3) {
			this.writeAMF3StringWithoutType(name);
			this.writeAmf3Object(value);
		} else if (objectEncoding == AMF0) {
			this.writeUTF(name);
			this.writeAmf0Object(value);
		} else {
			throw new ArgumentError("Unsupported objectEncoding: " + objectEncoding);
		}
	}

	private function writeAMF3TypedObject(v:Dynamic, localTraits:AMFTraits):Void {
		var encodedName:String = (localTraits.alias != null && localTraits.alias.length > 0) ? localTraits.alias : ']:' + localTraits.qName + ":[";

		if (!traitsByReference(localTraits.props, encodedName)) {
			this.writeUInt29(3 | (localTraits.externalizable ? 4 : 0) | (localTraits.isDynamic ? 8 : 0) | (localTraits.count << 4));
			this.writeAMF3StringWithoutType(localTraits.alias);

			if (!localTraits.externalizable) {
				var l:UInt = localTraits.count;
				for (i in 0...l) {
					this.writeAMF3StringWithoutType(localTraits.props[i]);
				}
			}
		}

		if (localTraits.externalizable) {
			var oldWritingExternal = this._writingExternal;
			this._writingExternal = true;
			v.writeExternal(this);
			this._writingExternal = oldWritingExternal;
		} else {
			var l:UInt = localTraits.count;
			for (i in 0...l) {
				// sealed props
				var val:Dynamic = Reflect.field(localTraits.getterSetters, localTraits.props[i]).getValue(v);
				if (val == null) {
					// coerce null values to the 'correct' types
					val = Reflect.field(localTraits.nullValues, localTraits.props[i]);

					// handle '*' type which can be undefined or explicitly null
					#if html5
					if (val == js.Lib.undefined && Reflect.field(localTraits.getterSetters, localTraits.props[i]).getValue(v) == null) {
						val = null;
					}
					#end
				}
				this.writeAmf3Object(val);
			}

			if (localTraits.isDynamic) {
				if (dynamicPropertyWriter != null) {
					dynamicPropertyWriter.writeDynamicProperties(v, this);
				} else {
					// default implementation
					var dynFields:Array<String> = Reflect.fields(v);
					var l:UInt = dynFields.length;
					for (i in 0...l) {
						var val = Reflect.field(v, dynFields[i]);
						if (isFunctionValue(val)) {
							// skip this name-value pair, don't even write it out as undefined (match flash)
							continue;
						}
						this.writeAMF3StringWithoutType(dynFields[i]);
						this.writeAmf3Object(val);
					}
				}
				// end of dynamic properties marker
				this.writeAMF3StringWithoutType(EMPTY_STRING);
			}
		}
	}

	private var _comparator:String;

	/**
		Javascript does not differentiate between 'Class' and 'Function'
		So in javascript : Object instanceof Function is true, in flash it is not (Object instanceof Class *is* true).
		The function below is an attempt to discriminate between a pure function and a 'constructor' function
		@param value the value to inspect
		@return true if considered to be a 'pure' function value (not a constructor)
	**/
	private function isFunctionValue(value:Dynamic):Bool {
		if (Type.typeof(value) == TFunction) {
			var comparator:String = _comparator;
			var checkBase:Array<Dynamic>;
			if (comparator == null) {
				checkBase = Reflect.fields(function():Void {});
				if (checkBase.indexOf('name') != -1) {
					checkBase.splice(checkBase.indexOf('name'), 1);
				}
				_comparator = comparator = checkBase.join(",");
			}
			checkBase = Reflect.fields(value);
			if (checkBase.indexOf('name') != -1) {
				checkBase.splice(checkBase.indexOf('name'), 1);
			}
			var check:String = checkBase.join(",");
			return check == comparator;
		}
		return false;
	}

	private function writeAmf3Dictionary(v:Dynamic):Void {
		writeByte(AMF3_DICTIONARY);
		if (!this.amf3ObjectByReference(v)) {
			if ((v is AMFDictionary.AMFDictionaryData)) {
				var dict = cast(v, AMFDictionary.AMFDictionaryData<Dynamic, Dynamic>);
				var keys = @:privateAccess dict.keys;
				var values = @:privateAccess dict.values;
				var len = keys.length;
				writeUInt29((len << 1) | 1);
				writeBoolean(@:privateAccess dict.weakKeys);
				for (i in 0...len) {
					writeAmf3Object(keys[i]);
					writeAmf3Object(values[i]);
				}
			} else if ((v is IMap)) {
				var dict = cast(v, IMap<Dynamic, Dynamic>);
				var keys:Array<Dynamic> = [];
				var values:Array<Dynamic> = [];
				for (key in dict) {
					keys.push(key);
					values.push(dict.get(key));
				}
				var len = keys.length;
				writeUInt29((len << 1) | 1);
				writeBoolean((v is WeakMap));
				for (i in 0...len) {
					writeAmf3Object(keys[i]);
					writeAmf3Object(values[i]);
				}
			}
		}
	}

	#if flash
	private function writeFlashDictionary(v:openfl.utils.Dictionary<Dynamic, Dynamic>):Void {
		writeByte(AMF3_DICTIONARY);
		if (!this.amf3ObjectByReference(v)) {
			var keys:Array<Dynamic> = [];
			var values:Array<Dynamic> = [];
			for (key in v) {
				keys.push(key);
				values.push(v[key]);
			}
			var len = keys.length;
			writeUInt29((len << 1) | 1);
			writeBoolean((v is WeakMap));
			for (i in 0...len) {
				writeAmf3Object(keys[i]);
				writeAmf3Object(values[i]);
			}
		}
	}
	#end

	private function writeAmf3Array(v:Dynamic):Void {
		writeByte(AMF3_ARRAY);
		if (!this.amf3ObjectByReference(v)) {
			var len:UInt = 0;
			var akl:UInt = 0; // associative keys length
			var keys:Array<Dynamic> = [];
			if ((v is AMFEcmaArray.AMFEcmaArrayData)) {
				var array = cast(v, AMFEcmaArray.AMFEcmaArrayData<Dynamic>);
				len = array.length;
				#if (haxe_ver >= 4.1)
				for (key => value in array.keyValueIterator()) {
					keys.push(key);
				}
				#else
				for (i in 0...len) {
					keys.push(i);
				}
				#end
			} else if ((v is Array)) {
				var array = cast(v, Array<Dynamic>);
				len = array.length;
				#if (haxe_ver >= 4.1)
				for (key => value in array.keyValueIterator()) {
					keys.push(key);
				}
				#else
				for (i in 0...len) {
					keys.push(i);
				}
				#end
			}
			var denseLength:UInt = len;
			// profile the array
			// es6 specifies a generalized traversal order we can rely upon going forward
			// testing in IE11 shows the same order applies in that es5 Array implementation, so we assume it here:
			/*
				Property keys are traversed in the following order:
				First, the keys that are integer indices, in ascending numeric order.
				note non-integers: '02' round-tripping results in the different string '2'.
					'3.141' is not an integer index, because 3.141 is not an integer.
				Then, all other string keys, in the order in which they were added to the object.
				Lastly, all symbol keys, in the order in which they were added to the object.
				We don't need to worry about Symbols here
			 */
			var kl:UInt = keys.length;
			// Assumption - based on the above,
			// if the last key in the keys is an integer index, and length matches the array.length then it is a pure strict array
			// if not, it is non-strict
			if (kl != len || (kl > 0 && (Std.parseInt(Std.string(keys[kl - 1])) != keys[kl - 1])) || Lambda.exists(v, isFunctionValue)) {
				// Array is not strict
				if (len > 0) {
					// the array has at least some integer keys

					// find denseLength
					for (i in 0...len) {
						denseLength = i;
						if (keys[i] != Std.string(i))
							break;
						// also seems to be true in avm:
						if (isFunctionValue(v[i]))
							break;
					}
					// remove dense keys,
					// leaving only associative keys (which may include valid integer keys outside the dense part)
					keys.splice(0, denseLength);
				} // else all keys are associative keys, and denseLength is zero
				akl = keys.length;
			}
			this.writeUInt29((denseLength << 1) | 1);

			if (akl > 0) {
				// name-value pairs of associative keys
				for (i in 0...akl) {
					var key:String = keys[i];
					var val:Any = null;
					if ((v is AMFEcmaArray.AMFEcmaArrayData)) {
						var array:AMFEcmaArray<Dynamic> = cast(v, AMFEcmaArray.AMFEcmaArrayData<Dynamic>);
						// Reflect.field() doesn't work here because the fields
						// are stored in a private variable
						val = array[key];
					} else {
						val = Reflect.field(v, key);
					}
					if (isFunctionValue(val)) {
						continue;
					}
					this.writeAMF3StringWithoutType(key);
					this.writeAmf3Object(val);
				}
			}
			// empty string 'terminates' associative keys block - no more associative keys (if there were any)
			writeAMF3StringWithoutType(EMPTY_STRING);
			if (denseLength > 0) {
				for (i in 0...denseLength) {
					writeAmf3Object(v[i]);
				}
			}
		}
	}

	private function writeAmf3Vector(v:Dynamic):Void {
		// v is a Vector synthType instance
		var className:String = Type.getClassName(Type.getClass(v));
		var content:Array<Dynamic> = cast(Reflect.field(v, "value"), Array<Dynamic>);
		var amfType:UInt;
		if (className == 'openfl.Vector<Int>')
			amfType = AMF3_VECTOR_INT;
		else if (className == 'openfl.Vector<UInt>')
			amfType = AMF3_VECTOR_UINT;
		else if (className == 'openfl.Vector<Float>')
			amfType = AMF3_VECTOR_DOUBLE;
		else
			amfType = AMF3_VECTOR_OBJECT;
		writeByte(amfType);

		var i:UInt;
		var len:UInt = v.length;
		if (!this.amf3ObjectByReference(v)) {
			this.writeUInt29((len << 1) | 1);
			this.writeBoolean(Reflect.field(v, "fixed") == true);
			if (amfType == AMF3_VECTOR_OBJECT) {
				// note this is available as a specific field, but not yet readily accessible in terms of field name
				className = className.substring(8, className.length - 1); // strip leading 'Vector.<' and trailing '>'
				if (className == "*") {
					className = "";
				} else {
					try {
						className = getAliasByClass(openfl.Lib.getDefinitionByName(className));
						if (className == null) {
							className = "";
						}
					} catch (e:Error) {
						className = "";
					}
				}

				/*if (className == 'Boolean' || className == 'String' || className == 'Class' || className == 'Array' || className=='Object' || className=='*') {
						className = ""; // this will be a Vector.<Object> on read (even for '*' it seems, contrary to spec)
					} else {
				}*/
				this.writeAMF3StringWithoutType(className);
				for (i in 0...len) {
					writeAmf3Object(content[i]);
				}
			} else if (amfType == AMF3_VECTOR_INT) {
				for (i in 0...len) {
					writeInt(content[i]);
				}
			} else if (v.type == AMF3_VECTOR_UINT) {
				for (i in 0...len) {
					writeUnsignedInt(content[i]);
				}
			} else if (v.type == AMF3_VECTOR_DOUBLE) {
				for (i in 0...len) {
					writeDouble(content[i]);
				}
			}
		}
	}

	private function writeAMF0Date(v:Date):Void {
		if (!amf0ObjectByReference(v)) {
			writeByte(AMF0_DATE);
			writeDouble(v.getTime());
			// timezone offset is mandatory but never used
			// it is a S16 in spec, but because it is always zero, cheat:
			writeByte(0);
			writeByte(0);
		}
	}

	private function writeAMF0Vector(v:Dynamic):Void {
		throw new Error("AMF0 Vector not supported");
	}

	private function writeAMF0Array(v:Dynamic):Void {
		// is it strict or associative
		if (!this.amf0ObjectByReference(v)) {
			var len:UInt = 0;
			var keys:Array<Dynamic> = [];
			if ((v is AMFEcmaArray.AMFEcmaArrayData)) {
				var array = cast(v, AMFEcmaArray.AMFEcmaArrayData<Dynamic>);
				len = array.length;
				#if (haxe_ver >= 4.1)
				for (key => value in array.keyValueIterator()) {
					keys.push(key);
				}
				#else
				for (i in 0...len) {
					keys.push(i);
				}
				#end
			} else if ((v is Array)) {
				var array = cast(v, Array<Dynamic>);
				len = array.length;
				#if (haxe_ver >= 4.1)
				for (key => value in array.keyValueIterator()) {
					keys.push(key);
				}
				#else
				for (i in 0...len) {
					keys.push(i);
				}
				#end
			}
			// profile the array
			// es6 specifies a generalized traversal order we can rely upon going forward
			// testing in IE11 shows the same order applies in that es5 Array implementation, so we assume it here:
			/*
				Property keys are traversed in the following order:
				First, the keys that are integer indices, in ascending numeric order.
				note non-integers: '02' round-tripping results in the different string '2'.
					'3.141' is not an integer index, because 3.141 is not an integer.
				Then, all other string keys, in the order in which they were added to the object.
				Lastly, all symbol keys, in the order in which they were added to the object.
				We don't need to worry about Symbols here
			 */
			var kl:UInt = keys.length;
			// Assumption - based on the above,
			// if the last key in the keys is an integer index, and length matches the array.length then it is a pure strict array
			// if not, it is non-strict
			// discriminate between strict and ecma by any inclusion or not of non-ordinal keys only. dense vs. non-dense is not a factor
			if (kl > 0 && Std.parseInt(Std.string((keys[kl - 1]))) != keys[kl - 1]) {
				// ecma
				writeByte(AMF0_ECMA_ARRAY);
				writeUnsignedInt(len);
				len = keys.length;
				for (i in 0...len) {
					var key:String = keys[i];
					var val:Dynamic = null;
					if ((v is AMFEcmaArray.AMFEcmaArrayData)) {
						var array:AMFEcmaArray<Dynamic> = cast(v, AMFEcmaArray.AMFEcmaArrayData<Dynamic>);
						// Reflect.field() doesn't work here because the fields
						// are stored in a private variable
						val = array[key];
					} else {
						val = Reflect.field(v, key);
					}
					if (!isFunctionValue(val)) {
						writeUTF(key);
						writeAmf0Object(val);
					}
				}
				// end of object
				writeByte(0);
				writeByte(0);
				writeByte(AMF0_OBJECT_END);
			} else {
				// strict
				// encode as ecma anyway... because player seems to do that
				writeByte(AMF0_ECMA_ARRAY);
				writeUnsignedInt(len); // array length
				len = keys.length; // now keys length
				for (i in 0...len) {
					var key:Any = keys[i];
					var val:Any = null;
					if ((key is Int)) {
						val = v[(key : Int)];
					} else {
						val = Reflect.field(v, Std.string(key));
					}
					if (!isFunctionValue(val)) {
						writeUTF(Std.string(key));
						writeAmf0Object(val);
					}
				}
				writeByte(0);
				writeByte(0);
				writeByte(AMF0_OBJECT_END);
			}
		}
	}

	private function amf0ObjectByReference(v:Dynamic):Bool {
		final ref = objects.indexOf(v);
		final found:Bool = ref != -1;
		if (found) {
			writeByte(AMF0_REFERENCE);
			writeShort(ref);
		} else {
			objects.push(v);
		}
		return found;
	}

	private function writeAMF0ObjectVariant(v:Dynamic):Void {
		if (!this.amf0ObjectByReference(v)) {
			final localTraits:AMFTraits = getLocalTraitsInfo(v);
			writeAMF0TypedObject(v, localTraits);
		}
	}

	private function writeAMF0TypedObject(v:Dynamic, localTraits:AMFTraits):Void {
		if (localTraits.alias == null || localTraits.alias.length == 0) {
			writeByte(AMF0_OBJECT);
		} else {
			writeByte(AMF0_TYPED_OBJECT);
			writeUTF(localTraits.alias);
		}
		var l:UInt = localTraits.count;
		for (i in 0...l) {
			// sealed props
			var val:Dynamic = Reflect.field(localTraits.getterSetters, localTraits.props[i]).getValue(v);
			if (val == null) {
				// coerce null values to the 'correct' types
				val = Reflect.field(localTraits.nullValues, localTraits.props[i]);

				// handle '*' type which can be undefined or explicitly null
				#if html5
				if (val == js.Lib.undefined && Reflect.field(localTraits.getterSetters, localTraits.props[i]).getValue(v) == null) {
					val = null;
				}
				#end
			}
			this.writeUTF(localTraits.props[i]);
			this.writeAmf0Object(val);
		}

		if (localTraits.isDynamic) {
			// default implementation
			var dynFields:Array<String> = Reflect.fields(v);
			l = dynFields.length;
			for (i in 0...l) {
				var val:Dynamic = Reflect.field(v, dynFields[i]);
				if (isFunctionValue(val)) {
					// skip this name-value pair, don't even write it out as undefined (match flash)
					continue;
				}
				this.writeUTF(dynFields[i]);
				this.writeAmf0Object(val);
			}
		}

		writeByte(0);
		writeByte(0);
		writeByte(AMF0_OBJECT_END);
	}

	private function writeAMF0XML(v:Dynamic):Void {
		// e4x XML does not exist in AMF0.
		// so send to 'Object'
		writeAMF0ObjectVariant(v);
	}
}
