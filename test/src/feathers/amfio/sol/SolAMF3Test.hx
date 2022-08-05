/*
	Feathers UI AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio.sol;

import openfl.Lib;
import feathers.amfio.sol.testdata.AMF3ArrayDemo;
import feathers.amfio.sol.testdata.AMF3BooleanDemo;
import feathers.amfio.sol.testdata.AMF3ByteArrayDemo;
import feathers.amfio.sol.testdata.AMF3DateDemo;
import feathers.amfio.sol.testdata.AMF3DictionaryDemo;
import feathers.amfio.sol.testdata.AMF3IntegerDemo;
import feathers.amfio.sol.testdata.AMF3NullDemo;
import feathers.amfio.sol.testdata.AMF3NumberDemo;
import feathers.amfio.sol.testdata.AMF3ObjectDemo;
import feathers.amfio.sol.testdata.AMF3StringDemo;
import feathers.amfio.sol.testdata.AMF3UndefinedDemo;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import utest.Assert;
import utest.Test;
import com.AS3SolTestClass;

class SolAMF3Test extends Test {
	public function new() {
		super();
	}

	private var reader:SolReader;
	private var writer:SolWriter;

	public function setupClass():Void {
		#if (openfl >= "9.2.0")
		Lib.registerClassAlias("com.AS3SolTestClass", AS3SolTestClass);
		#end
	}

	public function setup():Void {
		reader = new SolReader();
		writer = new SolWriter();
	}

	public function testArray():Void {
		function verify(result:Dynamic):Void {
			var expected = [1, 2, 3];
			Assert.isTrue(Reflect.hasField(result, "myIntArray"));
			var actual = result.myIntArray;
			Assert.notNull(actual);
			Assert.equals(expected.length, actual.length);
			Assert.equals(expected[0], actual[0]);
			Assert.equals(expected[1], actual[1]);
			Assert.equals(expected[2], actual[2]);
		}

		var bytes = new AMF3ArrayDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testEcmaArray():Void {
		// TODO: create a test file with Flash/AIR
		var expected:AMFEcmaArray<Dynamic> = [];
		expected["one"] = "eins";
		expected["two"] = "zwei";
		function verify(result:Dynamic):Void {
			Assert.isTrue(Reflect.hasField(result, "myStringArray"));
			var actual:AMFEcmaArray<Dynamic> = result.myStringArray;
			Assert.notNull(actual);
			Assert.notNull(actual["one"]);
			Assert.notNull(actual["two"]);
			Assert.equals(expected["one"], actual["one"]);
			Assert.equals(expected["two"], actual["two"]);
		}

		var original = {myStringArray: expected};

		var resultBytes = writer.write("", original, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testBoolean():Void {
		function verify(result:Dynamic):Void {
			Assert.isTrue(Reflect.hasField(result, "myBool"));
			Assert.isTrue(result.myBool);
		}

		var bytes = new AMF3BooleanDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testByteArray():Void {
		function verify(result:Dynamic):Void {
			Assert.isTrue(Reflect.hasField(result, "myByteArray"));
			var actual:ByteArray = result.myByteArray;
			actual.position = 0;
			var expected = [0, 12, 72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, 33];
			Assert.equals(expected.length, actual.bytesAvailable);
			while (actual.bytesAvailable > 0) {
				var expectedByte = expected.shift();
				var actualByte = actual.readByte();
				Assert.equals(expectedByte, actualByte);
			}
		}

		var bytes = new AMF3ByteArrayDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testDate():Void {
		function verify(result:Dynamic):Void {
			var expected = new Date(2014, 8, 2, 5, 27, 7);
			Assert.isTrue(Reflect.hasField(result, "myDate"));
			var actual = result.myDate;
			Assert.notNull(actual);
			Assert.equals(expected.getFullYear(), actual.getFullYear());
			Assert.equals(expected.getMonth(), actual.getMonth());
			Assert.equals(expected.getDate(), actual.getDate());
			// hours may not be accurate because Haxe Date timezone is odd
			// Assert.equals(expected.getHours(), actual.getHours());
			Assert.equals(expected.getMinutes(), actual.getMinutes());
			Assert.equals(expected.getSeconds(), actual.getSeconds());
		}

		var bytes = new AMF3DateDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	#if (openfl >= "9.2.0")
	public function testDictionary():Void {
		function verify(result:Dynamic):Void {
			var expected = new AMFDictionary<Dynamic, Dynamic>();
			expected["0"] = {foo: "value0"};
			expected["key1"] = {foo: "what"};
			var xml = Xml.parse("<start>\n  <span>testing</span>\n</start>");
			expected[xml] = "value4";
			expected[new AS3SolTestClass()] = "value2";
			expected[{this_is: "a test"}] = "value3";

			Assert.isTrue(Reflect.hasField(result, "myDictionary"));
			var actual:AMFDictionary<Dynamic, Dynamic> = result.myDictionary;
			Assert.notNull(actual);
			Assert.notNull(actual["0"]);
			Assert.equals(expected["0"].foo, actual["0"].foo);
			Assert.notNull(actual["key1"]);
			Assert.equals(expected["key1"].foo, actual["key1"].foo);
			// TODO: XML key
			// TODO: typed object
			// TODO: object key
		}

		var bytes = new AMF3DictionaryDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}
	#end

	public function testInteger():Void {
		function verify(result:Dynamic):Void {
			var expected = 7;
			Assert.isTrue(Reflect.hasField(result, "myInt"));
			Assert.equals(expected, result.myInt);
		}

		var bytes = new AMF3IntegerDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testNull():Void {
		function verify(result:Dynamic):Void {
			Assert.isTrue(Reflect.hasField(result, "myNull"));
			Assert.isNull(result.myNull);
		}

		var bytes = new AMF3NullDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testNumber():Void {
		function verify(result:Dynamic):Void {
			var expected = 3.141592653589793;
			Assert.isTrue(Reflect.hasField(result, "myFloat"));
			Assert.equals(expected, result.myFloat);
		}

		var bytes = new AMF3NumberDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testObject():Void {
		function verify(result:Dynamic):Void {
			var expected = {
				p1: 5,
				p2: "hallo",
				p3: 3.1415926535897931,
				p4: {prop: "val"},
				p5: new Date(2014, 8, 2, 17, 33, 16)
			};
			Assert.isTrue(Reflect.hasField(result, "myObject"));
			var actual = result.myObject;
			Assert.notNull(actual);
			Assert.equals(Reflect.fields(expected).length, Reflect.fields(actual).length);
			Assert.equals(expected.p1, actual.p1);
			Assert.equals(expected.p2, actual.p2);
			Assert.equals(expected.p3, actual.p3);
			Assert.notNull(actual.p4);
			Assert.equals(expected.p4.prop, actual.p4.prop);
			Assert.notNull(actual.p5);
			Assert.equals(expected.p5.getFullYear(), actual.p5.getFullYear());
			Assert.equals(expected.p5.getMonth(), actual.p5.getMonth());
			Assert.equals(expected.p5.getDate(), actual.p5.getDate());
			// hours may not be accurate because Haxe Date timezone is weird
			// Assert.equals(expected.p5.getHours(), actual.p5.getHours());
			Assert.equals(expected.p5.getMinutes(), actual.p5.getMinutes());
			Assert.equals(expected.p5.getSeconds(), actual.p5.getSeconds());
		}

		var bytes = new AMF3ObjectDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testString():Void {
		function verify(result:Dynamic):Void {
			var expected = "ralle";
			Assert.isTrue(Reflect.hasField(result, "myString"));
			Assert.equals(expected, result.myString);
		}

		var bytes = new AMF3StringDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testUndefined():Void {
		function verify(result:Dynamic):Void {
			Assert.isTrue(Reflect.hasField(result, "myUndefined"));
			Assert.isNull(result.myUndefined);
		}

		var bytes = new AMF3UndefinedDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF3);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}
}
