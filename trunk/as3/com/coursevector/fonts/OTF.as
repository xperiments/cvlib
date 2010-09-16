/**
 * 
 * Read OpenType Fonts
 * 
 * ** Requires Adobe AIR **
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

/* Required Tables under OpenType Spec 1.4
 * 
 * cmap	Character to glyph mapping
 * head	Font header
 * hhea	Horizontal header
 * hmtx	Horizontal metrics
 * maxp	Maximum profile
 * name	Naming table
 * OS/2	OS/2 and Windows specific metrics
 * post	PostScript information
 */
 /* Tables Related to TrueType Outlines
 * 
 * cvt	Control Value Table
 * fpgm	Font program
 * glyf	Glyph data
 * loca	Index to location
 * prep	CVT Program
 */
 /* Tables Related to PostScript Outlines
 * 
 * CFF	PostScript font program (compact font format)
 * VORG	Vertical Origin
 * 
 * 
 * Tables Related to Bitmap Glyphs
 * 
 * EBDT	Embedded bitmap data
 * EBLC	Embedded bitmap location data
 * EBSC	Embedded bitmap scaling data
 */
 /* Advanced Typographic Tables
 * 
 * BASE	Baseline data
 * GDEF	Glyph definition data
 * GPOS	Glyph positioning data
 * GSUB	Glyph substitution data
 * JSTF	Justification data
 */ 
 /* Other OpenType Tables
 * 
 * DSIG	Digital signature
 * gasp	Grid-fitting/Scan-conversion
 * hdmx	Horizontal device metrics
 * kern	Kerning
 * LTSH	Linear threshold data
 * PCLT	PCL 5 data
 * VDMX	Vertical device metrics
 * vhea	Vertical Metrics header
 * vmtx	Vertical Metrics
 * VORG	Vertical Origin
 */
 
 package com.coursevector.fonts {
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.errors.EOFError;
	import flash.utils.*;

	public class OTF extends com.coursevector.fonts.TTF {
		
		public function OTF(sourceFile:File):void {
			super(sourceFile);
		}
		
		override public function loadFont(sourceFile:File):void {
			baData = new ByteArray();
			var arrTables:Array = new Array();
			var fs:FileStream = new FileStream();
			
			fs.open(sourceFile, FileMode.READ);
			fs.readBytes(baData);
			fs.position = 0;
			var strOTTO:String = fs.readUTFBytes(4);
			fs.close();
			
			objData.offSetTable = getOffSetTable(baData);
			
			/* ** Note
			 * Must equal 1.0 for TrueType or OpenType with TrueType data.
			 * If it's OTTO, then it's a OpenType with a CFF table (PostScript data), 
			 * and should be handled with the OTF class.
			 */
			if ((objData.offSetTable.majorVersion != 1 || (objData.offSetTable.majorVersion == 1 && objData.offSetTable.minorVersion != 0)) && strOTTO != "OTTO") {
				return;
			}
			
			// Populate Directory
			for(var i:int = 0; i< objData.offSetTable.numTables; i++) {
				arrTables.push(getDirectoryTable(baData));
			}
			objData.tables = arrTables;
			
			// Populate Tables
			for (var j:int = 0; j < objData.tables.length; j++) {
				if (objData.tables[j].name == "name") {
					var curTable:Object = objData.tables[j];
					baData.position = curTable.offSet;
					curTable.header = getNameTableHeader(baData);
					curTable.platforms = new Object();
					
					for (var k:int = 0; k < curTable.header.count; k++) {
						var offset:uint = curTable.offSet + curTable.header.stringOffset;
						addNameRecords(baData, curTable.platforms, offset);
					}
				}
			}
		}
		
		public static function isValid(sourceFile:File):Boolean {
			var ext:String = sourceFile.extension.toLowerCase();
			if(ext) {
				if (ext == "otf") {
					var fs:FileStream = new FileStream();
					
					fs.open(sourceFile, FileMode.READ);
					var majorVersion:uint = fs.readUnsignedShort();
					var minorVersion:uint = fs.readUnsignedShort();
					fs.position = 0;
					var str:String = fs.readUTFBytes(4);
					fs.close();
					
					if ((majorVersion != 1 || (majorVersion == 1 && minorVersion != 0)) && str != "OTTO") {
						return false;
					} else {
						return true;
					}
				}
			}
			return false;
		}
	}
}