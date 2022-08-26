/*
	AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import utest.Assert;
import utest.Test;

class AMFEcmaArrayTest extends Test {
	public function new() {
		super();
	}

	public function testConstructor():Void {
		var array = new AMFEcmaArray<Dynamic>();
		Assert.equals(0, array.length);
	}

	public function testAssignEmptyArray():Void {
		var array:AMFEcmaArray<Dynamic> = [];
		Assert.equals(0, array.length);
	}

	public function testAssignIntArray():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		Assert.equals(5, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(4, array[2]);
		Assert.equals(1, array[3]);
		Assert.equals(5, array[4]);

		#if (haxe_ver > 4.1)
		Assert.isTrue(array.contains(3));
		Assert.isTrue(array.contains(1));
		Assert.isTrue(array.contains(4));
		Assert.isTrue(array.contains(5));
		Assert.isFalse(array.contains(8));
		#end
		Assert.equals(0, array.indexOf(3));
		Assert.equals(1, array.indexOf(1));
		Assert.equals(2, array.indexOf(4));
		Assert.equals(4, array.indexOf(5));
		Assert.equals(-1, array.indexOf(8));
		Assert.equals(0, array.lastIndexOf(3));
		Assert.equals(3, array.lastIndexOf(1));
		Assert.equals(2, array.lastIndexOf(4));
		Assert.equals(4, array.lastIndexOf(5));
		Assert.equals(-1, array.lastIndexOf(8));
	}

	public function testSetKey():Void {
		var array = new AMFEcmaArray<Dynamic>();
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		Assert.equals(0, array.length);
		Assert.equals(1, array["one"]);
		Assert.equals(2, array["two"]);
		Assert.equals(3, array["three"]);
		#if (haxe_ver > 4.1)
		Assert.isFalse(array.contains(1));
		Assert.isFalse(array.contains(2));
		Assert.isFalse(array.contains(3));
		#end
		Assert.equals(-1, array.indexOf(1));
		Assert.equals(-1, array.indexOf(2));
		Assert.equals(-1, array.indexOf(3));
		Assert.equals(-1, array.lastIndexOf(1));
		Assert.equals(-1, array.lastIndexOf(2));
		Assert.equals(-1, array.lastIndexOf(3));
	}

	public function testSetIndex():Void {
		var array = new AMFEcmaArray<String>();
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;

		var one = "one";
		array[0] = one;
		Assert.equals(1, array.length);
		Assert.equals(one, array[0]);

		var two = "two";
		array[1] = two;
		Assert.equals(2, array.length);
		Assert.equals(one, array[0]);
		Assert.equals(two, array[1]);

		var three = "three";
		array[2] = three;
		Assert.equals(3, array.length);
		Assert.equals(one, array[0]);
		Assert.equals(two, array[1]);
		Assert.equals(three, array[2]);
	}

	public function testPush():Void {
		var array = new AMFEcmaArray<String>();
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;

		var one = "one";
		array.push(one);
		Assert.equals(1, array.length);
		Assert.equals(one, array[0]);

		var two = "two";
		array.push(two);
		Assert.equals(2, array.length);
		Assert.equals(one, array[0]);
		Assert.equals(two, array[1]);

		var three = "three";
		array.push(three);
		Assert.equals(3, array.length);
		Assert.equals(one, array[0]);
		Assert.equals(two, array[1]);
		Assert.equals(three, array[2]);
	}

	public function testUnshift():Void {
		var array = new AMFEcmaArray<String>();
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;

		var one = "one";
		array.unshift(one);
		Assert.equals(1, array.length);
		Assert.equals(one, array[0]);

		var two = "two";
		array.unshift(two);
		Assert.equals(2, array.length);
		Assert.equals(two, array[0]);
		Assert.equals(one, array[1]);
	}

	public function testInsert():Void {
		var array = new AMFEcmaArray<String>();
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;

		var one = "one";
		array.insert(0, one);
		Assert.equals(1, array.length);
		Assert.equals(one, array[0]);

		var two = "two";
		array.insert(0, two);
		Assert.equals(2, array.length);
		Assert.equals(two, array[0]);
		Assert.equals(one, array[1]);

		var three = "three";
		array.insert(1, three);
		Assert.equals(3, array.length);
		Assert.equals(two, array[0]);
		Assert.equals(three, array[1]);
		Assert.equals(one, array[2]);
	}

	public function testPop():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;

		Assert.equals(5, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(4, array[2]);
		Assert.equals(1, array[3]);
		Assert.equals(5, array[4]);

		var result = array.pop();
		Assert.equals(5, result);
		Assert.equals(4, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(4, array[2]);
		Assert.equals(1, array[3]);

		var result = array.pop();
		Assert.equals(1, result);
		Assert.equals(3, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(4, array[2]);

		var result = array.pop();
		Assert.equals(4, result);
		Assert.equals(2, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(1, array[1]);

		var result = array.pop();
		Assert.equals(1, result);
		Assert.equals(1, array.length);
		Assert.equals(3, array[0]);

		var result = array.pop();
		Assert.equals(3, result);
		Assert.equals(0, array.length);

		var result = array.pop();
		Assert.equals(null, result);
		Assert.equals(0, array.length);
	}

	public function testShift():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		Assert.equals(5, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(4, array[2]);
		Assert.equals(1, array[3]);
		Assert.equals(5, array[4]);

		var result = array.shift();
		Assert.equals(3, result);
		Assert.equals(4, array.length);
		Assert.equals(1, array[0]);
		Assert.equals(4, array[1]);
		Assert.equals(1, array[2]);
		Assert.equals(5, array[3]);

		var result = array.shift();
		Assert.equals(1, result);
		Assert.equals(3, array.length);
		Assert.equals(4, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(5, array[2]);

		var result = array.shift();
		Assert.equals(4, result);
		Assert.equals(2, array.length);
		Assert.equals(1, array[0]);
		Assert.equals(5, array[1]);

		var result = array.shift();
		Assert.equals(1, result);
		Assert.equals(1, array.length);
		Assert.equals(5, array[0]);

		var result = array.shift();
		Assert.equals(5, result);
		Assert.equals(0, array.length);

		var result = array.shift();
		Assert.equals(null, result);
		Assert.equals(0, array.length);
	}

	public function testReverse():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		array.reverse();
		Assert.equals(5, array.length);
		Assert.equals(5, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(4, array[2]);
		Assert.equals(1, array[3]);
		Assert.equals(3, array[4]);
		Assert.equals(1, array["one"]);
		Assert.equals(2, array["two"]);
		Assert.equals(3, array["three"]);
	}

	public function testJoin():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var result = array.join(",");
		Assert.equals("3,1,4,1,5", result);
	}

	public function testConcat():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var array2:Array<Int> = [1, 5, 9];
		var result = array.concat(array2);
		Assert.isOfType(result, Array);
		Assert.equals(6, result.length);
		Assert.equals(3, result[0]);
		Assert.equals(1, result[1]);
		Assert.equals(4, result[2]);
		Assert.equals(1, result[3]);
		Assert.equals(5, result[4]);
		Assert.equals(9, result[5]);
	}

	public function testResize():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		array.resize(3);
		Assert.equals(3, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(1, array[1]);
		Assert.equals(4, array[2]);
		Assert.equals(1, array["one"]);
		Assert.equals(2, array["two"]);
		Assert.equals(3, array["three"]);
	}

	public function testCopy():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var result = array.copy();
		Assert.isOfType(result, feathers.amfio.AMFEcmaArray.AMFEcmaArrayData);
		Assert.equals(5, result.length);
		Assert.equals(3, result[0]);
		Assert.equals(1, result[1]);
		Assert.equals(4, result[2]);
		Assert.equals(1, result[3]);
		Assert.equals(5, result[4]);
		Assert.equals(1, result["one"]);
		Assert.equals(2, result["two"]);
		Assert.equals(3, result["three"]);
	}

	public function testSplice():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var result = array.splice(1, 3);
		Assert.isOfType(result, Array);
		Assert.equals(3, result.length);
		Assert.equals(1, result[0]);
		Assert.equals(4, result[1]);
		Assert.equals(1, result[2]);

		Assert.equals(2, array.length);
		Assert.equals(3, array[0]);
		Assert.equals(5, array[1]);
		Assert.equals(1, array["one"]);
		Assert.equals(2, array["two"]);
		Assert.equals(3, array["three"]);
	}

	public function testSlice():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var result = array.slice(1, 3);
		Assert.isOfType(result, Array);
		Assert.equals(2, result.length);
		Assert.equals(1, result[0]);
		Assert.equals(4, result[1]);
	}

	public function testIteratorWithNumbersOnly():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		var expectedArray = [3, 1, 4, 1, 5];
		for (item in array) {
			var expected = expectedArray.shift();
			Assert.equals(expected, item);
		}
	}

	public function testIteratorWithKeysOnly():Void {
		var array = new AMFEcmaArray<Int>();
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		for (item in array) {
			Assert.fail("AMFEcmaArray with keys only should return nothing from iterator");
		}
		Assert.pass();
	}

	public function testIteratorWithNumbersAndKeys():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var expectedArray = [3, 1, 4, 1, 5];
		for (item in array) {
			var expected = expectedArray.shift();
			Assert.equals(expected, item);
		}
	}

	#if (haxe_ver >= 4.1)
	public function testKeyValueIteratorWithNumbersOnly():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		var expectedIndices = [0, 1, 2, 3, 4];
		var expectedValues = [3, 1, 4, 1, 5];
		for (index => value in array) {
			var expectedIndex = expectedIndices.shift();
			var expectedValue = expectedValues.shift();
			Assert.equals(expectedIndex, index);
			Assert.equals(expectedValue, value);
		}
	}

	public function testKeyValueIteratorWithKeysOnly():Void {
		var array = new AMFEcmaArray<Int>();
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var expectedKeys = ["one", "two", "three"];
		var expectedValues = [1, 2, 3];
		for (key => value in array) {
			#if flash
			// string keys are not guaranteed to be in any particular order
			var keyIndex = expectedKeys.indexOf(key);
			Assert.notEquals(-1, keyIndex);
			Assert.equals(expectedValues[keyIndex], value);
			expectedKeys.splice(keyIndex, 1);
			expectedValues.splice(keyIndex, 1);
			#else
			var expectedKey = expectedKeys.shift();
			var expectedValue = expectedValues.shift();
			Assert.equals(expectedKey, key);
			Assert.equals(expectedValue, value);
			#end
		}
	}

	public function testKeyValueIteratorWithNumbersAndKeys():Void {
		var array:AMFEcmaArray<Int> = [3, 1, 4, 1, 5];
		array["one"] = 1;
		array["two"] = 2;
		array["three"] = 3;
		var expectedKeys:Array<Dynamic> = [0, 1, 2, 3, 4, "one", "two", "three"];
		var expectedValues = [3, 1, 4, 1, 5, 1, 2, 3];
		for (key => value in array) {
			#if flash
			if ((key is String)) {
				// string keys are not guaranteed to be in any particular order
				var keyIndex = expectedKeys.indexOf(key);
				Assert.notEquals(-1, keyIndex);
				Assert.equals(expectedValues[keyIndex], value);
				expectedKeys.splice(keyIndex, 1);
				expectedValues.splice(keyIndex, 1);
			} else
			#end
			{
				var expectedKey = expectedKeys.shift();
				var expectedValue = expectedValues.shift();
				Assert.equals(expectedKey, key);
				Assert.equals(expectedValue, value);
			}
		}
	}
	#end
}
