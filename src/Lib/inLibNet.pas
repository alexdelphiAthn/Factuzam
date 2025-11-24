unit inLibNet;

interface

function FormatSqlOnlineSqlformatOrg(sSQL: String): String;

implementation

uses  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
      System.Classes, System.Math, Vcl.Graphics,
      Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
      IdHTTP, IdSSLOpenSSL, System.JSON;

function FormatSqlOnlineSqlformatOrg(sSQL: String): String;
var
  HttpReq: TIdHTTP;
  SSLio: TIdSSLIOHandlerSocketOpenSSL;
  Parameters: TStringList;
  JsonResponseStr: String;
  JsonTmp: TJSONValue;
  sOs, sUserAgent:String;
begin
  HttpReq := TIdHTTP.Create;
  SSLio := TIdSSLIOHandlerSocketOpenSSL.Create;
  HttpReq.IOHandler := SSLio;
  SSLio.SSLOptions.SSLVersions := [sslvTLSv1_1, sslvTLSv1_2];
  HttpReq.Request.CharSet := 'utf-8';
  sOS := 'Windows NT '+IntToStr(Win32MajorVersion)+'.'+
                       IntToStr(Win32MinorVersion);
  sUserAgent := 'HeidiSQL' + '/' + '12.3.0.6589' +
                ' ('+ sOS +'; '+ 'heidisql.exe'+');';
  HttpReq.Request.UserAgent := sUserAgent;
  // Parameter documentation: https://sqlformat.org/api/
  Parameters := TStringList.Create;
  Parameters.AddPair('sql', sSQL);
  Parameters.AddPair('reindent', '1');
  Parameters.AddPair('indent_width', '2');
  Parameters.AddPair('keyword_case', 'upper');
  JsonResponseStr := HttpReq.Post('https://sqlformat.org/api/v1/format',
                                   Parameters);
  if JsonResponseStr.IsEmpty then
    raise Exception.Create('Empty result from online reformatter');
  JsonTmp := TJSONObject.ParseJSONValue(JsonResponseStr);
  Result := JsonTmp.FindValue('result').Value;
  JsonTmp.Free;
  HttpReq.Free;
end;

end.
