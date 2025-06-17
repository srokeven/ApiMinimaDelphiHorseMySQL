unit contadores.controller;

interface

uses FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf,
  FireDAC.Phys.Intf, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, Data.DB, FireDAC.Comp.Client, System.StrUtils,
  System.SysUtils, System.JSON, DataSetConverter4D,
  DataSetConverter4D.Impl;

type
  TContadoresController = class
    private
      FQuery: TFDQuery;
      FErrorReport: string;
      FSchemaSQL: string;
      function ValidarDadosContador(AJson: string): string;
    public
      constructor Create(var AConnection: TFDConnection);
      destructor Destroy; override;
      function LoadAll: string;
      function GetById(AId: integer): string;
      function Insert(AJsonContador: string): string;
      function Update(AJsonContador: string): string;
      function GetErrorReport: string;
  end;

implementation

uses uUtils;

constructor TContadoresController.Create(var AConnection: TFDConnection);
begin
  FQuery := TFDQuery.Create(nil);
  FQuery.Connection := AConnection;
end;

destructor TContadoresController.Destroy;
begin
  FQuery.Free;
  inherited;
end;

function TContadoresController.GetById(AId: integer): string;
var
  lJsonContador: TJSONObject;
  vJsonArray: TJSONArray;
begin
  FQuery.SQL.Text := 'SELECT C.* FROM companies C where C.ID = :ID ';
  FQuery.ParamByName('ID').AsInteger := AId;
  FQuery.Open;
  if not (FQuery.IsEmpty) then
  begin
    lJsonContador := TConverter.New.DataSet.Source(FQuery).AsJSONObject;
    FQuery.Close;
    FQuery.SQL.Text := 'SELECT * FROM company_address where `ID_COMPANY` = :ID_COMPANY ';
    FQuery.ParamByName('ID_COMPANY').AsInteger := AId;
    FQuery.Open;
    lJsonContador.AddPair('ADDRESS', TConverter.New.DataSet.Source(FQuery).AsJSONArray);

    FQuery.Close;
    FQuery.SQL.Text := 'SELECT * FROM company_emails where `ID_COMPANY` = :ID_COMPANY ';
    FQuery.ParamByName('ID_COMPANY').AsInteger := AId;
    FQuery.Open;
    lJsonContador.AddPair('EMAIL', TConverter.New.DataSet.Source(FQuery).AsJSONArray);

    FQuery.Close;
    FQuery.SQL.Text := 'SELECT * FROM company_phones where `ID_COMPANY` = :ID_COMPANY ';
    FQuery.ParamByName('ID_COMPANY').AsInteger := AId;
    FQuery.Open;
    lJsonContador.AddPair('PHONE', TConverter.New.DataSet.Source(FQuery).AsJSONArray);

    FQuery.Close;
    FQuery.SQL.Text := 'SELECT * FROM company_employees where `ID_COMPANY` = :ID_COMPANY ';
    FQuery.ParamByName('ID_COMPANY').AsInteger := AId;
    FQuery.Open;
    lJsonContador.AddPair('EMPLOYEE', TConverter.New.DataSet.Source(FQuery).AsJSONArray);
    Result := lJsonContador.ToJSON;
  end;
  FQuery.Close;

  lJsonContador.Free;
end;

function TContadoresController.GetErrorReport: string;
begin
  Result := FErrorReport;
end;

function TContadoresController.Insert(AJsonContador: string): string;
var
  lJson: TJSONObject;
  I, O, lIdContador: Integer;
  lRetornoValidacao: string;
