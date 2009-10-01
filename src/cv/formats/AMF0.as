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
	import flash.xml.XMLDocument;
	import flash.net.registerClassAlias;
	//import com.coursevector.formats.AMF3;
	
	public class AMF0 {
		
		private var objCache:Array = new Array();
		//private var amf3:AMF3;
		
		public function AMF0():void {
			clearCache();
			//amf3 = new AMF3();
		}
		
		public function clearCache():void {
			objCache = new Array();
		}
		
		public function readData(by:FileStream):*	{
			var type:int = by.readByte();
			switch(type) {
				case 0x00 : return readNumber(by); // Number
				case 0x01 : return readBoolean(by); // Boolean
				case 0x02 : return readString(by); // String
				case 0x03 : return readObject(by); // Object
				case 0x04 : return null; // MovieClip, not used
				case 0x05 : return null; // Null
				case 0x06 : return readUndefined(by); // Undefined
				case 0x07 : return readReference(by); // Reference
				case 0x08 : return readMixedArray(by); // ECMA Array (associative)
				//case 0x09 : // Object End Marker
				case 0x0A : return readArray(by); // Strict Array
				case 0x0B : return readDate(by); // Date
				case 0x0C : return readLongString(by); // Long String, string.length > 2^16
				case 0x0D : return null; // Unsupported
				case 0x0E : return null;// Recordset, not used
				case 0x0F : return readXML(by); // XML
				case 0x10 : return readCustomClass(by); // Typed Object (Custom Class)
				case 0x11 : return null;// amf3.readData(by); // AMF3 Switch
				/*
				With the introduction of AMF 3 in Flash Player 9 to support ActionScript 3.0 and the 
				new AVM+, the AMF 0 format was extended to allow an AMF 0 encoding context to be 
				switched to AMF 3. To achieve this, a new type marker was added to AMF 0, the 
				avmplus-object-marker. The presence of this marker signifies that the following Object is 
				formatted in AMF 3 (See [AMF3]).
				*/
				default: throw Error("AMF0::readData - Error : Undefined AMF0 type encountered '" + type + "'");
			}
		}
		
		public function readNumber(by:FileStream):Number {
			var val:Number = by.readDouble();
			by.readByte(); // Ending byte
			return val;
		}
		
		public function readBoolean(by:FileStream):Boolean {
			var val:Boolean = by.readBoolean();
			by.readByte(); // Ending byte
			return val;
		}
		
		public function readString(by:FileStream):String {
			var val:String = by.readUTF();
			by.readByte(); // Ending byte
			return val;
		}
		
		/**
		 * readObject reads the name/value properties of the amf message
		 * 
		 * @return Object The object data
		 */
		public function readObject(by:FileStream):Object {
			var obj:Object = new Object();
			var varName:String = by.readUTF();
			var type:int = by.readByte();
			
			while(type != 0x09) {
				// Since readData checks type again
				by.position--;
				
				obj[varName] = readData(by);
				
				// No Ending Byte in Objects
				if (type != 0x04 && type != 0x05 && type != 0x0D && type != 0x0E && type != 0x11) by.position--;
				
				varName = by.readUTF();
				type = by.readByte();
			}
			
			objCache.push(obj);
			by.readByte(); // Ending byte
			return obj;
		}
		
		public function readUndefined(by:FileStream):* {
			by.readByte(); // Ending byte
			return null;
		}
		
		/**
		 * readReference replaces the old readFlushedSO. It treats where there
		 * are references to other objects. Currently it does not resolve the
		 * object as this would involve a serious amount of overhead, unless
		 * you have a genius idea
		 * 
		 * @return Object 
		 */
		public function readReference(by:FileStream):Object {
			var ref:uint = by.readUnsignedShort();
			trace("readReference: " + ref);
			by.readByte(); // Ending byte
			
			return { };// objCache[ref];
		}
		
		/**
		 * readMixedObject reads the name/value properties of the amf message and converts
		 * numeric looking keys to numeric keys
		 * 
		 * @return Array The array data
		 */
		public function readMixedArray(by:FileStream):Array {
			var arr:Array = new Array();
			
			var l:uint = by.readUnsignedInt();
			for(var i:int = 0; i < l; i++) {
				var key:String = by.readUTF();
				var value:* = readData(by);
				
				// No Ending Byte in Arrays
				by.position--;
				
				arr[key] = value;
			}
			
			objCache.push(arr);
			
			// End tag 00 00 09
			by.position += 3;
			by.readByte(); // Ending byte
			return arr;
		}
		
		/**
		 * readArray turns an all numeric keyed actionscript array
		 * 
		 * @return Array
		 */
		public function readArray(by:FileStream):Array {
			var arr:Array = new Array();
			var l:uint = by.readUnsignedInt();
			for (var i:int = 0; i < l; i++) {
				arr.push(readData(by));
			}
			
			objCache.push(arr);
			return arr;
		}
		
		/**
		 * readDate reads a date from the amf message
		 * 
		 * @return Date
		 */
		public function readDate(by:FileStream):Date {
			var ms:Number = by.readDouble();
			var timezone:int = by.readShort(); // reserved, not supported. should be set to 0x0000
			/*var timezone:int = $this->readInt();
			if (timezone > 720) {
				timezone = -(65536 - timezone);
			}
			timezone *= -60;*/
			
			var varVal:Date = new Date();
			varVal.setTime(ms);
			
			by.readByte(); // Ending byte
			return varVal;
		}
		
		public function readLongString(by:FileStream):String {
			var val:String = by.readUTFBytes(by.readUnsignedInt());
			by.readByte(); // Ending byte
			return val;
		}
		
		public function readXML(by:FileStream):XML {
			var strXML:String = by.readUTFBytes(by.readUnsignedInt());
			var val:XML = new XML(strXML);
			by.readByte(); // Ending byte
			return val;
		}
		
		/**
		 * readCustomClass reads the amf content associated with a class instance which was registered
		 * with Object.registerClass. 
		 * 
		 * @return object The class
		 */
		public function readCustomClass(by:FileStream):* {
			var classID:String = by.readUTF();
			//trace("classID", classID);
			
			var obj:Object = readObject(by) as Object;
			obj._____$$$$$classID = classID;
			//registerClassAlias(classID, obj);
			objCache.push(obj);
			return obj;
		}
	}
}