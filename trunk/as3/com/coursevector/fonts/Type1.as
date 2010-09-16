/**
 * 
 * Read Type 1 Fonts (Printer Font Binary)
 * 
 * ** Requires Adobe AIR **
 * 
 * .pfa (Printer Font Ascii) is a Type 1 font
 * .pfb (Printer Font Binary) files contain a binary compressed version of .pfa for use on a user's Windows system.
 * .pfm (Printer Font Metrics) files contain font metric information used by applications for laying out lines of 
 * text in a document. They also specify the Windows font menu name, kerning pair data, and a variety of other font-level information.
 * 
 * @author Gabriel Mariani
 * @version 0.1
 * @internal http://partners.adobe.com/public/developer/en/font/T1_SPEC.PDF
*/

/*
uint8 - BYTE - readUnsignedByte
int8 - CHAR - readByte
uint16 - USHORT - readUnsignedShort
int16 - SHORT - readShort
uint32 - ULONG - readUnsignedInt
int32 - LONG - readInt

*/
 
package com.coursevector.fonts {
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	public class Type1 {
		
		private var objData:Object = new Object();
		private var baData:ByteArray;
		private static var _isValid:Boolean = false;
		
		public function Type1(sourceFile:File):void {
			if(!sourceFile.exists) return;
			loadFont(sourceFile);
		}
		
		public function loadFont(sourceFile:File):void {
			baData = new ByteArray();
			var fs:FileStream = new FileStream();
			
			fs.open(sourceFile, FileMode.READ);
			objData.header = getHeader(fs);
			objData.fontInfo = getFontInfo(fs);
			objData.name = objData.header.FontName || objData.fontInfo.FullName || objData.fontInfo.FontName || "";
			fs.close();
		}
		
		// Is this a type1 font?
		public static function isValid(sourceFile:File):Boolean {
			var ext:String = sourceFile.extension.toLowerCase();
			if(ext) {
				if (ext == "pfa" || ext == "pfb") {
					var fs:FileStream = new FileStream();
					fs.open(sourceFile, FileMode.READ);
					fs.position = 6;
					var char1:String = fs.readUTFBytes(1);
					var char2:String = fs.readUTFBytes(1);
					fs.close();
					return (char1 == "%" && char2 == "!");
				}
			}
			return false;
		}
		
		public function get data():Object {
			return objData;
		}
		
		public function get fontName():String {
			return objData.name;
		}
		
		private function getName(d:Dictionary, d2:Dictionary):String {
			var str:String = d['FontName'];
			if(!str) {
				str = d2['FullName'];
				if(!str) {
					str = d2['FontName'];
					if(!str) str = "";
				}
			}
			return str;
		}
		
		private function getDate(d:Dictionary):String {
			var str:String = d['CreationDate'];
			if(str) {
				str = str.substr(1);
			} else {
				str = "";
			}
			return str;
		}
		
		private function getVM(d:Dictionary):Array {
			var arr:Array = new Array();
			var str:String = d['VMusage'];
			if(str) {
				str = str.substr(1);
				arr = str.split(" ");
			}
			return arr;
		}
		
		private function getCopy(d:Dictionary, d2:Dictionary):String {
			var str:String = d['Copyright'];
			if(!str) {
				str = d2['Notice'];
				if(!str) str = "";
			}
			return str;
		}
		
		private function getFontInfo(fs:FileStream):Object {
			var obj:Object = {};
			var startPosition:uint;
			var endPosition:uint;
			var str:String;
			var byte:String;
			
			for (var i:uint = 0; i < fs.bytesAvailable; i++) {
				byte = fs.readUTFBytes(1);
				
				// Char Code 13 = \r CR Line Break
				// Char Code 10 = LF Line Break
				
				if (!startPosition && !endPosition && (byte == "e" || byte == "c")) {
					//currentdict end, end readonly def
					byte = fs.readUTFBytes(16);
					
					// Finished reading metadata
					if(byte == "urrentfile eexec") break;
					
					fs.position -= 16;
				}
				
				if (!startPosition && byte == "/") {
					startPosition = fs.position - 1;
				} else if (startPosition && !endPosition && (byte.charCodeAt() == 13 || byte.charCodeAt() == 10)) {
					endPosition = fs.position - 1;
				} 
				
				if (startPosition && endPosition) {
					fs.position = startPosition;
					str = fs.readUTFBytes(endPosition - startPosition);
					fs.position++;
					startPosition = undefined;
					endPosition = undefined;
					
					//   /(\/)([a-zA-Z]*)(.*)/g   g1 is slash g2 is var name g3 is full var value
					var regex:RegExp = /(\/)([a-zA-Z]*)(.*)/g
					var o:Object = regex.exec(str);
					if(o) {
						// trim any ending spaces, remove 'readonly' 'readonly def' and '(', ')'
						o[3] = o[3].replace(/\s\/|\s*\((?=[A-Z\d])|\)?\s?readonly\s*|\s+$|\s?def/g, '');
						
						// trim spaces
						o[3] = o[3].replace(/^\s+|\s+$/g, '');
						obj[o[2]] = o[3];
					}
				}
			}
			
			return obj;
		}
		
		private function getHeader(fs:FileStream):Object {
			var obj:Object = {};
			var dictHeader:Dictionary = new Dictionary();
			var startPosition:uint;
			var endPosition:uint;
			var str:String;
			var byte:String;
			
			for (var i:uint = 0; i < fs.bytesAvailable; i++) {
				byte = fs.readUTFBytes(1);
				// Char Code 13 = \r CR Line Break
				// Char Code 10 = LF Line Break
				
				// The position must be greater than 5 since ANSI PFB files seems to have the first 5 bits taken up with nonsense
				if (!startPosition && byte == "%" && fs.position > 5) {
					startPosition = fs.position - 1;
				} else if (startPosition && !endPosition && (byte.charCodeAt() == 13 || byte.charCodeAt() == 10)) {
					endPosition = fs.position - 1;
				} else if (!startPosition && !endPosition && (byte.charCodeAt() == 13 || byte.charCodeAt() == 10)) {
					break;
				}
				
				if (startPosition && endPosition) {
					fs.position = startPosition;
					str = fs.readUTFBytes(endPosition - startPosition);
					
					fs.position++;
					startPosition = undefined;
					endPosition = undefined;
					
					if (str.indexOf("%") == -1) {
						break;
					}
					
					var regex:RegExp = /%!?%?\s?(.*):\s(.*)/gi
					var o:Object = regex.exec(str);
					if(o) {
						if(String(o[1]).indexOf("PS-") > -1) {
							var a:Array = o[2].split(" ");
							obj['FontName'] = a[0];
							obj['FontVersion'] = a[1];
						} else {
							obj[o[1]] = o[2];
						}
					}
				}
			}
			
			return obj;
		}
	}
}