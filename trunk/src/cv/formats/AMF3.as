/* 
	AMF3 parsers, reads AMF3 encoded data
    Copyright (C) 2009  Gabriel Mariani

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package cv.formats {
	
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.xml.XMLDocument;
	
	public class AMF3 {
		
		private var objCache:Object = new Object();
		private var strCache:Object = new Object();
		private var defCache:Object = new Object();
		
		public function AMF3():void {
			clearCache();
		}
		
		public function clearCache():void {
			objCache = new Object();
			strCache = new Object();
		}
		
		public function readData(by:FileStream):*	{
			/*
			// While this is possible, it's very buggy and throws range errors on objects
			var val:*;
			try {
				val = by.readObject();
			} catch(e:RangeError) {
				trace(e);
			}
			return val;
			*/
			
			var type:int = by.readByte();
			switch(type) {
				case 0x00 : return undefined;  //undefined
				case 0x01 : return null;  //null
				case 0x02 : return false; //boolean false
				case 0x03 : return true;  //boolean true
				case 0x04 : return readInt(by);
				case 0x05 : return by.readDouble();
				case 0x06 : return readString(by);
				case 0x07 : return readXMLDoc(by);
				case 0x08 : return readDate(by);
				case 0x09 : return readArray(by);
				case 0x0A : return readObject(by); // Object
				case 0x0B : return readXML(by); // XML
				case 0x0C : return readByteArray(by); // Byte Array
				default: throw Error("AMF3::readData - Error : Undefined AMF3 type encountered '" + type + "'");
			}
		}
		
		public function readByteArray(by:FileStream):ByteArray {
			var handle:int = readInt(by);
			var inline:Boolean = ((handle & 1) != 0 );
			var ba:ByteArray;
			handle = handle >> 1;
			
			if(inline) {
				ba = new ByteArray();
				by.readBytes(ba, 0, handle);
				objCache[handle] = ba;
			} else {
				ba = objCache[handle];
			}
			
			return ba;
		}
		
		public function readInt(by:FileStream):int {
			var valInt:int = by.readByte();
			if(valInt < 128) {
				return valInt;
			} else {
				valInt = (valInt & 0x7f) << 7;
				var tmpInt:int = by.readByte();
				if(tmpInt < 128) {
					return valInt | tmpInt;
				} else {
					valInt = (valInt | (tmpInt & 0x7f)) << 7;
					tmpInt = by.readByte();
					if(tmpInt < 128) {
						return valInt | tmpInt;
					} else {
						valInt = (valInt | (tmpInt & 0x7f)) << 8;
						tmpInt = by.readByte();
						valInt |= tmpInt;
						
						// Check if the integer should be negative
						if ((valInt & 0x10000000) != 0) {
							// and extend the sign bit
							valInt |= 0xe0000000;
						}
						return valInt;
					}
				}
			}
		}
		
		public function readString(by:FileStream):String {
			var handle:int = readInt(by);
			var str:String = "";
			
			// Is this referring to a previous string?
			if ((handle & 0x01) == 0) {
				handle = handle >> 1;
				if (handle >= strCache.length) {
					throw Error("AMF3::readString - Error : Undefined string reference '" + handle + "'");
					return null;
				}
				return strCache[handle];
			}
			
			var len:int = handle >> 1; 
			if (len > 0) {
				str = by.readUTFBytes(len);
				strCache[handle] = str;
			}
			
			return str;
		}
		
		public function readObject(by:FileStream):Object {
			var handle:int = readInt(by);
			var inline:Boolean = ((handle & 1) != 0 ); handle = handle >> 1;
			var classDefinition:Object;
			var classMemberDefinitions:Array;
			
			if(inline) {
				//an inline object
				var inlineClassDef:Boolean = ((handle & 1) != 0 );
				handle = handle >> 1;
				
				if(inlineClassDef) {
					//inline class-def
					var typeIdentifier:String = readString(by);
					var typedObject:Boolean = (typeIdentifier) && typeIdentifier != "";
					
					//flags that identify the way the object is serialized/deserialized
					var externalizable:Boolean = ((handle & 1) != 0 );
					handle = handle >> 1;
					
					var isDynamic:Boolean = ((handle & 1) != 0 );
					handle = handle >> 1;
					
					var classMemberCount:int = handle;
					classMemberDefinitions = new Array();
					for(var i:int = 0; i < classMemberCount; i++) {
						classMemberDefinitions.push(readString(by));
					}
					
					classDefinition = {"type" : typeIdentifier, "members" : classMemberDefinitions, "externalizable" : externalizable, "dynamic" : isDynamic};
					defCache[handle] = classDefinition;
				} else {
					//a reference to a previously passed class-def
					classDefinition = defCache[handle];
				}
			} else {
				//an object reference
				return objCache[handle];
			}		
			
			
			var type:String = classDefinition['type'];
			var obj:Object = mapClass(type);
			
			var isObject:Boolean = true;
			if(obj == null){ 
				obj = new Object();
				isObject = false;
			}
			
			//Add to references as circular references may search for this object
			objCache[handle] = obj;
			
			if(classDefinition['externalizable']) {
				if(type == 'flex.messaging.io.ArrayCollection') {
					obj = readData(by);
				} else if(type == 'flex.messaging.io.ObjectProxy') {
					obj = readData(by);
				} else {
					throw Error("AMF3::readObject - Error : Unable to read externalizable data type '" + type + "'");
				}
			} else {
				var members:Array = classDefinition['members'] as Array;
				var memberCount:int = members.length;
				var key:String;
				
				for(var j:int = 0; j < memberCount; j++) {
					var val:* = readData(by);
					key = members[j];
					obj[key] = val;
				}
				
				if(classDefinition['dynamic']/* && obj is ASObject*/) {
					key = readString(by);
					while( key != "" ) {
						var value:* = readData(by);
						obj[key] = value;
						key = readString(by);
					}
				}
				
				if(type != '' && !isObject) {
					obj['_explicitType'] = type;
				}
			}
			
			/*if(isObject && method_exists(obj, 'init')) {
				obj.init();
			}*/
			
			return obj;
		}
		
		private function mapClass(typeIdentifier:String):* {
			//Check out if class exists
			if(typeIdentifier == "") {
				return null;
			}
			
			if(typeIdentifier == "flex.messaging.messages.CommandMessage") {
				//return new CommandMessage();
			}
			
			if(typeIdentifier == "flex.messaging.messages.RemotingMessage") {
				//return new RemotingMessage();
			}
			
			// Can't access Flex only classes
			return null;
			
			/*
			//AMFPHP specific stuff
			
			$clazz = null;
			$mappedClass = str_replace('.', '/', typeIdentifier);
			if(isset($GLOBALS['amfphp']['incomingClassMappings'][typeIdentifier])) {
				$mappedClass = str_replace('.', '/', $GLOBALS['amfphp']['incomingClassMappings'][typeIdentifier]);
			}
			
			var isInclude:Boolean = false;
			
			if(file_exists($GLOBALS['amfphp']['customMappingsPath'] . $mappedClass . '.php')) {
				isInclude = $GLOBALS['amfphp']['customMappingsPath'] . $mappedClass . '.php';
			} else if(file_exists($GLOBALS['amfphp']['customMappingsPath'] . $mappedClass . '.class.php')) {
				isInclude = $GLOBALS['amfphp']['customMappingsPath'] . $mappedClass . '.class.php';
			}
			
			if(isInclude !== FALSE) {
				include_once(isInclude);
				$lastPlace = strrpos('/' . $mappedClass, '/');
				$classname = substr($mappedClass, $lastPlace);
				if(class_exists($classname)) {
					$clazz = new $classname;
				}
			}
			
			return $clazz; // return the object
			*/
		}
		
		public function readDate(by:FileStream):Date {
			var handle:int = by.readByte();
			
			// Is this referring to a previous date?
			if ((handle & 0x01) == 0) {
	            handle = handle >> 1;
	            if (handle >= objCache.length) {
					throw Error("AMF3::readDate - Error : Undefined date reference '" + handle + "'");
	                return null;
	            }
	            return objCache[handle];
	        }
			
			var varVal:Date = new Date();
			varVal.setTime(by.readDouble());
			objCache[handle] = varVal;
			
			return varVal;
		}
		
		public function readXMLDoc(by:FileStream):XMLDocument {
			var handle:int = readInt(by);
			var xmldoc:XMLDocument = new XMLDocument();
			var inline:Boolean = ((handle & 1)  != 0 );
			handle = handle >> 1;
			
			if(inline) {
				xmldoc = new XMLDocument(by.readUTFBytes(handle));
				objCache[handle] = xmldoc;
			} else {
				xmldoc = objCache[handle];
			}
			
			return xmldoc;
		}
		
		public function readXML(by:FileStream):XML {
			var handle:int = readInt(by);
			var xml:XML = new XML();
			var inline:Boolean = ((handle & 1)  != 0 );
			handle = handle >> 1;
			
			if(inline) {
				xml = new XML(by.readUTFBytes(handle));
				objCache[handle] = xml;
			} else {
				xml = objCache[handle];
			}
			
			return xml;
		}
		
		public function readArray(by:FileStream):Array {
			var handle:int = readInt(by);
			var inline:Boolean = ((handle & 1)  != 0 );
			handle = handle >> 1;
			
			if (inline) {
				var arr:Array = new Array();
				var strKey:String = readString(by);
				
				while(strKey != "") {
					arr[strKey] = readData(by);
					strKey = readString(by);
				}
				
				for(var i:int = 0; i < handle; i++) {
					arr[i] = readData(by);
				}
				
				objCache[handle] = arr;
				return arr;
			} else {
				// return previously reference array
				return objCache[handle];
			}
		}
	}
	
}