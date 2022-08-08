/*
	AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import openfl.utils.ByteArray;
import utest.Assert;
import utest.Test;

class AMF0Test extends Test {
	// util check functions
	private static function bytesMatchExpectedData(bytes:ByteArray, expected:Array<UInt>, offset:Int = 0):Bool {
		var len = expected.length;
		var end = offset + len;
		var savedPos = bytes.position;
		bytes.position = offset;
		for (i in offset...end) {
			var check = bytes.readUnsignedByte();
			if (expected[i - offset] != check) {
				trace("failed at " + i, expected[i - offset], check);
				bytes.position = savedPos;
				return false;
			}
		}
		bytes.position = savedPos;
		return true;
	}

	private static function dynamicKeyCountMatches(forObject:Dynamic, expectedCount:Int):Bool {
		return Reflect.fields(forObject).length == expectedCount;
	}

	public function new() {
		super();
	}

	private var ba:ByteArray;
	private var writer:AMFWriter;
	private var reader:AMFReader;

	public function setup():Void {
		ba = new ByteArray();
		ba.objectEncoding = AMF0;
		ba.endian = BIG_ENDIAN;
		writer = new AMFWriter(ba);
		writer.objectEncoding = AMF0;
		writer.endian = BIG_ENDIAN;
		reader = new AMFReader(ba);
		reader.objectEncoding = AMF0;
		reader.endian = BIG_ENDIAN;
	}

	public function testEmptyString():Void {
		var testString = "";
		writer.writeObject(testString);
		Assert.equals(3, ba.length);
		Assert.equals(3, ba.position);

		ba.position = 0;
		Assert.equals(testString, reader.readObject());

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testString():Void {
		var testString = "testString";

		writer.writeObject(testString);

		Assert.equals(13, ba.length);
		Assert.equals(13, ba.position);

		ba.position = 0;
		Assert.equals(testString, reader.readObject());

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testLongString():Void {
		var baseString:String = "";
		var l = 94; // include all ascii chars between 32 to 126
		while (l >= 0) {
			baseString += String.fromCharCode(32 + 94 - l);
			l--;
		}
		var buffer:Array<String> = [];
		while (l < 65536) {
			buffer.push(baseString);
			l += baseString.length;
		}
		var fullString = buffer.join("");

		writer.writeObject(fullString);

		Assert.equals(65555, ba.length);
		Assert.equals(65555, ba.position);

		ba.position = 0;
		var result = reader.readObject();
		Assert.equals(fullString, result);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testBooleanTrue():Void {
		writer.writeObject(true);

		Assert.equals(2, ba.length);
		Assert.equals(2, ba.position);

		ba.position = 0;
		Assert.equals(true, reader.readObject());

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testBooleanFalse():Void {
		writer.writeObject(false);

		Assert.equals(2, ba.length);
		Assert.equals(2, ba.position);
		ba.position = 0;

		Assert.equals(false, reader.readObject());

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testFloat():Void {
		writer.writeObject(Math.NaN);
		writer.writeObject(0.0);
		writer.writeObject(1.0);
		writer.writeObject(-1.0);
		writer.writeObject(1.5);
		writer.writeObject(-1.5);
		writer.writeObject(Math.POSITIVE_INFINITY);
		writer.writeObject(Math.NEGATIVE_INFINITY);

		Assert.equals(72, ba.length);
		Assert.equals(72, ba.position);

		ba.position = 0;
		var num = reader.readObject();
		Assert.isOfType(num, Float);
		Assert.isTrue(Math.isNaN(num));
		num = reader.readObject();
		Assert.isTrue((num is Float));
		Assert.equals(0.0, num);
		num = reader.readObject();
		Assert.isTrue((num is Float));
		Assert.equals(1.0, num);
		num = reader.readObject();
		Assert.isTrue((num is Float));
		Assert.equals(-1.0, num);
		num = reader.readObject();
		Assert.isTrue((num is Float));
		Assert.equals(1.5, num);
		num = reader.readObject();
		Assert.isTrue((num is Float));
		Assert.equals(-1.5, num);
		num = reader.readObject();
		Assert.isTrue((num is Float));
		Assert.isTrue(!Math.isFinite(num));
		Assert.isTrue(num > 0);
		Assert.equals(Math.POSITIVE_INFINITY, num);
		num = reader.readObject();
		Assert.isTrue((num is Float));
		Assert.isTrue(!Math.isFinite(num));
		Assert.isTrue(num < 0);
		Assert.equals(Math.NEGATIVE_INFINITY, num);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testNull():Void {
		writer.writeObject(null);

		Assert.equals(1, ba.length);
		Assert.equals(1, ba.position);

		ba.position = 0;
		var val = reader.readObject();
		Assert.isNull(val);

		Assert.equals(0, ba.bytesAvailable);
	}

	#if html5
	// other targets have only null, not undefined
	// so there's nothing to test
	public function testUndefined():Void {
		writer.writeObject(js.Lib.undefined);

		Assert.equals(1, ba.length);
		Assert.equals(1, ba.position);

		ba.position = 0;
		var val = reader.readObject();
		Assert.equals(js.Lib.undefined, val);
		Assert.isNull(val);

		Assert.equals(0, ba.bytesAvailable);
	}
	#end

	public function testEmptyArray():Void {
		var instance:Array<Dynamic> = [];
		writer.writeObject(instance);

		Assert.equals(8, ba.length);
		Assert.equals(8, ba.position);

		ba.position = 0;
		var val:Array<Dynamic> = reader.readObject();
		Assert.isOfType(val, Array);
		Assert.equals(0, val.length);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testArrayInstance():Void {
		var instance:Array<Dynamic> = [99];
		writer.writeObject(instance);
		Assert.isTrue(bytesMatchExpectedData(ba, [
			0x08, 0x00, 0x00, 0x00, 0x01, 0x00, 0x01, 0x30, 0x00, 0x40, 0x58, 0xc0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09
		]));

		ba.position = 0;
		instance = reader.readObject();
		Assert.equals(1, instance.length);
		Assert.equals(99, instance[0]);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testEmptyStructure():Void {
		var instance = {};
		writer.writeObject(instance);

		Assert.equals(4, ba.length);
		Assert.equals(4, ba.position);

		ba.position = 0;
		var val = reader.readObject();
		Assert.isTrue(Type.typeof(val) == TObject);
		Assert.isTrue(dynamicKeyCountMatches(instance, 0));

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testArrayOfStructures():Void {
		var obj1 = {test: true};
		var obj2 = {test: "maybe"};
		var obj3 = {test: true};
		writer.writeObject([obj1, obj2, obj3]);

		ba.position = 0;
		Assert.isTrue(bytesMatchExpectedData(ba, [
			0x08, 0x00, 0x00, 0x00, 0x03, 0x00, 0x01, 0x30, 0x03, 0x00, 0x04, 0x74, 0x65, 0x73, 0x74, 0x01, 0x01, 0x00, 0x00, 0x09, 0x00, 0x01, 0x31, 0x03,
			0x00, 0x04, 0x74, 0x65, 0x73, 0x74, 0x02, 0x00, 0x05, 0x6d, 0x61, 0x79, 0x62, 0x65, 0x00, 0x00, 0x09, 0x00, 0x01, 0x32, 0x03, 0x00, 0x04, 0x74,
			0x65, 0x73, 0x74, 0x01, 0x01, 0x00, 0x00, 0x09, 0x00, 0x00, 0x09
		]));
	}

	public function testDuplicateStructure():Void {
		var obj = {test: true};
		writer.writeObject([obj, obj]);
		Assert.equals(29, ba.length);
		Assert.equals(29, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [
			8, 0, 0, 0, 2, 0, 1, 48, 3, 0, 4, 116, 101, 115, 116, 1, 1, 0, 0, 9, 0, 1, 49, 7, 0, 1, 0, 0, 9
		]));

		ba.position = 0;
		var result:Array<Any> = reader.readObject();
		Assert.isOfType(result, Array);
		Assert.equals(2, result.length);
		Assert.notNull(result[0]);
		Assert.notNull(result[1]);
		// should refer to the same object
		Assert.equals(result[0], result[1]);
		Assert.isTrue(Type.typeof(result[0]) == TObject);
		Assert.isTrue(Type.typeof(result[1]) == TObject);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testDuplicateStructureWithSeparateWriteObjectCalls():Void {
		var obj = {test: true};
		writer.writeObject(obj);
		writer.writeObject(obj);
		Assert.equals(24, ba.length);
		Assert.equals(24, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [
			3, 0, 4, 116, 101, 115, 116, 1, 1, 0, 0, 9, 3, 0, 4, 116, 101, 115, 116, 1, 1, 0, 0, 9
		]));

		ba.position = 0;
		var result1 = reader.readObject();
		var result2 = reader.readObject();
		// should not refer to the same object
		Assert.notEquals(result1, result2);
		Assert.isTrue(Reflect.field(result1, "test"));
		Assert.isTrue(Reflect.field(result2, "test"));

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testFunction():Void {
		// functions are always encoded as undefined
		var instance = function():Void {};
		writer.writeObject(instance);

		Assert.equals(1, ba.length);
		Assert.equals(1, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [0x06]));

		ba.position = 0;
		instance = reader.readObject();
		Assert.isNull(instance);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testObjectWithFunction():Void {
		// for a property that has a function value, the property is also undefined
		var objectWithFunction = {
			'function': function():Void {}
		};
		writer.writeObject(objectWithFunction);

		Assert.equals(4, ba.length);
		Assert.equals(4, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [0x03, 0x00, 0x00, 0x09]));

		ba.position = 0;
		var obj = reader.readObject();
		// the dynamic deserialized object has no key for the function value
		Assert.isTrue(dynamicKeyCountMatches(obj, 0));

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testBasicClassInstance():Void {
		var instance = new TestClass1();
		writer.writeObject(instance);

		Assert.equals(19, ba.length);
		Assert.equals(19, ba.position);

		Assert.isTrue(bytesMatchExpectedData(ba, [
			0x03, 0x00, 0x0a, 0x74, 0x65, 0x73, 0x74, 0x46, 0x69, 0x65, 0x6c, 0x64, 0x31, 0x02, 0x00, 0x00, 0x00, 0x00, 0x09
		]));

		ba.position = 0;
		var anonObject = reader.readObject();
		// should not be typed
		Assert.isFalse((anonObject is TestClass1));
		Assert.equals(instance.testField1, Reflect.field(anonObject, "testField1"));

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testBasicClassInstances():Void {
		var obj1 = new TestClass1();
		var obj2 = new TestClass2();
		var multipleDifferentInstances:Array<Dynamic> = [obj1, obj2];
		writer.writeObject(multipleDifferentInstances);

		Assert.equals(51, ba.length);
		Assert.equals(51, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [
			0x08, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0x30, 0x03, 0x00, 0x0a, 0x74, 0x65, 0x73, 0x74, 0x46, 0x69, 0x65, 0x6c, 0x64, 0x31, 0x02, 0x00, 0x00,
			0x00, 0x00, 0x09, 0x00, 0x01, 0x31, 0x03, 0x00, 0x0a, 0x74, 0x65, 0x73, 0x74, 0x46, 0x69, 0x65, 0x6c, 0x64, 0x31, 0x01, 0x01, 0x00, 0x00, 0x09,
			0x00, 0x00, 0x09
		]));

		ba.position = 0;
		var result:Array<Any> = reader.readObject();
		Assert.isOfType(result, Array);
		Assert.equals(2, result.length);
		Assert.notEquals(obj1, result[0]);
		Assert.notEquals(obj2, result[0]);
		Assert.notEquals(obj1, result[1]);
		Assert.notEquals(obj2, result[1]);
		Assert.isFalse((result[0] is TestClass1));
		Assert.isFalse((result[0] is TestClass2));
		Assert.isFalse((result[1] is TestClass1));
		Assert.isFalse((result[1] is TestClass2));

		Assert.equals(0, ba.bytesAvailable);
	}
}

@:keep
private class TestClass1 {
	public function new() {}

	public var testField1:String = "";
}

@:keep
private class TestClass2 {
	// Note: do not change this test class unless you change the related tests to
	// support any changes that might appear when testing reflection into it
	public function new() {}

	public var testField1:Bool = true;
}
