# AMF I/O

AMF binary data format readers and writers for for [OpenFL](https://openfl.org/) and [Feathers UI](https://feathersui.com/), written in [Haxe](https://haxe.org/).

Contains the following types for AMF input and output.

- `AMFReader`: Reads AMF0 or AMF3 objects from a `ByteArray`
- `AMFWriter`: Writes AMF0 or AMF3 objects to a `ByteArray`
- `SolReader`: Reads Flash Local Shared Object data from a `ByteArray`
- `SolWriter`: Writes Flash Local Shared Object data to a `ByteArray`
- `AMFEcmaArray`: An associative array that may contain both integer and string keys. Like a combination of the `Array` type and an anonymous structure.
- `AMFDictionary`: Similar to the `Map` type, but keys are not restricted to a single type.

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
