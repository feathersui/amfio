/*
	AMF I/O
	Copyright 2022 Bowler Hat LLC

	Minerva
	Copyright 2020 Gabriel Mariani

	Permission to use, copy, modify, and/or distribute this software for
	any purpose with or without fee is hereby granted, provided that the
	above copyright notice and this permission notice appear in all copies.

	THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
	WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
	WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR
	BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES
	OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
	WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
	ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
	SOFTWARE.
 */

package feathers.amfio.sol;

import openfl.errors.Error;
import openfl.utils.ByteArray;

/**
	Read _.sol_ file data from a `ByteArray`.

	```haxe
	var reader = new SolReader();
	var data = reader.read(byteArray);
	```
**/
class SolReader {
	private static final SOL_SIGNATURE = "TCSO";
	private static final TAG_TYPE_LSO:UInt = 2;

	/**
		Constructor.
	**/
	public function new() {}

	/**
		The name read from the _.sol_ file.
	**/
	public var name(default, null):String;

	/**
		The data read from the _.sol_ file.
	**/
	public var data(default, null):Dynamic;

	/**
		Reads the _.sol_ data encoded in a `ByteArray`.
	**/
	public function read(input:ByteArray):Dynamic {
		input.position = 0;

		var header = readSolHeader(input);
		name = header.name;

		data = readSolData(header, input);
		return data;
	}

	private function readSolHeader(data:ByteArray):SolHeader {
		var tagTypeAndContentLength = data.readUnsignedShort();
		var contentLength = tagTypeAndContentLength & 0x3f;
		if (contentLength == 0x3f) {
			contentLength = data.readInt();
		}
		var tagType = tagTypeAndContentLength >> 6;
		if (tagType != TAG_TYPE_LSO) {
			throw new Error('Failed to read Sol data. Expected tag type: $TAG_TYPE_LSO');
		}

		var signature = data.readUTFBytes(4);
		if (signature != SOL_SIGNATURE) {
			throw new Error('Failed to read Sol data. Expected signature: "$SOL_SIGNATURE"');
		}

		// Unknown, 6 bytes long 0x00 0x04 0x00 0x00 0x00 0x00 0x00
		data.readUTFBytes(6);

		var name = data.readUTF();

		var amfVersion = data.readUnsignedInt();

		var header = new SolHeader();
		header.type = tagType;
		header.contentLength = contentLength;
		header.name = name;
		header.amfVersion = amfVersion;
		return header;
	}

	private function readSolData(header:SolHeader, data:ByteArray):Dynamic {
		data.objectEncoding = header.amfVersion == 3 ? AMF3 : AMF0;

		var result:Dynamic = {};
		var reader = new AMFReader(data);
		reader.objectEncoding = data.objectEncoding;
		while (data.bytesAvailable > 0 && data.position < header.contentLength) {
			var varName = "";
			var varValue:Dynamic = null;
			if (data.objectEncoding == AMF3) {
				varName = reader.readAmf3String();
				varValue = reader.readAmf3Object();
			} else if (data.objectEncoding == AMF0) {
				varName = data.readUTF();
				varValue = reader.readAmf0Object();
			}
			var endingByte = data.readUnsignedByte();
			if (endingByte != 0) {
				throw new Error('Failed to read Sol data. Expected 0 byte after field: "$varName"');
			}
			Reflect.setField(result, varName, varValue);
		}
		return result;
	}
}

private class SolHeader {
	public function new() {}

	public var type:Int;
	public var contentLength:UInt;
	public var name:String;
	public var amfVersion:Int;
}
