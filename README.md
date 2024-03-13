# AMF I/O

Readers and writers for [OpenFL](https://openfl.org/) targeting the [Action Message Format (AMF)](https://en.wikipedia.org/wiki/Action_Message_Format) and [Flash Local Shared Object (LSO)](https://en.wikipedia.org/wiki/Local_shared_object) binary data formats. Written in [Haxe](https://haxe.org/).

Contains the following types for AMF input and output.

- `AMFReader`: Reads AMF0 or AMF3 objects from a [`ByteArray`](https://api.openfl.org/openfl/utils/ByteArray.html)
- `AMFWriter`: Writes AMF0 or AMF3 objects to a [`ByteArray`](https://api.openfl.org/openfl/utils/ByteArray.html)
- `SolReader`: Reads Flash Local Shared Object data from a [`ByteArray`](https://api.openfl.org/openfl/utils/ByteArray.html)
- `SolWriter`: Writes Flash Local Shared Object data to a [`ByteArray`](https://api.openfl.org/openfl/utils/ByteArray.html)
- `AMFEcmaArray`: An associative array that may contain both integer and string keys. Like a combination of an [array](https://haxe.org/manual/std-Array.html) and an [anonymous structure](https://haxe.org/manual/types-anonymous-structure.html).
- `AMFDictionary`: Similar to the [`Map` type](https://haxe.org/manual/std-Map.html), but keys are not restricted to a single type.

## Minimum Requirements

- Haxe 4.1
- OpenFL 9.2.0

## Installation

Run the following command in a terminal to install [amfio](https://lib.haxe.org/p/amfio) from Haxelib.

```sh
haxelib install amfio
```

## Project Configuration

After installing the library above, add it to your OpenFL _project.xml_ file:

```xml
<haxelib name="amfio" />
```

## Documentation

- [amfio API Reference](https://api.feathersui.com/amfio/)
