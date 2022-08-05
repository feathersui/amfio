/*
	Feathers UI AMF I/O
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

import openfl.net.ObjectEncoding;
import openfl.utils.ByteArray;

class SolWriter {
	private static final SOL_SIGNATURE = "TCSO";
	private static final TAG_TYPE_LSO:UInt = 2;

	public function new() {}

	public function write(name:String, output:Dynamic, objectEncoding:ObjectEncoding = AMF3):ByteArray {
		var result = new ByteArray();
		result.endian = BIG_ENDIAN;
		result.objectEncoding = objectEncoding;

		var body = writeBody(name, output, objectEncoding);
		var tagTypeAndContentLength = (TAG_TYPE_LSO << 6) + 0x3f;
		result.writeShort(tagTypeAndContentLength);
		var contentLength = body.length;
		result.writeInt(contentLength);

		result.writeBytes(body);

		return result;
	}

	private function writeBody(name:String, output:Dynamic, objectEncoding:ObjectEncoding):ByteArray {
		var result:ByteArray = new ByteArray();
		result.endian = BIG_ENDIAN;
		result.objectEncoding = objectEncoding;

		result.writeUTFBytes(SOL_SIGNATURE);

		// Unknown, 6 bytes long 0x00 0x04 0x00 0x00 0x00 0x00 0x00
		result.writeByte(0x00);
		result.writeByte(0x04);
		result.writeByte(0x00);
		result.writeByte(0x00);
		result.writeByte(0x00);
		result.writeByte(0x00);

		result.writeUTF(name);

		result.writeUnsignedInt(objectEncoding == AMF3 ? 3 : 0);

		var writer = new AMFWriter(result);
		writer.objectEncoding = objectEncoding;
		for (varName in Reflect.fields(output)) {
			var varValue = Reflect.field(output, varName);
			if (objectEncoding == AMF3) {
				writer.writeDynamicProperty(varName, varValue);
			} else if (objectEncoding == AMF0) {
				result.writeUTF(varName);
				writer.writeAmf0Object(varValue);
			}
			result.writeByte(0);
		}
		return result;
	}
}
