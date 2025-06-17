unit uUtils;

interface

uses
  Inifiles, System.SysUtils, System.JSON, System.Classes, System.DateUtils, IdHashMessageDigest;

  //Manipulação de arquivos
  procedure GravarIni(ASecao, AIdent, AValor, AIniFile: string);
  function LerIni(ASecao, AIdent, AValorDefault, AIniFile: string): string;
  procedure GravaLog(ALog, AFileName: string);
  function GetConexaoConfig: string;
  function GetConexaoContadoresConfig: string;

  //Manipulação de JSON
  function LerJson(aJson, aIdent: string): string;  //Retorna um valor de um parametro de json
  function LerJsonFromJson(aJson, aIdent: string): string; //Retorna um objecto json de um objeto json
  function LerJsonArray(aJson, aNameArray: string): string; //Retorna um string de um array de json de um objeto
  function LerJsonFromArrayJson(aJson: string; aIndex: integer): string;   //Retorna um json dentro de um array de json
  function IsJSONValid(const jsonString: string): Boolean; //Verifica se o json é valido

  //Manipulação de arquivos de json
  function LerJsonFromFile(const FileName: string): string; //Retorna todo o conteudo de um arquivo de json
  function LerArrayJsonFromFile(const FileName: string): string; //Retorna todo o conteudo de um arquivo de array de json
  procedure GravarArrayJsonToFile(const JSON: string; const FileName: string); //Grva um arquivo de texto com o conteudo de um array de json

  //Parse
  function ConverterStringData(ADataString: string): string;

implementation

procedure GravarIni(ASecao, AIdent, AValor, AIniFile: string);
var
  vIni: TIniFile;
begin
  vIni := TIniFile.Create(AIniFile);
  try
    vIni.WriteString(ASecao, AIdent, AValor);
  finally
    vIni.Free;
  end;
end;

function LerIni(ASecao, AIdent, AValorDefault, AIniFile: string): string;
var
  vIni: TIniFile;
begin
  vIni := TIniFile.Create(AIniFile);
  try
    Result := vIni.ReadString(ASecao, AIdent, AValorDefault);
  finally
    vIni.Free;
  end;
end;

procedure GravaLog(ALog, AFileName: string);
var
  arq: TextFile;
  vDiretorio: string;
begin
  try
    vDiretorio := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'logs';
    if not DirectoryExists(vDiretorio) then
      ForceDirectories(vDiretorio);
    AssignFile(arq, IncludeTrailingPathDelimiter(vDiretorio)+AFileName+FormatDateTime('ddMMyyyy',Date)+'.txt');
    {$I-}
    Reset(arq);
    {$I+}
    if (IOResult <> 0)
       then Rewrite(arq) { arquivo não existe e será criado }
    else begin
           CloseFile(arq);
           Append(arq); { o arquivo existe e será aberto para saídas adicionais }
         end;
    WriteLn(Arq, Format('Data: %s -- Log: %s',
                        [FormatDateTime('dd/MM/yyyy hh:mm:ss', Now),
                        ALog]));
    CloseFile(Arq);
  except

  end;
end;

function GetConexaoConfig: string;
var
  vJsonResposta: TJSONObject;
