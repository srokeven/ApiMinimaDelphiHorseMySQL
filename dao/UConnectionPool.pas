unit UConnectionPool;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Phys.MySQL,
  FireDAC.Phys.MySQLDef, FireDAC.DApt, FireDAC.Stan.Error, SyncObjs, uUtils;

type
  TConnectionPool = class
  private
    FPool: TList<TFDConnection>;
    FInUse: TDictionary<TFDConnection, Boolean>;
    FLock: TCriticalSection;
    FMaxSize: Integer;
    FServer,
    FDatabase,
    FPort,
    FUsername,
    FPassword,
    FAplication: string;

    function CreateNewConnection: TFDConnection;
    procedure FDConexaoError(ASender, AInitiator: TObject; var AException: Exception);
  public
    procedure LoadParams(AServer, ADatabase, APort, AUsername, APassword, AAplication: string);
    constructor Create(MaxSize: Integer = 10);
    destructor Destroy; override;

    function AcquireConnection: TFDConnection;
    procedure ReleaseConnection(AConn: TFDConnection);
  end;

var
  GlobalConnPool: TConnectionPool;

procedure InitConnectionPool(AServer, ADatabase, APort, AUsername, APassword, AAplication: string);
procedure CloseConnectionPool;

implementation

{ TConnectionPool }

constructor TConnectionPool.Create(MaxSize: Integer);
begin
  inherited Create;
  FMaxSize := MaxSize;
  FPool := TList<TFDConnection>.Create;
  FInUse := TDictionary<TFDConnection, Boolean>.Create;
  FLock := TCriticalSection.Create;
end;

destructor TConnectionPool.Destroy;
var
  Conn: TFDConnection;
begin
  for Conn in FPool do
    Conn.Free;

  FInUse.Free;
  FPool.Free;
  FLock.Free;
  inherited;
end;

procedure TConnectionPool.LoadParams(AServer, ADatabase, APort, AUsername, APassword, AAplication: string);
begin
  FServer := AServer;
  FDatabase := ADatabase;
  FPort := APort;
  FUsername := AUsername;
  FPassword := APassword;
  FAplication := AAplication;
end;

procedure TConnectionPool.FDConexaoError(ASender, AInitiator: TObject;
  var AException: Exception);
var
  oExc: EFDDBEngineException;
  OnError: string;
  function DBExceptionToStr(aErroKind: TFDCommandExceptionKind): string;
  begin
    case aErroKind of
      ekOther: Result := 'Outros';
      ekNoDataFound: Result := 'Não foi encontrado dados';
      ekTooManyRows: Result := 'Multiplas linhas retornado';
      ekRecordLocked: Result := 'Transação travada';
      ekUKViolated: Result := 'Chave unica duplicada';
      ekFKViolated: Result := 'Chave estrangeira não encontrada';
      ekObjNotExists: Result := 'O objeto não exite';
      ekUserPwdInvalid: Result := 'Senha do usuario não é valida';
      ekUserPwdExpired: Result := 'Senha do usuario expirou';
      ekUserPwdWillExpire: Result := 'Senha do usuario vai expirar';
      ekCmdAborted: Result := 'Comando abortado';
      ekServerGone: Result := 'Perca de comunicação com o servidor';
      ekServerOutput: Result := 'Erro no servidor';
      ekArrExecMalfunc: Result := 'ArrExecMalfunc';
      ekInvalidParams: Result := 'Parametro invalido';
    end;
  end;
begin
  if AException is EFDDBEngineException then
  begin
    oExc := EFDDBEngineException(AException);
    if oExc.Kind = ekRecordLocked then
      oExc.Message := 'Exite uma transação pendente para o registro atual.'+#13#10+
        'Mensagem original: '+oExc.Errors[0].ObjName
    else if oExc.Kind = ekUKViolated then
      oExc.Message := 'Chave duplicada. Já existe um registro com a chave primaria informada'+#13#10+
        'Mensagem original: '+oExc.Errors[0].ObjName
    else if oExc.Kind = ekFKViolated then
      oExc.Message := 'Não foi possivel encontrar a chave estrangeira informada para o registro atual'+#13#10+
        'Mensagem original: '+oExc.Errors[0].ObjName
    else oExc.Message := oExc.Errors[0].Message+#13#10+'SQL: '+oExc.SQL;

    OnError := 'Erro de Banco de Dados'+sLineBreak+
               'Erro: '+oExc.Errors[0].Message+sLineBreak+
               'Tipo de erro: '+DBExceptionToStr(oExc.Kind)+sLineBreak+
               'Objeto do erro: '+oExc.Errors[0].ObjName+sLineBreak+
               'SQL usado: '+oExc.SQL+sLineBreak+
               'Paramentros: '+OExc.Params.Text+sLineBreak+
               'Componente: '+oExc.FDObjName+sLineBreak+
               'Aplicação: '+FAplication;
    GravaLog(OnError, 'connection');
  end;
end;

function TConnectionPool.CreateNewConnection: TFDConnection;
var
  Conn: TFDConnection;
begin
  Conn := TFDConnection.Create(nil);
  try
    Conn.OnError := FDConexaoError;
    Conn.LoginPrompt := False;
    Conn.Params.DriverID := 'MySQL';
    Conn.Params.Database := FDatabase;
    Conn.Params.UserName := FUsername;
    Conn.Params.Password := FPassword;
    Conn.Params.Add('Server='+FServer);
    Conn.Params.Add('Port='+FPort);
    Conn.Params.Values['AutoReconnect'] := 'True';
    Conn.Connected := True;
    Result := Conn;
  except
    on e: exception do
    begin
      Conn.Free;
      GravaLog('Erro ao se conectar ao banco: '+e.Message, 'connection');
      Result := nil;
    end;
  end;
end;

function TConnectionPool.AcquireConnection: TFDConnection;
const
  TIMEOUT_MS = 3000; // timeout máximo de 3 segundos
var
  Conn: TFDConnection;
  StartTime: Cardinal;
begin
  Result := nil;
  StartTime := TThread.GetTickCount;

  while True do
  begin
    FLock.Acquire;
    try
      // Tenta encontrar conexão livre
      for Conn in FPool do
        if not FInUse[Conn] then
        begin
          FInUse[Conn] := True;
          Exit(Conn);
        end;

      // Cria nova se ainda há espaço
      if FPool.Count < FMaxSize then
      begin
        Conn := CreateNewConnection;
        FPool.Add(Conn);
        FInUse.Add(Conn, True);
        Exit(Conn);
      end;

      // Timeout?
      if TThread.GetTickCount - StartTime >= TIMEOUT_MS then
        raise Exception.Create('Timeout ao tentar adquirir conexão.');

      // Espera por liberação
      TMonitor.Wait(FPool, 100);  // aguarda 100ms antes de nova tentativa
    finally
      FLock.Release;
    end;
  end;
end;

procedure TConnectionPool.ReleaseConnection(AConn: TFDConnection);
begin
  FLock.Acquire;
  try
    if FInUse.ContainsKey(AConn) then
    begin
      FInUse[AConn] := False;
      TMonitor.Pulse(FPool); // avisa quem estiver aguardando
    end;
  finally
    FLock.Release;
  end;
end;

procedure InitConnectionPool(AServer, ADatabase, APort, AUsername, APassword, AAplication: string);
begin
  GlobalConnPool := TConnectionPool.Create(10); // limite de 10 conexões
  GlobalConnPool.LoadParams(AServer, ADatabase, APort, AUsername, APassword, AAplication);
end;

procedure CloseConnectionPool;
begin
  FreeAndNil(GlobalConnPool);
end;

end.
