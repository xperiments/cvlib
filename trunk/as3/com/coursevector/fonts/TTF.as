/**
 * 
 * Read TrueType Fonts
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
 
 package com.coursevector.fonts {
	
	import flash.errors.EOFError;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.*;

	public class TTF {
		
		protected var objData:Object = new Object();
		protected var baData:ByteArray;
		
		public function TTF(sourceFile:File):void {
			if(!sourceFile.exists) return;
			loadFont(sourceFile);
		}
		
		public function loadFont(sourceFile:File):void {
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
			if(objData.offSetTable.majorVersion != 1 || objData.offSetTable.minorVersion != 0 || strOTTO == "OTTO") return;
			
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
		
		public function get data():Object {
			return objData;
		}
		
		public function get fontSubFamily():String {
			var l:uint = objData.tables.length;
			for (var j:int = 0; j < l; j++) {
				if (objData.tables[j].name == "name") {
					var curTable:Object;
					var curPlatform:Object;
					var curEncoding:Object;
					var curLanguage:Object;
					var l2:uint;
					var curRecord:Object;
					var k:int;
					var isMac:Boolean = false;
					
					curTable = objData.tables[j];
					if(curTable.platforms.Microsoft) {
						curPlatform = curTable.platforms.Microsoft;
					} else if(curTable.platforms.Macintosh) {
						curPlatform = curTable.platforms.Macintosh;
						isMac = true;
					} else  {
						return "";
					}
					
					if(isMac) {
						if(curPlatform["0"]) {
							curEncoding = curPlatform["0"];
							if(curEncoding["0"]) {
								curLanguage = curEncoding["0"];
							} else if(curEncoding["1033"]) {
								curLanguage = curEncoding["1033"];
							} else {
								return "";
							}
						} else {
							return "";
						}
					} else {
						if(curPlatform["0"]) {
							curEncoding = curPlatform["0"];
						} else if(curPlatform["1"]) {
							curEncoding = curPlatform["1"];
						} else {
							return "";
						}
						
						if(curEncoding["0409"]) {
							curLanguage = curEncoding["0409"];
						} else {
							return "";
						}
					}
					
					l2 = curLanguage.records.length;
					
					for (k = 0; k < l2; k++) {
						// nameId 2 is Font Subfamily Name
						// nameId 17 is Preferred Subfamily (Windows only)
						if (curLanguage.records[k].nameId == 2) {
							curRecord = curLanguage.records[k];
							if (curRecord.text.length > 0) {
								return curRecord.text;
							}
						}
					}
				}
			}
			
			return "";
		}
		
		public function get fontFamily():String {
			var l:uint = objData.tables.length;
			for (var j:int = 0; j < l; j++) {
				if (objData.tables[j].name == "name") {
					var curTable:Object;
					var curPlatform:Object;
					var curEncoding:Object;
					var curLanguage:Object;
					var l2:uint;
					var curRecord:Object;
					var k:int;
					var isMac:Boolean = false;
					
					curTable = objData.tables[j];
					if(curTable.platforms.Microsoft) {
						curPlatform = curTable.platforms.Microsoft;
					} else if(curTable.platforms.Macintosh) {
						curPlatform = curTable.platforms.Macintosh;
						isMac = true;
					} else  {
						return "";
					}
					
					if(isMac) {
						if(curPlatform["0"]) {
							curEncoding = curPlatform["0"];
							if(curEncoding["0"]) {
								curLanguage = curEncoding["0"];
							} else if(curEncoding["1033"]) {
								curLanguage = curEncoding["1033"];
							} else {
								return "";
							}
						} else {
							return "";
						}
					} else {
						if(curPlatform["0"]) {
							curEncoding = curPlatform["0"];
						} else if(curPlatform["1"]) {
							curEncoding = curPlatform["1"];
						} else {
							return "";
						}
						
						if(curEncoding["0409"]) {
							curLanguage = curEncoding["0409"];
						} else {
							return "";
						}
					}
					
					l2 = curLanguage.records.length;
					
					for (k = 0; k < l2; k++) {
						// nameId 1 is Font Family Name
						// nameId 16 is Preferred Family (Windows only)
						if (curLanguage.records[k].nameId == 1) {
							curRecord = curLanguage.records[k];
							if (curRecord.text.length > 0) {
								return curRecord.text;
							}
						}
					}
				}
			}
			
			return "";
		}
		
		/*
		Check only english language codes
		*/
		public function get fontName():String {
			var l:uint = objData.tables.length;
			for (var j:int = 0; j < l; j++) {
				if (objData.tables[j].name == "name") {
					var curTable:Object;
					var curPlatform:Object;
					var curEncoding:Object;
					var curLanguage:Object;
					var l2:uint;
					var curRecord:Object;
					var k:int;
					var isMac:Boolean = false;
					
					curTable = objData.tables[j];
					if(curTable.platforms.Microsoft) {
						curPlatform = curTable.platforms.Microsoft;
					} else if(curTable.platforms.Macintosh) {
						curPlatform = curTable.platforms.Macintosh;
						isMac = true;
					} else  {
						return "";
					}
					
					if(isMac) {
						if(curPlatform["0"]) {
							curEncoding = curPlatform["0"];
							if(curEncoding["0"]) {
								curLanguage = curEncoding["0"];
							} else if(curEncoding["1033"]) {
								curLanguage = curEncoding["1033"];
							} else {
								return "";
							}
						} else {
							return "";
						}
					} else {
						if(curPlatform["0"]) {
							curEncoding = curPlatform["0"];
						} else if(curPlatform["1"]) {
							curEncoding = curPlatform["1"];
						} else {
							return "";
						}
						
						if(curEncoding["0409"]) {
							curLanguage = curEncoding["0409"];
						} else {
							return "";
						}
					}
					
					l2 = curLanguage.records.length;
					
					for (k = 0; k < l2; k++) {
						// nameId 4 is Full Font Name, but fonts don't always use that?
						// nameId 6 is PostScript Font Name
						if (curLanguage.records[k].nameId == 4) {
							curRecord = curLanguage.records[k];
							if (curRecord.text.length > 0) {
								return curRecord.text;
							}
						}
					}
				}
			}
			
			return "";
		}
		
		public static function isValid(sourceFile:File):Boolean {
			var ext:String = sourceFile.extension.toLowerCase();
			if(ext) {
				if (ext == "ttf") {
					var fs:FileStream = new FileStream();
					
					fs.open(sourceFile, FileMode.READ);
					var majorVersion:uint = fs.readUnsignedShort();
					var minorVersion:uint = fs.readUnsignedShort();
					fs.close();
					
					/* ** Note
					 * Must equal 1.0 for TrueType or OpenType with TrueType data.
					 * If it's OTTO, then it's a OpenType with a CFF table (PostScript data), 
					 * and should be handled with the OTF class.
					 */
					if (majorVersion != 1 || (majorVersion == 1 && minorVersion != 0)) {
						return false;
					} else {
						return true;
					}
				}
			}
			return false;
		}
		
		protected function getOffSetTable(ba:ByteArray):Object {
			var obj:Object = new Object();
			obj.majorVersion = ba.readUnsignedShort();
			obj.minorVersion = ba.readUnsignedShort();
			obj.numTables = ba.readUnsignedShort();
			obj.searchRange = ba.readUnsignedShort();
			obj.entrySelector = ba.readUnsignedShort();
			obj.rangeShift = ba.readUnsignedShort();
			return obj;
		}
		
		protected function getDirectoryTable(ba:ByteArray):Object {
			var obj:Object = new Object();
			obj.name = ba.readUTFBytes(4); //table name
			obj.checkSum = ba.readUnsignedInt(); //Check sum
			obj.offSet = ba.readUnsignedInt(); //Offset from beginning of file
			obj.length = ba.readUnsignedInt(); //length of the table in bytes
			return obj;
		}
		
		// cmap Table
		protected function getCMAPTable():Object {
			return null;
		}
		
		// head Table
		protected function getHeadTable():Object {
			/* Fixed  	Table version number  	0x00010000 for version 1.0.
			 * Fixed 	fontRevision 	Set by font manufacturer.
			 * ULONG 	checkSumAdjustment 	To compute: set it to 0, sum the entire font as ULONG, then store 0xB1B0AFBA - sum.
			 * ULONG 	magicNumber 	Set to 0x5F0F3CF5.
			 * USHORT 	flags 	Bit 0 - baseline for font at y=0;
			 * 					Bit 1 - left sidebearing point at x=0;
			 * 					Bit 2 - instructions may depend on point size;
			 * 					Bit 3 - force ppem to integer values for all internal scaler math; may use fractional ppem sizes if this bit is clear;
			 * 					Bit 4 - instructions may alter advance width (the advance widths might not scale linearly);
			 * 					Bits 5-10:These should be set according to Apple's specification. However, they are not implemented in OpenType.
			 * 					Bit 11 - font data is 'lossless,' as a result of having been compressed and decompressed with the Agfa MicroType Express engine.
			 * 					Bit 12 - font converted (produce compatible metrics)
			 * 					Bit 13: Font optimised for ClearType
			 * 					Bit 14: Reserved, set to 0
			 * 					Bit 15: Reserved, set to 0
			 * USHORT 	unitsPerEm 	Valid range is from 16 to 16384. This value should be a power of 2 for fonts that have TrueType outlines.
			 * LONGDATETIME 	created 	Number of seconds since 12:00 midnight, January 1, 1904. 64-bit integer
			 * LONGDATETIME 	modified 	Number of seconds since 12:00 midnight, January 1, 1904. 64-bit integer
			 * USHORT 	xMin 	For all glyph bounding boxes.
			 * SHORT 	yMin 	For all glyph bounding boxes.
			 * SHORT 	xMax 	For all glyph bounding boxes.
			 * SHORT 	yMax 	For all glyph bounding boxes.
			 * USHORT 	macStyle 	Bit 0: Bold (if set to 1)
			 * 						Bit 1: Italic (if set to 1)
			 * 						Bit 2: Underline (if set to 1)
			 * 						Bit 3: Outline (if set to 1)
			 * 						Bit 4: Shadow (if set to 1)
			 * 						Bit 5: Condensed (if set to 1)
			 * 						Bit 6: Extended (if set to 1)
			 * 						Bits 7-15: reserved (set to 0).
			 * USHORT 	lowestRecPPEM 	Smallest readable size in pixels.
			 * SHORT 	fontDirectionHint 	0: Fully mixed directional glyphs;
			 * 								1: Only strongly left to right;
			 * 								2: Like 1 but also contains neutrals;
			 * 								-1: Only strongly right to left;
			 * 								-2: Like -1 but also contains neutrals. 1
			 * SHORT 	indexToLocFormat 	0 for short offsets, 1 for long.
			 * SHORT 	glyphDataFormat 	0 for current format.
			*/
			return null;
		}
		
		// hhea Table
		protected function getHHEATable():Object {
			/*Fixed  	Table version number  	0x00010000 for version 1.0.
			 * FWORD 	Ascender 	Typographic ascent. (Distance from baseline of highest ascender)
			 * FWORD 	Descender 	Typographic descent. (Distance from baseline of lowest descender)
			 * FWORD 	LineGap 	Typographic line gap. Negative LineGap values are treated as zero in Windows 3.1, System 6, and 7.
			 * UFWORD 	advanceWidthMax 	Maximum advance width value in 'hmtx' table.
			 * FWORD 	minLeftSideBearing 	Minimum left sidebearing value in 'hmtx' table.
			 * FWORD 	minRightSideBearing 	Minimum right sidebearing value; calculated as Min(aw - lsb - (xMax - xMin)).
			 * FWORD 	xMaxExtent 	Max(lsb + (xMax - xMin)).
			 * SHORT 	caretSlopeRise 	Used to calculate the slope of the cursor (rise/run); 1 for vertical.
			 * SHORT 	caretSlopeRun 	0 for vertical.
			 * SHORT 	caretOffset 	The amount by which a slanted highlight on a glyph needs to be shifted to produce the best appearance. Set to 0 for non-slanted fonts
			 * SHORT 	(reserved) 	set to 0
			 * SHORT 	(reserved) 	set to 0
			 * SHORT 	(reserved) 	set to 0
			 * SHORT 	(reserved) 	set to 0
			 * SHORT 	metricDataFormat 	0 for current format.
			 * USHORT 	numberOfHMetrics 	Number of hMetric entries in 'hmtx' table
			 */
			return null;
		}
		
		// hmtx Table
		protected function getHMTXTable():Object {
			/*
			 * Array [USHORT advanceWidth, SHORT leftSideBering]
			 * 
			 * Paired advance width and left side bearing values for each glyph. 
			 * The value numOfHMetrics comes from the 'hhea' table. 
			 * If the font is monospaced, only one entry need be in the array, 
			 * but that entry is required. The last entry applies to all subsequent glyphs.
			 * 
			 * Here the advanceWidth is assumed to be the same as the advanceWidth for the last entry above. 
			 * The number of entries in this array is derived from numGlyphs (from 'maxp' table) minus 
			 * numberOfHMetrics. This generally is used with a run of monospaced glyphs (e.g., Kanji 
			 * fonts or Courier fonts). Only one run is allowed and it must be at the end. This 
			 * allows a monospaced font to vary the left side bearing values for each glyph.
			 */
			return null;
		}
		
		// maxp Table
		protected function getMAXPTable():Object {
			// Note: PostScript only requires numGlyphs, and verion to be 0.5
			
			/* Fixed  	Table version number  	0x00005000 for version 0.5 / 0x00010000 for version 1.0
			 * USHORT 	numGlyphs 	The number of glyphs in the font.
			 * USHORT  	maxPoints  	Maximum points in a non-composite glyph.
			 * USHORT 	maxContours 	Maximum contours in a non-composite glyph.
			 * USHORT 	maxCompositePoints 	Maximum points in a composite glyph.
			 * USHORT 	maxCompositeContours 	Maximum contours in a composite glyph.
			 * USHORT 	maxZones 	1 if instructions do not use the twilight zone (Z0), or 2 if instructions do use Z0; should be set to 2 in most cases.
			 * USHORT 	maxTwilightPoints 	Maximum points used in Z0.
			 * USHORT 	maxStorage 	Number of Storage Area locations.
			 * USHORT 	maxFunctionDefs 	Number of FDEFs.
			 * USHORT 	maxInstructionDefs 	Number of IDEFs.
			 * USHORT 	maxStackElements 	Maximum stack depth2.
			 * USHORT 	maxSizeOfInstructions 	Maximum byte count for glyph instructions.
			 * USHORT 	maxComponentElements 	Maximum number of components referenced at "top level" for any composite glyph.
			 * USHORT 	maxComponentDepth 	Maximum levels of recursion; 1 for simple components.
			 */
			return null;
		}
		
		// name Table
		protected function getNameTableHeader(ba:ByteArray):Object {
			var obj:Object = new Object();
			obj.format = ba.readUnsignedShort(); // Format selector. Always 0
			obj.count = ba.readUnsignedShort(); // Name Records count
			obj.stringOffset = ba.readUnsignedShort(); // Offset for strings storage, from start of the table
			return obj;
		}
		
		protected function addNameRecords(ba:ByteArray, o:Object, nOffSet:uint):Object {
			
			var obj:Object = new Object();
			
			try {
				obj.platformId = ba.readUnsignedShort(); // Platform ID
				obj.platformType = "unknown" // Platform ID Translated
				switch(obj.platformId) {
					case 0:
						obj.platformType = "Unicode";
						break;
					case 1:
						obj.platformType = "Macintosh";
						break;
					case 2:
						obj.platformType = "ISO";
						break;
					case 3:
						obj.platformType = "Microsoft";
						break;
				}

				obj.platformSpecificID = ba.readUnsignedShort(); // Platform-specific encoding ID
				obj.platformSpecificType = "unknown"; // Platform-specific ID translated
				if (obj.platformId == 0) {
					// Unicode
					switch(obj.platformSpecificID) {
						case 0:
							obj.platformSpecificType = "Default semantics";
							break;
						case 1:
							obj.platformSpecificType = "Version 1.1 semantics";
							break;
						case 2:
							obj.platformSpecificType = "ISO 10646 1993 semantics [deprecated]";
							break;
						case 2:
							obj.platformSpecificType = "Unicode 2.0 or later semantics";
							break;
					}
				} else if (obj.platformId == 1) {
					// Macintosh
					switch(obj.platformSpecificID) {
						case 0:
							obj.platformSpecificType = "Roman";
							break;
						case 1:
							obj.platformSpecificType = "Japanese";
							break;
						case 2:
							obj.platformSpecificType = "Traditional Chinese";
							break;
						case 3:
							obj.platformSpecificType = "Korean";
							break;
						case 4:
							obj.platformSpecificType = "Arabic";
							break;
						case 5:
							obj.platformSpecificType = "Hebrew";
							break;
						case 6:
							obj.platformSpecificType = "Greek";
							break;
						case 7:
							obj.platformSpecificType = "Russian";
							break;
						case 8:
							obj.platformSpecificType = "RSymbol";
							break;
						case 9:
							obj.platformSpecificType = "Devanagari";
							break;
						case 10:
							obj.platformSpecificType = "Gurmukhi";
							break;
						case 11:
							obj.platformSpecificType = "Gujarati";
							break;
						case 12:
							obj.platformSpecificType = "Oriya";
							break;
						case 13:
							obj.platformSpecificType = "Bengali";
							break;
						case 14:
							obj.platformSpecificType = "Tamil";
							break;
						case 15:
							obj.platformSpecificType = "Telugu";
							break;
						case 16:
							obj.platformSpecificType = "Kannada";
							break;
						case 17:
							obj.platformSpecificType = "Malayalam";
							break;
						case 18:
							obj.platformSpecificType = "Sinhalese";
							break;
						case 19:
							obj.platformSpecificType = "Burmese";
							break;
						case 20:
							obj.platformSpecificType = "Khmer";
							break;
						case 21:
							obj.platformSpecificType = "Thai";
							break;
						case 22:
							obj.platformSpecificType = "Laotian";
							break;
						case 23:
							obj.platformSpecificType = "Georgian";
							break;
						case 24:
							obj.platformSpecificType = "Armenian";
							break;
						case 25:
							obj.platformSpecificType = "Simplified Chinese";
							break;
						case 26:
							obj.platformSpecificType = "Tibetan";
							break;
						case 27:
							obj.platformSpecificType = "Mongolian";
							break;
						case 28:
							obj.platformSpecificType = "Geez";
							break;
						case 29:
							obj.platformSpecificType = "Slavic";
							break;
						case 30:
							obj.platformSpecificType = "Vietnamese";
							break;
						case 31:
							obj.platformSpecificType = "Sindhi";
							break;
						case 32:
							obj.platformSpecificType = "(Uninterpreted)";
							break;
					}
				} else if (obj.platformId == 2) {
					// ISO
					switch(obj.platformSpecificID) {
						case 0:
							obj.platformSpecificType = "Unicode 1.0 semantics";
							break;
						case 1:
							obj.platformSpecificType = "Unicode 1.1 semantics";
							break;
						case 2:
							obj.platformSpecificType = "ISO 10646:1993 semantics";
							break;
					}
				} else if (obj.platformId == 3) {
					// Microsoft
					switch(obj.platformSpecificID) {
						case 0:
							obj.platformSpecificType = "Undefined";
							break;
						case 1:
							obj.platformSpecificType = "UGL";
							break;
					}
				}
				
				obj.languageId = ba.readUnsignedShort(); // Language ID
				obj.languageType = "unknown" // Language ID Translated 20 of 150
				if (obj.platformId == 1) {
					// Macintosh
					obj.languageType = getLanguageType(obj.languageId);
				} else if (obj.platformId == 2) {
					// ISO
					// There are not any ISO-specific language ID�s
				} else if (obj.platformId == 3) {
					// Microsoft
					obj.languageType = getLanguageType(obj.languageId);
					var strHex:String = obj.languageId.toString(16);
					strHex.toLowerCase();
					if (strHex.length < 4) strHex = "0" + strHex;
					obj.languageId = strHex;
					
				}
				
				obj.nameId = ba.readUnsignedShort(); // Name ID
				obj.nameType = "unknown"; // Name ID Translated
				switch(obj.nameId) {
					case 0:
						obj.nameType = "Copyright Notice";
						break;
					case 1:
						obj.nameType = "Font Family Name";
						break;
					case 2:
						obj.nameType = "Font Subfamily Name";
						break;
					case 3:
						obj.nameType = "Unique Font Identifier";
						break;
					case 4:
						obj.nameType = "Full Font Name";
						break;
					case 5:
						obj.nameType = "Version String";
						break;
					case 6:
						obj.nameType = "Postscript Name";
						break;
					case 7:
						obj.nameType = "Trademark";
						break;
					case 8:
						obj.nameType = "Manufacturer Name";
						break;
					case 9:
						obj.nameType = "Designer";
						break;
					case 10:
						obj.nameType = "Description";
						break;
					case 11:
						obj.nameType = "URL Vendor";
						break;
					case 12:
						obj.nameType = "URL Designer";
						break;
					case 13:
						obj.nameType = "License Description";
						break;
					case 14:
						obj.nameType = "License Info URL";
						break;
					case 15:
						obj.nameType = "Reserved; Set to zero;";
						break;
					case 16:
						obj.nameType = "Preferred Family (Windows only)";
						break;
					case 17:
						obj.nameType = "Preferred Subfamily (Windows only)";
						break;
					case 18:
						obj.nameType = "Compatible Full (Macintosh only)";
						break;
					case 19:
						obj.nameType = "Sample Text";
						break;
				}
				
				obj.length = ba.readUnsignedShort(); // String Length (in bytes)
				obj.offSet = ba.readUnsignedShort(); // String offset from start of storage area (in bytes)
				if(obj.offSet > ba.bytesAvailable) obj.offSet = 0;
				// Add Data //
				// Check Platform Object
				if (!o[obj.platformType]) {
					o[obj.platformType] = new Object();
					o[obj.platformType].type = obj.platformType;
					o[obj.platformType].id = obj.platformId;
				}
				var objPlatform:Object = o[obj.platformType];
				
				// Check Encoding Object
				if (!objPlatform[obj.platformSpecificID]) {
					objPlatform[obj.platformSpecificID] = new Object();
					objPlatform[obj.platformSpecificID].type = obj.platformSpecificType;
					objPlatform[obj.platformSpecificID].id = obj.platformSpecificID;
				}
				var objEncoding:Object = objPlatform[obj.platformSpecificID];
				
				// Check Language Object
				if (!objEncoding[obj.languageId]) {
					objEncoding[obj.languageId] = new Object();
					objEncoding[obj.languageId].type = obj.languageType;
					objEncoding[obj.languageId].id = obj.languageId;
				}
				var objLanguage:Object = objEncoding[obj.languageId];
				
				// Add Record
				if (!objLanguage.records) objLanguage.records = new Array();
				var nPos:uint = ba.position;
				ba.position = nOffSet + obj.offSet;
				obj.text = readUTFBytes16(ba, obj.length);
				ba.position = nPos;
				objLanguage.records.push(obj);
				
			} catch (e:EOFError) {
				obj.error = true;
			}
			return obj;
		}
		
		protected function getLanguageType(n:int):String {
			var strReturn:String = "unknown";
			
			// Macintosh, although some use Microsoft's codes
			switch(n) {
				case 0:
					strReturn = "English";
					break;
				case 1:
					strReturn = "French";
					break;
				case 2:
					strReturn = "German";
					break;
				case 3:
					strReturn = "Italian";
					break;
				case 4:
					strReturn = "Dutch";
					break;
				case 5:
					strReturn = "Swedish";
					break;
				case 6:
					strReturn = "Spanish";
					break;
				case 7:
					strReturn = "Danish";
					break;
				case 8:
					strReturn = "Portuguese";
					break;
				case 9:
					strReturn = "Norwegian";
					break;
				case 10:
					strReturn = "Hebrew";
					break;
				case 11:
					strReturn = "Japanese";
					break;
				case 12:
					strReturn = "Arabic";
					break;
				case 13:
					strReturn = "Finnish";
					break;
				case 14:
					strReturn = "Greek";
					break;
				case 15:
					strReturn = "Icelandic";
					break;
				case 16:
					strReturn = "Maltese";
					break;
				case 17:
					strReturn = "Turkish";
					break;
				case 18:
					strReturn = "Croatian";
					break;
				case 19:
					strReturn = "Chinese (traditional)";
					break;
			}
			
			if (strReturn != "unknown") return strReturn;
			
			// Microsoft
			var strHex:String = n.toString(16);
			strHex.toLowerCase();
			if (strHex.length < 4) strHex = "0" + strHex;
			//obj.languageId = strHex;
			
			switch(strHex) {
				case "041c":
					strReturn = "Albanian";
					break;
				case "042d":
					strReturn = "Basque";
					break;
				case "0423":
					strReturn = "Byelorussian";
					break;
				case "0402":
					strReturn = "Bulgarian";
					break;
				case "0403":
					strReturn = "Catalan";
					break;
				case "041a":
					strReturn = "Croatian";
					break;
				case "0405":
					strReturn = "Czech";
					break;
				case "0406":
					strReturn = "Danish";
					break;
				case "0413":
					strReturn = "Dutch (Standard)";
					break;
				case "0813":
					strReturn = "Belgian (Flemish)";
					break;
				case "0409":
					strReturn = "English (American)";
					break;
				case "0809":
					strReturn = "English (British)";
					break;
				case "0c09":
					strReturn = "English (Australian)";
					break;
				case "1009":
					strReturn = "English (Canadian)";
					break;
				case "1409":
					strReturn = "English (New Zealand)";
					break;
				case "1809":
					strReturn = "English (Ireland)";
					break;
				case "0425":
					strReturn = "Estonian";
					break;
				case "040b":
					strReturn = "Finnish";
					break;
				case "040c":
					strReturn = "French (Standard)";
					break;
				case "080c":
					strReturn = "French (Belgian)";
					break;
				case "0c0c":
					strReturn = "French (Canadian)";
					break;
				case "100c":
					strReturn = "French (Swiss)";
					break;
				case "140c":
					strReturn = "French (Luxembourg)";
					break;
				case "0407":
					strReturn = "German (Standard)";
					break;
				case "0807":
					strReturn = "German (Swiss)";
					break;
				case "0c07":
					strReturn = "German (Austrian)";
					break;
				case "1007":
					strReturn = "German (Luxembourg)";
					break;
				case "1407":
					strReturn = "German (Liechtenstein)";
					break;
				case "040e":
					strReturn = "Hungarian";
					break;
				case "040f":
					strReturn = "Icelandic";
					break;
				case "0410":
					strReturn = "Italian (Standard)";
					break;
				case "0810":
					strReturn = "Italian (Swiss)";
					break;
				case "0426":
					strReturn = "Latvian";
					break;
				case "0427":
					strReturn = "Lithuanian";
					break;
				case "0414":
					strReturn = "Norwegian (Bokmal)";
					break;
				case "0814":
					strReturn = "Norwegian (Nynorsk)";
					break;
				case "0415":
					strReturn = "Polish";
					break;
				case "0416":
					strReturn = "Portuguese (Brazilian)";
					break;
				case "0816":
					strReturn = "Portuguese (Standard)";
					break;
				case "0418":
					strReturn = "Romanian";
					break;
				case "0419":
					strReturn = "Russian";
					break;
				case "041b":
					strReturn = "Slovak";
					break;
				case "0424":
					strReturn = "Slovenian";
					break;
				case "040a":
					strReturn = "Spanish (Traditional Sort)";
					break;
				case "080a":
					strReturn = "Spanish (Mexican)";
					break;
				case "0c0a":
					strReturn = "Spanish (Modern Sort)";
					break;
			}
			
			return strReturn;
		}
		
		// OS/2 Table
		protected function getOS2Table():Object {
			/* USHORT  	version  	0x0003
			 * SHORT 	xAvgCharWidth 	 
			 * USHORT 	usWeightClass 	 
			 * USHORT 	usWidthClass 	 
			 * SHORT 	fsType 	 
			 * SHORT 	ySubscriptXSize 	 
			 * SHORT 	ySubscriptYSize 	 
			 * SHORT 	ySubscriptXOffset 	 
			 * SHORT 	ySubscriptYOffset 	 
			 * SHORT 	ySuperscriptXSize 	 
			 * SHORT 	ySuperscriptYSize 	 
			 * SHORT 	ySuperscriptXOffset 	 
			 * SHORT 	ySuperscriptYOffset 	 
			 * SHORT 	yStrikeoutSize 	 
			 * SHORT 	yStrikeoutPosition 	 
			 * SHORT 	sFamilyClass 	 
			 * BYTE 	panose[10] 	 
			 * ULONG 	ulUnicodeRange1 	Bits 0-31
			 * ULONG 	ulUnicodeRange2 	Bits 32-63
			 * ULONG 	ulUnicodeRange3 	Bits 64-95
			 * ULONG 	ulUnicodeRange4 	Bits 96-127
			 * CHAR 	achVendID[4] 	 
			 * USHORT 	fsSelection 	 
			 * USHORT 	usFirstCharIndex 	 
			 * USHORT 	usLastCharIndex 	 
			 * SHORT 	sTypoAscender 	 
			 * SHORT 	sTypoDescender 	 
			 * SHORT 	sTypoLineGap 	 
			 * USHORT 	usWinAscent 	 
			 * USHORT 	usWinDescent 	 
			 * ULONG 	ulCodePageRange1 	Bits 0-31
			 * ULONG 	ulCodePageRange2 	Bits 32-63
			 * SHORT 	sxHeight 	 
			 * SHORT 	sCapHeight 	 
			 * USHORT 	usDefaultChar 	 
			 * USHORT 	usBreakChar 	 
			 * USHORT 	usMaxContext
			*/
			return null;
		}
		
		// Post Table
		protected function getPostTable():Object {
			/* Fixed Version
			 * Fixed italicAngle
			 * FWord underlinePosition
			 * FWord underlineThickness
			 * ULONG isFixedPitch
			 * ULONG minMemType42
			 * ULONG maxMemType42
			 * ULONG minMemType1
			 * ULONG maxMemType1
			 */
			return null;
		}
		
		protected function readUTFBytes16(fs:*, length:uint):String {
			var str:String = "";
			var count:int = 1;
			var byte:String = ""; 
			for (var i:uint = 0; i < length; i++) {
				byte += fs.readUTFBytes(1);
				count++;
				
				if(count > 2) {
					if(byte == '!"') byte = "™"; // Trademark Unicode
					
					str += byte;
					byte = "";
					count = 1;
				}
			}
			return str;
		}
	}
}