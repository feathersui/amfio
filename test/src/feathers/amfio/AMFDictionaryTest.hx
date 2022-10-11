/*
	AMF I/O
	Copyright 2022 Bowler Hat LLC. All Rights Reserved.

	This program is free software. You can redistribute and/or modify it in
	accordance with the terms of the accompanying license agreement.
 */

package feathers.amfio;

import utest.Assert;
import utest.Test;

class AMFDictionaryTest extends Test {
	public function new() {
		super();
	}

	public function testConstructor():Void {
		var dict = new AMFDictionary<Dynamic, Dynamic>();
		Assert.notNull(dict);
	}

	public function testGetAndSet():Void {
		trace("*** START");
		var dict = new AMFDictionary<Dynamic, Dynamic>();
		dict[1] = "number";
		dict["two"] = "string";
		dict[true] = "boolean";
		var obj = {abc: 123, def: 456};
		dict[obj] = "object";
		dict[Test] = "class";
		Assert.equals("number", dict[1]);
		Assert.equals("string", dict["two"]);
		Assert.equals("boolean", dict[true]);
		Assert.equals("object", dict[obj]);
		Assert.equals("class", dict[Test]);
		Assert.isNull(dict["abc123"]);
		trace("*** END");
	}
}