begin
  //Inserindo um registro por vez, para inserir varios de forma rapida verificar o uso de Array DML
  lJson := TJSONValue.ParseJSONValue(AJsonContador) as TJSONObject;
  for I := 0 to lJson.GetValue<TJSONArray>('company').Count - 1 do
  begin
    lRetornoValidacao := ValidarDadosContador(lJson.GetValue<TJSONArray>('company').ToJSON);

    if not (lRetornoValidacao.IsEmpty) then
    begin
      Result := Result + lRetornoValidacao;
      Continue;
    end;

    FQuery.Close;
    try
      FQuery.SQL.Text := 'insert into `companies`(`NAME_FANTASY`, `CRC`, `SOCIAL_REASON`, `CNPJ`, `CPF`, `QTD_DOWN_INPUT`, `QTD_DOWN_EXIT`, `QTD_CUSTOMER_CREATE`, `QTD_LOGIN`, `STATUS`, `QTD_FILE_INPUT`, `QTD_FILE_EXIT`) '+
                         'values (:NAME_FANTASY, :CRC, :SOCIAL_REASON, :CNPJ, :CPF, :QTD_DOWN_INPUT, :QTD_DOWN_EXIT, :QTD_CUSTOMER_CREATE, :QTD_LOGIN, :STATUS, :QTD_FILE_INPUT, :QTD_FILE_EXIT) ';

      FQuery.ParamByName('NAME_FANTASY').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('NAME_FANTASY', '');
      FQuery.ParamByName('CRC').AsString           := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CRC', '');
      FQuery.ParamByName('SOCIAL_REASON').AsString := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('SOCIAL_REASON', '');
      FQuery.ParamByName('CNPJ').AsString          := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CNPJ', '');
      FQuery.ParamByName('CPF').AsString           := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CPF', '');

      FQuery.ParamByName('QTD_DOWN_INPUT').AsInteger      := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_DOWN_INPUT', 0);
      FQuery.ParamByName('QTD_DOWN_EXIT').AsInteger       := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_DOWN_EXIT', 0);
      FQuery.ParamByName('QTD_CUSTOMER_CREATE').AsInteger := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_CUSTOMER_CREATE', 0);
      FQuery.ParamByName('QTD_LOGIN').AsInteger           := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_LOGIN', 0);
      FQuery.ParamByName('STATUS').AsInteger              := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('STATUS', 0);
      FQuery.ParamByName('QTD_FILE_INPUT').AsInteger      := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_FILE_INPUT', 0);
      FQuery.ParamByName('QTD_FILE_EXIT').AsInteger       := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_FILE_EXIT', 0);
      FQuery.ExecSQL;
      FQuery.SQL.Text := 'select max(ID) ID from `companies` where `CRC` = :CRC';
      FQuery.ParamByName('CRC').AsString := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CRC', '');
      FQuery.Open;
      if not FQuery.IsEmpty then
        lIdContador := FQuery.FieldByName('ID').AsInteger;
      FQuery.Close;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Count - 1 do
      begin
        FQuery.SQL.Text := 'INSERT INTO `company_address`(`ADDRESS`, `NEIGHBORHOOD`, `NUMBER`, `UF`, `CEP`, `CITY`, `ID_COMPANY`) '+
                           'VALUES (:ADDRESS, :NEIGHBORHOOD, :NUMBER, :UF, :CEP, :CITY, :ID_COMPANY)';

        FQuery.ParamByName('ADDRESS').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('STREET', '');
        FQuery.ParamByName('NEIGHBORHOOD').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('NEIGHBORHOOD', '');
        FQuery.ParamByName('NUMBER').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('NUMBER', '');
        FQuery.ParamByName('UF').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('UF', '');
        FQuery.ParamByName('CEP').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('CEP', '');
        FQuery.ParamByName('CITY').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('CITY', '');
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMAIL').Count - 1 do
      begin
        FQuery.SQL.Text := 'INSERT INTO `company_emails`(`EMAIL`, `ID_COMPANY`) '+
                           'VALUES (:EMAIL, :ID_COMPANY)';

        FQuery.ParamByName('EMAIL').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMAIL').Items[O].GetValue<string>('EMAIL', '');
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('PHONE').Count - 1 do
      begin
        FQuery.SQL.Text := 'INSERT INTO `company_phones`(`PHONE`, `ID_COMPANY`) '+
                           'VALUES (:PHONE, :ID_COMPANY)';

        FQuery.ParamByName('PHONE').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('PHONE').Items[O].GetValue<string>('PHONE', '');
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Count - 1 do
      begin
        FQuery.SQL.Text := 'INSERT INTO `company_employees`(`NAME`, `LOGIN`, `PASSWORD`, `ACCESS_LEVEL`, `ID_COMPANY`) '+
                           'VALUES (:NAME, :LOGIN, :PASSWORD, :ACCESS_LEVEL, :ID_COMPANY)';

        FQuery.ParamByName('NAME').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<string>('NAME', '');
        FQuery.ParamByName('LOGIN').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<string>('LOGIN', '');
        FQuery.ParamByName('PASSWORD').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<string>('PASSWORD', '');
        FQuery.ParamByName('ACCESS_LEVEL').AsInteger  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<integer>('ACCESS_LEVEL', 0);
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;
    except
      on Err: Exception do
      begin
        Result := Result + Format('Erro ao salvar cadastro para %s - %s: Erro: %s ; ',
          [lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CRC', ''),
           lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('NAME_FANTASY', ''),
           Err.Message]);
      end;
    end;
  end;
  lJson.Free;
