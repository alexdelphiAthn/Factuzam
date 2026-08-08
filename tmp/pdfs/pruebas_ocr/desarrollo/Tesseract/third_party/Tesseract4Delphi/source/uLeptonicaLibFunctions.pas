unit uLeptonicaLibFunctions;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

{$I tesseract.inc}

{$IFNDEF TARGET_64BITS}{$ALIGN ON}{$ENDIF}
{$MINENUMSIZE 1}

interface

uses
  uLeptonicaTypes;

var
  pixRead        : function(const filename: PUTF8Char): PPix; cdecl;
  pixDestroy     : procedure(var pix: PPix); cdecl;
  pixReadMem     : function(const pdata: pl_uint8; size: NativeUInt): PPix; cdecl;
  pixWriteMem    : function(var pfdata: pl_uint8; var pfsize: NativeUInt; pix: PPix; format: l_int32): l_ok; cdecl;
  pixDeskew      : function(pixs: PPix; redsearch: l_int32): PPix; cdecl;
  lept_free      : procedure(ptr: Pointer); cdecl;
  boxCreate      : function(x, y, w, h: l_int32): PBox; cdecl;
  boxDestroy     : procedure(var box: PBox); cdecl;
  boxCopy        : function(box: PBox): PBox; cdecl;
  boxClone       : function(box: PBox): PBox; cdecl;
  boxaCreate     : function(n: l_int32): PBoxa; cdecl;
  boxaDestroy    : procedure(var boxa: PBoxa); cdecl;
  pixaCreate     : function(n: l_int32): PPixa; cdecl;
  pixaDestroy    : procedure(var pixa: PPixa); cdecl;

implementation

end.
