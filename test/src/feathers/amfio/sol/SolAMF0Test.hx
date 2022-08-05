/*
	Feathers UI AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio.sol;

import feathers.amfio.sol.testdata.AMF0ArrayDemo;
import feathers.amfio.sol.testdata.AMF0BooleanDemo;
import feathers.amfio.sol.testdata.AMF0DateDemo;
import feathers.amfio.sol.testdata.AMF0ECMAArrayDemo;
import feathers.amfio.sol.testdata.AMF0IntegerDemo;
import feathers.amfio.sol.testdata.AMF0LongStringDemo;
import feathers.amfio.sol.testdata.AMF0NullDemo;
import feathers.amfio.sol.testdata.AMF0NumberDemo;
import feathers.amfio.sol.testdata.AMF0ObjectDemo;
import feathers.amfio.sol.testdata.AMF0StringDemo;
import feathers.amfio.sol.testdata.AMF0UndefinedDemo;
import feathers.amfio.sol.testdata.LongString;
import openfl.utils.Endian;
import utest.Assert;
import utest.Test;

class SolAMF0Test extends Test {
	public function new() {
		super();
	}

	private var reader:SolReader;
	private var writer:SolWriter;

	public function setup():Void {
		reader = new SolReader();
		writer = new SolWriter();
	}

	public function testArray():Void {
		function verify(result:Dynamic) {
			var expected = [1, 2, 3];
			Assert.isTrue(Reflect.hasField(result, "myIntArray"));
			var actual = cast(result.myIntArray, Array<Dynamic>);
			Assert.notNull(actual);
			Assert.equals(expected.length, actual.length);
			Assert.equals(expected[0], actual[0]);
			Assert.equals(expected[1], actual[1]);
			Assert.equals(expected[2], actual[2]);
		}

		var bytes = new AMF0ArrayDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		Assert.isTrue(Reflect.hasField(result2, "myIntArray"));
		verify(result2);
	}

	public function testBoolean():Void {
		function verify(result:Dynamic):Void {
			Assert.isTrue(Reflect.hasField(result, "myBool"));
			Assert.isTrue(result.myBool);
		}

		var bytes = new AMF0BooleanDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testDate():Void {
		function verify(result:Dynamic):Void {
			var expected = new Date(2014, 8, 2, 3, 23, 3);
			Assert.isTrue(Reflect.hasField(result, "myDate"));
			var actual = result.myDate;
			Assert.notNull(actual);
			Assert.equals(expected.getFullYear(), actual.getFullYear());
			Assert.equals(expected.getMonth(), actual.getMonth());
			Assert.equals(expected.getDate(), actual.getDate());
			// hours may not be accurate because Haxe Date timezone is weird
			// Assert.equals(expected.getHours(), actual.getHours());
			Assert.equals(expected.getMinutes(), actual.getMinutes());
			Assert.equals(expected.getSeconds(), actual.getSeconds());
		}
		var bytes = new AMF0DateDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testEcmaArray():Void {
		function verify(result:Dynamic) {
			var expected:AMFEcmaArray<Dynamic> = [];
			expected["one"] = "eins";
			expected["two"] = "zwei";
			Assert.isTrue(Reflect.hasField(result, "myStringArray"));
			var actual:AMFEcmaArray<Dynamic> = result.myStringArray;
			Assert.notNull(actual);
			Assert.notNull(actual["one"]);
			Assert.notNull(actual["two"]);
			Assert.equals(expected["one"], actual["one"]);
			Assert.equals(expected["two"], actual["two"]);
		}

		var bytes = new AMF0ECMAArrayDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testInteger():Void {
		function verify(result:Dynamic) {
			var expected = 7;
			Assert.isTrue(Reflect.hasField(result, "myInt"));
			Assert.equals(expected, result.myInt);
		}

		var bytes = new AMF0IntegerDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testLongString():Void {
		var longStringData = new LongString();
		var expected = longStringData.readUTFBytes(longStringData.bytesAvailable);
		function verify(result:Dynamic) {
			Assert.isTrue(Reflect.hasField(result, "myLongString"));
			Assert.equals(expected, result.myLongString);
		}

		var bytes = new AMF0LongStringDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testNull():Void {
		function verify(result:Dynamic) {
			Assert.isTrue(Reflect.hasField(result, "myNull"));
			Assert.isNull(result.myNull);
		}

		var bytes = new AMF0NullDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testNumber():Void {
		function verify(result:Dynamic) {
			var expected = 3.141592653589793;
			Assert.isTrue(Reflect.hasField(result, "myFloat"));
			Assert.equals(expected, result.myFloat);
		}

		var bytes = new AMF0NumberDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testObject():Void {
		function verify(result:Dynamic) {
			var expected = {p3: "hallo", p4: 8};
			Assert.isTrue(Reflect.hasField(result, "myObject2"));
			var actual = result.myObject2;
			Assert.notNull(actual);
			Assert.equals(Reflect.fields(expected).length, Reflect.fields(actual).length);
			Assert.equals(expected.p3, actual.p3);
			Assert.equals(expected.p4, actual.p4);
		}

		var bytes = new AMF0ObjectDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testString():Void {
		function verify(result:Dynamic) {
			var expected = "ralle";
			Assert.isTrue(Reflect.hasField(result, "myString"));
			Assert.equals(expected, result.myString);
		}

		var bytes = new AMF0StringDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}

	public function testUndefined():Void {
		function verify(result:Dynamic) {
			Assert.isTrue(Reflect.hasField(result, "myUndefined"));
			Assert.isNull(result.myUndefined);
		}

		var bytes = new AMF0UndefinedDemo();
		bytes.endian = Endian.BIG_ENDIAN;
		var result = reader.read(bytes);
		verify(result);

		var resultBytes = writer.write(reader.name, result, AMF0);
		resultBytes.position = 0;
		var result2 = reader.read(resultBytes);
		verify(result2);
	}
}