end;

function TContadoresController.LoadAll: string;
var
  vJsonArray: TJSONArray;
begin
  FSchemaSQL := 'SELECT C.ID, C.NAME_FANTASY, C.CRC, C.SOCIAL_REASON, C.CNPJ, C.CPF, '+
                       'CA.ADDRESS, CA.NEIGHBORHOOD, CA.NUMBER, CA.UF, CA.CEP, CA.CITY, ' +
                       'CE.EMAIL, CP.PHONE ' +
                'FROM companies C ' +
                'JOIN company_address CA ON ' +
                     'C.ID = CA.ID_COMPANY ' +
                'JOIN company_emails CE ON ' +
                     'C.ID = CE.ID_COMPANY ' +
                'JOIN company_phones CP ON ' +
                     'C.ID = CP.ID_COMPANY '+
                'ORDER BY C.ID; ';
  FQuery.SQL.Text := FSchemaSQL;
  FQuery.Open;
  if not FQuery.IsEmpty then
  begin
    vJsonArray := TConverter.New.DataSet.Source(FQuery).AsJSONArray;
    try
      Result := vJsonArray.ToJSON;
    finally
      vJsonArray.Free;
    end;
  end else Result := '[]';
  FQuery.Close;
end;

function TContadoresController.Update(AJsonContador: string): string;
var
  lJson: TJSONObject;
  I, O, lIdContador: Integer;
  lRetornoValidacao: string;
