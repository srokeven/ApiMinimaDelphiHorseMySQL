program ApiContadores;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Horse,
  Horse.Jhonson,
  Horse.HandleException,
  System.JSON,
  System.SysUtils,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.ConsoleUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  UConnectionPool in 'dao\UConnectionPool.pas',
  uUtils in 'common\uUtils.pas',
  contadores.controller in 'controller\contadores.controller.pas';

{ <<<<<<<<< Declara��o de variaveis >>>>>>>> }
var
  App: THorse;
  FPortaWS: string;
  FConfigConexao: string;

  { <<<<<<<<< Fun��es >>>>>>>> }

procedure CarregaConfiguracao;
begin
  FPortaWS := '9000';
  FormatSettings.ShortDateFormat := 'dd/mm/yyyy'; // Formato desejado para data
  FormatSettings.DateSeparator := '/'; // Separador de data
  FormatSettings.ShortTimeFormat := 'hh:nn:ss'; // Formato desejado para hora
  FormatSettings.TimeSeparator := ':'; // Separador de hora
  FConfigConexao := GetConexaoContadoresConfig; //Carrega variavel global com conex�o em json
end;

procedure GetContadores(Req: THorseRequest; Res: THorseResponse);
var
  lContadores: TContadoresController;
  lJsonResposta: TJSONObject;
  lResposta: string;
  Conn: TFDConnection; //Conex�o criada para cada requisi��o
begin
  if LerJson(FConfigConexao, 'host').IsEmpty then
  begin
    Writeln('Sem configura��o do banco de dados');
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('status', 0)
       .AddPair('message', 'Sem configura��o do banco de dados'))
       .Status(THTTPStatus.ServiceUnavailable);
    Exit;
  end;
  try
    Conn := GlobalConnPool.AcquireConnection; //Pega uma conex�o disponivel no pool de conex�es
    if Conn <> nil then
    begin
      lContadores := TContadoresController.Create(Conn);
      lResposta := lContadores.LoadAll;
      if (lResposta.IsEmpty) or (lResposta = '[]') then
        lJsonResposta := TJSONObject.Create.AddPair('status', 0)
                                           .AddPair('message', 'Sem registros')
      else
        lJsonResposta := TJSONObject.Create.AddPair('status', 1)
                                           .AddPair('message', 'ok')
                                           .AddPair('contadores', TJSONObject.ParseJSONValue(lResposta) as TJSONArray);
      Res.Send<TJSONObject>(lJsonResposta).Status(THTTPStatus.OK);
    end else
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('status', 0)
                                              .AddPair('message', 'N�o foi possivel conectar com o banco de dados'))
        .Status(THTTPStatus.InternalServerError);
  finally
    if lContadores <> nil then
      lContadores.Free;
    if Conn <> nil then
      GlobalConnPool.ReleaseConnection(Conn); //Libera conex�o para outra requisi��o usar
  end;
end;

procedure GetContador(Req: THorseRequest; Res: THorseResponse);
var
  lContadores: TContadoresController;
  lJsonResposta: TJSONObject;
  lResposta: string;
  lContadorID: integer;
  Conn: TFDConnection;
begin
  if LerJson(FConfigConexao, 'host').IsEmpty then
  begin
    Writeln('Sem configura��o do banco de dados');
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('status', 0)
       .AddPair('message', 'Sem configura��o do banco de dados'))
       .Status(THTTPStatus.ServiceUnavailable);
    Exit;
  end;
  try
    Conn := GlobalConnPool.AcquireConnection;
    if Conn <> nil then
    begin
      lContadores := TContadoresController.Create(Conn);
      lContadorID := StrToIntDef(Req.Params['contador'].Replace('*', ''),0);

      lResposta := lContadores.GetById(lContadorID);
      if (lResposta.IsEmpty) or (lResposta = '[]') then
        lJsonResposta := TJSONObject.Create.AddPair('status', 0)
          .AddPair('message', 'Sem registros')
      else
        lJsonResposta := TJSONObject.Create.AddPair('status', 1)
          .AddPair('message', 'ok').AddPair('company',
          TJSONObject.ParseJSONValue(lResposta) as TJSONObject);
      Res.Send<TJSONObject>(lJsonResposta).Status(THTTPStatus.OK);
    end else
      Res.Send<TJSONObject>(TJSONObject.Create.AddPair('status', 0)
        .AddPair('message', 'N�o foi possivel conectar com o banco de dados'))
          .Status(THTTPStatus.InternalServerError);
  finally
    if lContadores <> nil then
      lContadores.Free;
    if Conn <> nil then
      GlobalConnPool.ReleaseConnection(Conn);
  end;
