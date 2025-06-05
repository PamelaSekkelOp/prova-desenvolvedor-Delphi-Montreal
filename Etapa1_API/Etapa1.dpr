program Etapa1;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse, // Framework de microserviços REST para Delphi
  Horse.Request, Horse.Response, // Manipulação de requisições e respostas HTTP
  uTarefaController in 'uTarefaController.pas', // Controlador responsável pelas rotas de tarefas
  Winapi.ActiveX,
  uIFactoryConexao in 'uIFactoryConexao.pas', // Interface para criação de conexões (padrão Factory)
  TarefaDAO in 'TarefaDAO.pas',               // Objeto responsável por acessar o banco de dados (DAO)
  uTFactoryConexao in 'uTFactoryConexao.pas', // Implementação da Factory de conexão
  FireDAC.Comp.Client; // Componentes FireDAC para conexão com banco SQL Server

// Inicializa o servidor e testa a conexão com o banco de dados
procedure StartServer;
var
  TestConexao: IFactoryConexao;
  Cnx: TFDConnection;
begin
  // Testa conexão com o banco usando o padrão Factory
  TestConexao := TFactoryConexao.Create;
  Cnx := TestConexao.CriarConexao;
  try
    if Cnx.Connected then
      WriteLn('Conexão com o banco Etapa1DB OK!');
  finally
    Cnx.Free;
  end;

  // Define uma rota simples de teste "/ping"
  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('pong'); // Retorna "pong" como resposta
    end
  );

  // Informa que o servidor está pronto
  WriteLn('Servidor rodando em http://localhost:9000/ping');

  // Para futuro uso com HTTPS (SSL)
  // StartSSL(9001, 'cert.pem', 'key.pem');

  // Inicia o servidor na porta 9000
  THorse.Listen(9000);
end;

begin
  try
    // Middleware de segurança: adiciona cabeçalhos HTTP seguros à resposta
    THorse.Use(
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin
        Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
        Res.RawWebResponse.SetCustomHeader('X-Frame-Options', 'DENY');
        Res.RawWebResponse.SetCustomHeader('X-XSS-Protection', '1; mode=block');
        Next();
      end
    );

    // Registra as rotas REST da aplicação (GET, POST, PUT, DELETE de tarefas)
    RegistrarRotas;

    // Inicia o servidor e testa a conexão com o banco
    StartServer;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message); // Exibe erro no console, se ocorrer
  end;
end.