begin
  lJson := TJSONValue.ParseJSONValue(AJsonContador) as TJSONObject;
  for I := 0 to lJson.GetValue<TJSONArray>('company').Count - 1 do
  begin
    lRetornoValidacao := ValidarDadosContador(lJson.GetValue<TJSONArray>('company').ToJSON);

    if not (lRetornoValidacao.IsEmpty) then
    begin
      Result := Result + lRetornoValidacao;
      Continue;
    end;
    FQuery.Close;
    try
      FQuery.SQL.Text := ' UPDATE `companies` SET ' +
                         ' `NAME_FANTASY` = :NAME_FANTASY, '+
                         ' `CRC` = :CRC, '+
                         ' `SOCIAL_REASON` = :SOCIAL_REASON, '+
                         ' `CNPJ` = :CNPJ, '+
                         ' `CPF` = :CPF, '+
                         ' `QTD_DOWN_INPUT` = :QTD_DOWN_INPUT, '+
                         ' `QTD_DOWN_EXIT` = :QTD_DOWN_EXIT, '+
                         ' `QTD_CUSTOMER_CREATE` = :QTD_CUSTOMER_CREATE, '+
                         ' `QTD_LOGIN` = :QTD_LOGIN, '+
                         ' `STATUS` = :STATUS, '+
                         ' `QTD_FILE_INPUT` = :QTD_FILE_INPUT, '+
                         ' `QTD_FILE_EXIT` = :QTD_FILE_EXIT '+
                         ' WHERE `ID` = :ID ';

      lIdContador := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('ID', 0);
      FQuery.ParamByName('ID').AsInteger           := lIdContador;
      FQuery.ParamByName('NAME_FANTASY').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('NAME_FANTASY', '');
      FQuery.ParamByName('CRC').AsString           := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CRC', '');
      FQuery.ParamByName('SOCIAL_REASON').AsString := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('SOCIAL_REASON', '');
      FQuery.ParamByName('CNPJ').AsString          := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CNPJ', '');
      FQuery.ParamByName('CPF').AsString           := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CPF', '');

      FQuery.ParamByName('QTD_DOWN_INPUT').AsInteger      := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_DOWN_INPUT', 0);
      FQuery.ParamByName('QTD_DOWN_EXIT').AsInteger       := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_DOWN_EXIT', 0);
      FQuery.ParamByName('QTD_CUSTOMER_CREATE').AsInteger := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_CUSTOMER_CREATE', 0);
      FQuery.ParamByName('QTD_LOGIN').AsInteger           := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_LOGIN', 0);
      FQuery.ParamByName('STATUS').AsInteger              := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('STATUS', 0);
      FQuery.ParamByName('QTD_FILE_INPUT').AsInteger      := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_FILE_INPUT', 0);
      FQuery.ParamByName('QTD_FILE_EXIT').AsInteger       := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<integer>('QTD_FILE_EXIT', 0);
      FQuery.ExecSQL;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Count - 1 do
      begin
        if lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<integer>('ID', 0) = 0 then
          FQuery.SQL.Text := 'INSERT INTO `company_address`(`ADDRESS`, `NEIGHBORHOOD`, `NUMBER`, `UF`, `CEP`, `CITY`, `ID_COMPANY`) '+
                             'VALUES (:ADDRESS, :NEIGHBORHOOD, :NUMBER, :UF, :CEP, :CITY, :ID_COMPANY)'
        else
        begin
          FQuery.SQL.Text := 'UPDATE `company_address` SET ' +
                               '`ADDRESS` = :ADDRESS, ' +
                               '`NEIGHBORHOOD` = :NEIGHBORHOOD, ' +
                               '`NUMBER` = :NUMBER, ' +
                               '`UF` = :UF, ' +
                               '`CEP` = :CEP, ' +
                               '`CITY` = :CITY, ' +
                               '`ID_COMPANY` = :ID_COMPANY '+
                               'WHERE `ID` = :ID ';
          FQuery.ParamByName('ID').AsInteger := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<integer>('ID', 0);
        end;

        FQuery.ParamByName('ADDRESS').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('STREET', '');
        FQuery.ParamByName('NEIGHBORHOOD').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('NEIGHBORHOOD', '');
        FQuery.ParamByName('NUMBER').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('NUMBER', '');
        FQuery.ParamByName('UF').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('UF', '');
        FQuery.ParamByName('CEP').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('CEP', '');
        FQuery.ParamByName('CITY').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('ADDRESS').Items[O].GetValue<string>('CITY', '');
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMAIL').Count - 1 do
      begin
        if lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMAIL').Items[O].GetValue<integer>('ID', 0) = 0 then
          FQuery.SQL.Text := 'INSERT INTO `company_emails`(`EMAIL`, `ID_COMPANY`) '+
                             'VALUES (:EMAIL, :ID_COMPANY)'
        else
        begin
          FQuery.SQL.Text := 'UPDATE `company_emails` SET ' +
                             '`ID_COMPANY` = :ID_COMPANY, '+
                             '`EMAIL` = :EMAIL ' +
                             'WHERE `ID` = :ID';
          FQuery.ParamByName('ID').AsInteger := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMAIL').Items[O].GetValue<integer>('ID', 0);
        end;

        FQuery.ParamByName('EMAIL').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMAIL').Items[O].GetValue<string>('EMAIL', '');
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('PHONE').Count - 1 do
      begin
        if lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('PHONE').Items[O].GetValue<integer>('ID', 0) = 0 then
          FQuery.SQL.Text := 'INSERT INTO `company_phones`(`PHONE`, `ID_COMPANY`) '+
                             'VALUES (:PHONE, :ID_COMPANY)'
        else
        begin
          FQuery.SQL.Text := 'UPDATE `company_phones` SET ' +
                             '`ID_COMPANY` = :ID_COMPANY, '+
                             '`PHONE` = :PHONE ' +
                             'WHERE `ID` = :ID';
          FQuery.ParamByName('ID').AsInteger := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('PHONE').Items[O].GetValue<integer>('ID', 0);
        end;

        FQuery.ParamByName('PHONE').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('PHONE').Items[O].GetValue<string>('PHONE', '');
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;

      for O := 0 to lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Count - 1 do
      begin
        if lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<integer>('ID', 0) = 0 then
          FQuery.SQL.Text := 'INSERT INTO `company_employees`(`NAME`, `LOGIN`, `PASSWORD`, `ACCESS_LEVEL`, `ID_COMPANY`) '+
                             'VALUES (:NAME, :LOGIN, :PASSWORD, :ACCESS_LEVEL, :ID_COMPANY)'
        else
        begin
          FQuery.SQL.Text := 'UPDATE `company_employees` SET ' +
                             '`NAME` = :NAME, ' +
                             '`LOGIN` = :LOGIN, ' +
                             '`PASSWORD` = :PASSWORD, ' +
                             '`ID_COMPANY` = :ID_COMPANY, '+
                             '`ACCESS_LEVEL` = :ACCESS_LEVEL ' +
                             'WHERE `ID` = :ID';
          FQuery.ParamByName('ID').AsInteger := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<integer>('ID', 0);
        end;

        FQuery.ParamByName('NAME').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<string>('NAME', '');
        FQuery.ParamByName('LOGIN').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<string>('LOGIN', '');
        FQuery.ParamByName('PASSWORD').AsString  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<string>('PASSWORD', '');
        FQuery.ParamByName('ACCESS_LEVEL').AsInteger  := lJson.GetValue<TJSONArray>('company').Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<integer>('ACCESS_LEVEL', 0);
        FQuery.ParamByName('ID_COMPANY').AsInteger  := lIdContador;
        FQuery.ExecSQL;
      end;
    except
      on Err: Exception do
      begin
        Result := Result + Format('Erro ao salvar cadastro para %s - %s: Erro: %s ; ',
          [lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('CRC', ''),
           lJson.GetValue<TJSONArray>('company').Items[I].GetValue<string>('NAME_FANTASY', ''),
           Err.Message]);
      end;
    end;
  end;
  lJson.Free;