end;

procedure PostContadores(Req: THorseRequest; Res: THorseResponse);
var
  lResposta: string;
  lContadores: TContadoresController;
  Conn: TFDConnection;
begin
  if LerJson(FConfigConexao, 'host').IsEmpty then
  begin
    Writeln('Sem configura��o do banco de dados');
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('status', 0)
       .AddPair('message', 'Sem configura��o do banco de dados'))
       .Status(THTTPStatus.ServiceUnavailable);
    Exit;
  end;
  try
    Conn := GlobalConnPool.AcquireConnection;
    if Conn <> nil then
    begin
      lContadores := TContadoresController.Create(Conn);
      lResposta := lContadores.Insert(Req.Body);
      if (lResposta.IsEmpty) then
        Res.Send<TJSONObject>(
          TJSONObject.Create.AddPair('status', 1)
                            .AddPair('message', 'ok')
        ).Status(THTTPStatus.Created)
      else
        Res.Send<TJSONObject>(
          TJSONObject.Create.AddPair('status', 0)
                            .AddPair('message', lResposta)
        ).Status(THTTPStatus.OK);
    end;
  finally
    if lContadores <> nil then
      lContadores.Free;
    if Conn <> nil then
      GlobalConnPool.ReleaseConnection(Conn);
  end;
end;

procedure PutContadores(Req: THorseRequest; Res: THorseResponse);
var
  lResposta: string;
  lContadores: TContadoresController;
  Conn: TFDConnection;
begin
  if LerJson(FConfigConexao, 'host').IsEmpty then
  begin
    Writeln('Sem configura��o do banco de dados');
    Res.Send<TJSONObject>(TJSONObject.Create.AddPair('status', 0)
                                            .AddPair('message', 'Sem configura��o do banco de dados'))
       .Status(THTTPStatus.ServiceUnavailable);
    Exit;
  end;
  try
    Conn := GlobalConnPool.AcquireConnection;
    if Conn <> nil then
    begin
      lContadores := TContadoresController.Create(Conn);
      lResposta := lContadores.Update(Req.Body);
      if (lResposta.IsEmpty) then
        Res.Send<TJSONObject>(
          TJSONObject.Create.AddPair('status', 1)
                            .AddPair('message', 'ok')
        ).Status(THTTPStatus.Created)
      else
        Res.Send<TJSONObject>(
          TJSONObject.Create.AddPair('status', 0)
                            .AddPair('message', lResposta)
        ).Status(THTTPStatus.OK);
    end;
  finally
    if lContadores <> nil then
      lContadores.Free;
    if Conn <> nil then
      GlobalConnPool.ReleaseConnection(Conn);
  end;
end;

{ <<<<<<<<< Inicio da aplica��o >>>>>>>> }
begin
  try
    CarregaConfiguracao;
    InitConnectionPool(LerJson(FConfigConexao, 'host'),
                       LerJson(FConfigConexao, 'directory'),
                       LerJson(FConfigConexao, 'port'),
                       LerJson(FConfigConexao, 'username'),
                       LerJson(FConfigConexao, 'password'),
                       'Contadores'); //Inicia pool de conex�es
    App := THorse.Create;
    App.Use(Jhonson()); //Mid para uso de json
    App.Use(HandleException); //Mid para tratar erros
    App.Port := StrToIntDef(FPortaWS, 9000);
    App.MaxConnections := 1500;
    App.Get('/online', procedure(Req: THorseRequest; Res: THorseResponse) //Teste de api online sem necessidade de autentica��es
      begin
        Res.Send(FormatDateTime('dd/mm/yyyy hh:nn:ss', now)).Status(THTTPStatus.OK);
        GravaLog('Teste de servi�o: Conex�o: '+GetConexaoContadoresConfig, 'log_envio_');
      end);
    //Necessario implementar autentica��es, pois atualmente esta livre e sem seguran�a
    App.Post('/contadores', PostContadores);
    App.Put('/contadores', PutContadores);
    App.Get('/contadores', GetContadores);
    App.Get('/contador/:contador', GetContador);

    App.Listen;
    CloseConnectionPool; //Libera caso o servi�o chegue no fim
    Writeln('Servi�o online na porta: ' + FPortaWS);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
    end;
  end;

end.
