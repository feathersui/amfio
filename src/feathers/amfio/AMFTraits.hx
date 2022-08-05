/*
	Licensed to the Apache Software Foundation (ASF) under one or more
	contributor license agreements.  See the NOTICE file distributed with
	this work for additional information regarding copyright ownership.
	The ASF licenses this file to You under the Apache License, Version 2.0
	(the "License"); you may not use this file except in compliance with
	the License.  You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.

	AMF JavaScript library by Emil Malinov https://github.com/emilkm/amfjs
 */

package feathers.amfio;

import haxe.Constraints.Function;

class AMFTraits {
	public static function createInstanceVariableGetterSetter(reflectionFunction:Function, type:String):Dynamic {
		var ret:Dynamic = {
			setValue: function(inst:Dynamic, value:Dynamic):Void {
				reflectionFunction(inst, value);
			}
		};

		if (type == "*") {
			ret.getValue = function(inst:Dynamic):Dynamic {
				return reflectionFunction(inst, reflectionFunction);
			}
		} else {
			ret.getValue = function(inst:Dynamic):Dynamic {
				return reflectionFunction(inst);
			}
		}
		return ret;
	}

	public static function createInstanceAccessorGetterSetter(fieldName:String):Dynamic {
		return {
			getValue: function(inst:Dynamic):Dynamic {
				return Reflect.getProperty(inst, fieldName);
			},
			setValue: function(inst:Dynamic, value:Dynamic):Dynamic {
				Reflect.setProperty(inst, fieldName, value);
				return Reflect.getProperty(inst, fieldName);
			}
		};
	}

	public static function markTransient(fieldName:String, traits:AMFTraits):Void {
		if (traits.transients == null) {
			traits.transients = {};
		}
		Reflect.setField(traits.transients, fieldName, true);
	}

	private static var _emtpy_object:AMFTraits;

	public static function getClassTraits(fields:Array<String>, qName:String):AMFTraits {
		var traits:AMFTraits = new AMFTraits();
		traits.qName = '[Class] ' + qName;
		traits.isDynamic = true;
		traits.externalizable = false;
		traits.props = fields;

		return traits;
	}

	public static function getBaseObjectTraits():AMFTraits {
		if (_emtpy_object != null)
			return _emtpy_object;
		var traits:AMFTraits = _emtpy_object = new AMFTraits();
		traits.qName = 'Object';
		traits.externalizable = false;
		traits.isDynamic = true;
		return traits;
	}

	public static function getDynObjectTraits(fields:Array<String>):AMFTraits {
		var traits:AMFTraits;
		traits = new AMFTraits();
		traits.qName = 'Object';
		traits.externalizable = false;
		traits.isDynamic = true;
		traits.props = fields;
		return traits;
	}

	public function new() {}

	public var alias:String = "";
	public var qName:String;
	public var externalizable:Bool;
	public var isDynamic:Bool;
	public var count:UInt = 0;
	public var props:Array<String> = [];
	public var nullValues:Any = {};

	public var getterSetters:Any = {};
	public var transients:Any;

	public function hasProp(prop:String):Bool {
		return props.indexOf(prop) != -1;
	}

	public function isTransient(prop:String):Bool {
		return transients != null && Reflect.hasField(transients, prop);
	}

	public function toString():String {
		#if debug
		return 'Traits for \'' + qName + '\'\n' + 'alias: \'' + alias + '\'\n' + 'externalizable:' + (externalizable == true) + '\n' + 'isDynamic:'
			+ (isDynamic == true) + '\n' + 'count:' + count + '\n' + 'props:\n\t' + props.join('\n\t');
		#else
		return 'Traits';
		#end
	}
}
