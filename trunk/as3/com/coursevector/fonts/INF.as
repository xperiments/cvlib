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
*/

/*
uint8 - BYTE - readUnsignedByte
int8 - CHAR - readByte
uint16 - USHORT - readUnsignedShort
int16 - SHORT - readShort
uint32 - ULONG - readUnsignedInt
int32 - LONG - readInt

*/

// Illegal characters for file names: \/:*?"<>|
 
package com.coursevector.fonts {
	
	import flash.errors.EOFError;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class INF {
		
		private var objData:Object = new Object();
		private var baData:ByteArray;
		private static var _isValid:Boolean = false;
		
		public function INF(sourceFile:File):void {
			if(!sourceFile.exists) return;
			loadMetric(sourceFile);
		}
		
		public function loadMetric(sourceFile:File):void {
			baData = new ByteArray();
			var fs:FileStream = new FileStream();
			
			fs.open(sourceFile, FileMode.READ);
			
			var str:String = fs.readUTFBytes(fs.bytesAvailable);
			var arr:Array = str.split("\r");
			arr.pop();
			
			objData.name = INF.getName(arr);
			fs.close();
		}
		
		// is this a Type1 font metric?
		public static function isValid(sourceFile:File):Boolean {
			var ext:String = sourceFile.extension.toLowerCase();
			
			if(ext) {
				if (ext == "inf") {
					var fs:FileStream = new FileStream();
					fs.open(sourceFile, FileMode.READ);
					
					var str:String = fs.readUTFBytes(fs.bytesAvailable);
					var arr:Array = str.split("\r");
					arr.pop();
					
					INF.getName(arr);
					
					fs.close();
					return INF._isValid;
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
		
		private static function findIndex(arr:Array, str:String):uint {
			var l:uint = arr.length;
			for (var i:uint = 0; i < l; i++) {
				if (arr[i].indexOf(str) != -1) return i;
			}
			return 0;
		}
		
		private static function getName(arr:Array):String {
			var i:uint = INF.findIndex(arr, "FontName");
			var str:String = arr[i];
			INF._isValid = false;
			
			if (str) {
				str = str.split("FontName ")[1];
				str = str.substr(1);
				str = str.substr(0, -1);
				if (str.length > 0) INF._isValid = true;
			} else {
				str = "";
			}
			return str;
		}
	}
}