end;

function TContadoresController.ValidarDadosContador(AJson: string): string;
var
  lJson: TJSONArray;
  I: Integer;
  O: Integer;
begin
  lJson := TJSONValue.ParseJSONValue(AJson) as TJSONArray;
  try
    for I := 0 to lJson.Count - 1 do
    begin
      if lJson.Items[I].GetValue<integer>('ID', 0) = 0 then //Cadastro novo
      begin
        FQuery.Open('select `ID`, `CRC`, `NAME_FANTASY` from `companies` where `CRC` = '+QuotedStr(lJson.Items[I].GetValue<string>('CRC', '0')));
        if not (FQuery.IsEmpty) then
        begin
          Result := Result + Format('O CRC informado ja possui um cadastro para %d - %s; ', [FQuery.FieldByName('ID').AsInteger, FQuery.FieldByName('NAME_FANTASY').AsString]);
          Continue;
        end;
        if not (lJson.Items[I].GetValue<string>('CNPJ', '') = EmptyStr) then
        begin
          FQuery.Open('select `ID`, `CRC`, `NAME_FANTASY` from `companies` where `CNPJ` = '+QuotedStr(lJson.Items[I].GetValue<string>('CNPJ', '')));
          if not (FQuery.IsEmpty) then
          begin
            Result := Result + Format('O CNPJ informado ja possui um cadastro para %s - %s; ', [FQuery.FieldByName('CRC').AsString, FQuery.FieldByName('NAME_FANTASY').AsString]);
            Continue;
          end;
        end
        else if not (lJson.Items[I].GetValue<string>('CPF', '') = EmptyStr) then
        begin
          FQuery.Open('select `ID`, `CRC`, `NAME_FANTASY` from `companies` where `CPF` = '+QuotedStr(lJson.Items[I].GetValue<string>('CPF', '')));
          if not (FQuery.IsEmpty) then
          begin
            Result := Result + Format('O CPF informado ja possui um cadastro para %s - %s; ', [FQuery.FieldByName('CRC').AsString, FQuery.FieldByName('NAME_FANTASY').AsString]);
            Continue;
          end;
        end
        else
        begin
          Result := Result + 'CNPJ ou CPF não informado';
          Continue;
        end;
        for O := 0 to lJson.Items[I].GetValue<TJSONArray>('EMPLOYEE').Count - 1 do
        begin
          FQuery.Open('select `ID`, `LOGIN` from `company_employees` where `LOGIN` = '+QuotedStr(lJson.Items[I].GetValue<string>('LOGIN', '0')));
          if not (FQuery.IsEmpty) then
          begin
            Result := Result + Format('O login informado já possui um cadastro: %s; ', [FQuery.FieldByName('LOGIN').AsString]);
            Continue;
          end;
        end;
      end
      else //Cadastro atualizado
      begin
        for O := 0 to lJson.Items[I].GetValue<TJSONArray>('EMPLOYEE').Count - 1 do
        begin
          if lJson.Items[I].GetValue<TJSONArray>('EMPLOYEE').Items[O].GetValue<integer>('ID', 0) = 0 then
          begin
            FQuery.Open('select `ID`, `LOGIN` from `company_employees` where `LOGIN` = '+QuotedStr(lJson.Items[I].GetValue<string>('LOGIN', '0')));
            if not (FQuery.IsEmpty) then
            begin
              Result := Result + Format('O login informado já possui um cadastro: %s; ', [FQuery.FieldByName('LOGIN').AsString]);
              Continue;
            end;
          end;
        end;
      end;
    end;
    FQuery.Close;
  finally
    lJson.Free;
  end;
end;

end.