begin
  try
    vJsonResposta := TJSONObject.Create
      .AddPair('ident', LerIni('DB', 'ident', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('host', LerIni('DB', 'host', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('port', LerIni('DB', 'port', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('directory', LerIni('DB', 'directory', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('username', LerIni('DB', 'username', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('password', LerIni('DB', 'password', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('usar_pooling', LerIni('DB', 'usar_pooling', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'));
    Result :=vJsonResposta.ToJSON;
  finally
    vJsonResposta.Free;
  end;
end;

function GetConexaoContadoresConfig: string;
var
  vJsonResposta: TJSONObject;
begin
  try
    vJsonResposta := TJSONObject.Create
      .AddPair('ident', LerIni('DB_CONTADORES', 'ident', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('host', LerIni('DB_CONTADORES', 'host', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('port', LerIni('DB_CONTADORES', 'port', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('directory', LerIni('DB_CONTADORES', 'directory', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('username', LerIni('DB_CONTADORES', 'username', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('password', LerIni('DB_CONTADORES', 'password', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'))
      .AddPair('usar_pooling', LerIni('DB_CONTADORES', 'usar_pooling', '', IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'config_api.ini'));
    Result :=vJsonResposta.ToJSON;
  finally
    vJsonResposta.Free;
  end;
end;

function LerJson(aJson, aIdent: string): string;
var
  Obj: TJSONObject;
begin //Retorna um valor de um json simples
  Result := '';
  if (aJson.IsEmpty) or (aJson = '[]') or (aJson = '{}') then
    Exit;
  if not (aIdent.IsEmpty) then
  begin
    Obj := TJSONObject.ParseJSONValue(aJson) as TJSONObject;
    try
      try
        Result := Obj.GetValue<string>(aIdent, '');
        if Result = '' then
          Result := Obj.GetValue<string>(aIdent.ToLower, '');
        if Result = '' then
          Result := Obj.GetValue<string>(aIdent.ToUpper, '');
      except
      end;
    finally
      Obj.Free;
    end;
  end;
end;

function LerJsonFromJson(aJson, aIdent: string): string;
var
  vObj: TJSONObject;
begin
  if aJson.IsEmpty then
  begin
    Result := '{}';
    Exit;
  end;
  vObj := nil;
  try
    vObj := TJSONObject.ParseJSONValue(aJson) as TJSONObject;
    Result := vObj.GetValue<TJSONObject>(aIdent).ToJSON;
    vObj.Free;
  except on E: Exception do
    begin
      Result := '{}';
      vObj.Free;
    end;
  end;
end;

function LerJsonArray(aJson, aNameArray: string): string;
var
  vObj: TJSONObject;
begin
  if aJson.IsEmpty then
  begin
    Result := '[]';
    Exit;
  end;
  vObj := nil;
  try
    vObj := TJSONObject.ParseJSONValue(aJson) as TJSONObject;
    Result := vObj.GetValue<TJSONArray>(aNameArray).ToJSON;
    vObj.Free;
  except on E: Exception do
    begin
      Result := '[]';
      vObj.Free;
    end;
  end;
end;

function LerJsonFromArrayJson(aJson: string; aIndex: integer): string;
var
  vArray: TJSONArray;
begin
  Result := '';
  if (aJson.IsEmpty) or (aJson = '[]') or (aJson = '{}') then
    Exit;
  try
    vArray := TJSONObject.ParseJSONValue(aJson) as TJSONArray;
    Result := (vArray.Items[aIndex] as TJSONObject).ToString;
    vArray.Free;
  except on E: Exception do
    begin
      Result := '{}';
      vArray.Free;
    end;
  end;
end;

function IsJSONValid(const jsonString: string): Boolean;
var
  jsonValue: TJSONValue;
begin
  Result := False;

  try
    jsonValue := TJSONObject.ParseJSONValue(jsonString);
    Result := Assigned(jsonValue);
    FreeAndNil(jsonValue);
  except
    // Se ocorrer uma exceção ao analisar a string JSON, significa que não é válido
    Result := False;
  end;
end;

function LerJsonFromFile(const FileName: string): string;
var
  JSONText: string;
  vObjectJson: TJSONObject;
  arquivo: TStreamReader;
begin
  if not FileExists(FileName) then
    Exit('');

  arquivo := TStreamReader.Create(FileName, TEncoding.ANSI);
  try
    JSONText := arquivo.ReadToEnd;
  finally
    arquivo.Free;
  end;
  vObjectJson := TJSONObject.ParseJSONValue(JSONText) as TJSONObject;
  Result := vObjectJson.ToJSON;
  vObjectJson.Free;
end;

function LerArrayJsonFromFile(const FileName: string): string;
var
  JSONText: string;
  FileStream: TFileStream;
  vJsonArray: TJSONArray;
begin
  if not FileExists(FileName) then
    Exit('[]');

  FileStream := TFileStream.Create(FileName, fmOpenRead);
  try
    SetLength(JSONText, FileStream.Size div SizeOf(Char));
    FileStream.ReadBuffer(JSONText[1], FileStream.Size);
  finally
    FileStream.Free;
  end;

  vJsonArray := TJSONObject.ParseJSONValue(JSONText) as TJSONArray;
  Result := vJsonArray.ToString;
  vJsonArray.Free;
end;

procedure GravarArrayJsonToFile(const JSON: string; const FileName: string);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(FileName, fmCreate);
  try
    FileStream.WriteBuffer(JSON[1], Length(JSON) * SizeOf(Char));
  finally
    FileStream.Free;
  end;
end;

function ConverterStringData(ADataString: string): string;
begin
  //Somente data "dd/mm/yyyy"
  //Data de entrada "dd/mm/yyyy"
  if Length(ADataString) < 12 then
    Result :=   Copy(ADataString, 7, 4) + '-' + Copy(ADataString, 4, 2) + '-' + Copy(ADataString, 1, 2)  //Data de saida "yyyy-mm-dd"
  else
    //Data e hora "dd/mm/yyyy hh:nn:ss"
    Result :=   Copy(ADataString, 7, 4) + '-' + Copy(ADataString, 4, 2) + '-' + Copy(ADataString, 1, 2) + ' ' + Copy(ADataString, 12, 8)  //Data de saida "yyyy-mm-dd hh:nn:ss"
end;

end.
