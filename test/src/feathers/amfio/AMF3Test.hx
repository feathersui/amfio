/*
	Feathers UI AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import haxe.Constraints.Function;
import openfl.errors.Error;
import openfl.utils.ByteArray;
import openfl.utils.IDataInput;
import openfl.utils.IDataOutput;
import openfl.utils.IExternalizable;
import utest.Assert;
import utest.Test;

class AMF3Test extends Test {
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
		ba.objectEncoding = AMF3;
		ba.endian = BIG_ENDIAN;
		writer = new AMFWriter(ba);
		writer.objectEncoding = AMF3;
		writer.endian = BIG_ENDIAN;
		reader = new AMFReader(ba);
		reader.objectEncoding = AMF3;
		reader.endian = BIG_ENDIAN;
	}

	public function testEmptyString():Void {
		var testString = "";

		writer.writeObject(testString);

		Assert.equals(2, ba.length);
		Assert.equals(2, ba.position);

		ba.position = 0;
		Assert.equals(testString, reader.readObject());

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testString():Void {
		var testString = "testString";

		writer.writeObject(testString);

		Assert.equals(12, ba.length);
		Assert.equals(12, ba.position);

		ba.position = 0;
		Assert.equals(testString, reader.readObject());

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testBooleanTrue():Void {
		writer.writeObject(true);

		Assert.equals(1, ba.length);
		Assert.equals(1, ba.position);

		ba.position = 0;
		Assert.equals(true, reader.readObject());

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testBooleanFalse():Void {
		writer.writeObject(false);

		Assert.equals(1, ba.length);
		Assert.equals(1, ba.position);

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

		Assert.equals(58, ba.length);
		Assert.equals(58, ba.position);

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

		Assert.equals(3, ba.length);
		Assert.equals(3, ba.position);

		ba.position = 0;
		var val:Array<Dynamic> = reader.readObject();
		Assert.isOfType(val, Array);
		Assert.equals(0, val.length);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testArrayInstance():Void {
		var instance:Array<Dynamic> = [99];
		writer.writeObject(instance);
		Assert.isTrue(bytesMatchExpectedData(ba, [9, 3, 1, 4, 99]));

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
			9, 7, 1, 10, 11, 1, 9, 116, 101, 115, 116, 3, 1, 10, 1, 0, 6, 11, 109, 97, 121, 98, 101, 1, 10, 1, 0, 3, 1
		]));
	}

	public function testDuplicateStructure():Void {
		var obj = {test: true};
		writer.writeObject([obj, obj]);
		Assert.equals(15, ba.length);
		Assert.equals(15, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [9, 5, 1, 10, 11, 1, 9, 116, 101, 115, 116, 3, 1, 10, 2]));

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
		Assert.equals(20, ba.length);
		Assert.equals(20, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [10, 11, 1, 9, 116, 101, 115, 116, 3, 1, 10, 11, 1, 9, 116, 101, 115, 116, 3, 1]));

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
		Assert.isTrue(bytesMatchExpectedData(ba, [0]));

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
		Assert.isTrue(bytesMatchExpectedData(ba, [10, 11, 1, 1]));

		ba.position = 0;
		var obj = reader.readObject();
		// the dynamic deserialized object has no key for the function value
		Assert.isTrue(dynamicKeyCountMatches(obj, 0));

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testBasicClassInstance():Void {
		var instance = new TestClass1();
		writer.writeObject(instance);

		Assert.equals(16, ba.length);
		Assert.equals(16, ba.position);

		Assert.isTrue(bytesMatchExpectedData(ba, [10, 19, 1, 21, 116, 101, 115, 116, 70, 105, 101, 108, 100, 49, 6, 1]));

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

		Assert.equals(24, ba.length);
		Assert.equals(24, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [
			9, 5, 1, 10, 19, 1, 21, 116, 101, 115, 116, 70, 105, 101, 108, 100, 49, 6, 1, 10, 19, 1, 0, 3
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

	public function testByteArray():Void {
		var source = new ByteArray();

		for (i in 0...26) {
			source.writeByte(i);
		}
		var holder = [source, source];

		writer.writeObject(holder);
		Assert.equals(33, ba.length);
		Assert.equals(33, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [
			9, 5, 1, 12, 53, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 12, 2
		]));

		ba.position = 0;
		var result:Array<Any> = reader.readObject();
		Assert.isOfType(result, Array);
		Assert.equals(2, result.length);
		Assert.notEquals(source, result[0]);
		Assert.notEquals(source, result[1]);
		Assert.equals(result[0], result[1]);
		Assert.isTrue(bytesMatchExpectedData(result[0], [
			0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
		]));

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testExternalizableWithoutRegisterClassAlias():Void {
		var test3 = new TestClass3a();
		// TestClass3 is externalizable and does not have an alias, this is an error in flash

		var err:Error = null;
		try {
			writer.writeObject(test3);
		} catch (e:Error) {
			err = e;
		}

		Assert.notNull(err);
		Assert.equals(1, ba.length);
		Assert.equals(1, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [10]));
	}

	#if (!flash && openfl >= "9.2.0")
	public function testExternalizable():Void {
		var test3 = new TestClass3b();
		// register an alias
		openfl.Lib.registerClassAlias("TestClass3", TestClass3b);
		writer.writeObject(test3);
		Assert.equals(18, ba.length);
		Assert.equals(18, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [10, 7, 21, 84, 101, 115, 116, 67, 108, 97, 115, 115, 51, 9, 3, 1, 6, 0]));

		ba.position = 0;
		var result = reader.readObject();
		Assert.isOfType(result, TestClass3b);
		Assert.notEquals(test3, result);
		Assert.notEquals(test3.content, result.content);
		Assert.equals(test3.content[0], result.content[0]);

		Assert.equals(0, ba.bytesAvailable);
	}

	public function testExternalizable2():Void {
		var test3 = new TestClass3c();
		// register an alias
		openfl.Lib.registerClassAlias("TestClass3", TestClass3c);
		var chars = (test3.content[0]).split("");
		chars.reverse();
		test3.content[0] = chars.join("");
		writer.writeObject(test3);
		Assert.equals(28, ba.length);
		Assert.equals(28, ba.position);
		Assert.isTrue(bytesMatchExpectedData(ba, [
			10, 7, 21, 84, 101, 115, 116, 67, 108, 97, 115, 115, 51, 9, 3, 1, 6, 21, 51, 115, 115, 97, 108, 67, 116, 115, 101, 84
		]));

		ba.position = 0;
		var result = reader.readObject();
		// proof that it created a new instance, and that the reversed content string content is present in the new instance
		Assert.isOfType(result, TestClass3c);
		Assert.notEquals(test3, result);
		Assert.notEquals(test3.content, result.content);
		Assert.equals(test3.content[0], result.content[0]);

		Assert.equals(0, ba.bytesAvailable);
	}
	#end
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

@:keep
private class TestClass3a implements IExternalizable {
	public function new() {}

	public var content:Array<String> = ["TestClass3"];

	public function readExternal(input:IDataInput):Void {
		var content:Array<String> = (input.readObject() : Array<String>);
		this.content = content;
	}

	public function writeExternal(output:IDataOutput):Void {
		output.writeObject(content);
	}
}

@:keep
private class TestClass3b implements IExternalizable {
	public function new() {}

	public var content:Array<String> = ["TestClass3"];

	public function readExternal(input:IDataInput):Void {
		var content:Array<String> = (input.readObject() : Array<String>);
		this.content = content;
	}

	public function writeExternal(output:IDataOutput):Void {
		output.writeObject(content);
	}
}

@:keep
private class TestClass3c implements IExternalizable {
	public function new() {}

	public var content:Array<String> = ["TestClass3"];

	public function readExternal(input:IDataInput):Void {
		var content:Array<String> = (input.readObject() : Array<String>);
		this.content = content;
	}

	public function writeExternal(output:IDataOutput):Void {
		output.writeObject(content);
	}
}

@:keep
private class TestClass4 {
	public function new() {}

	public var testField1:Function;
}
