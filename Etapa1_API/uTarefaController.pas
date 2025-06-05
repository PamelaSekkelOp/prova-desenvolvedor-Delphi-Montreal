unit uTarefaController;

interface

uses
  Horse,                             // Framework REST
  System.JSON,                       // Manipulação de JSON
  uIFactoryConexao, uTFactoryConexao, // Padrão Factory para conexão com o banco
  TarefaDAO,                         // Objeto de acesso a dados (DAO)
  FireDAC.Comp.Client,
  System.SysUtils;

// Procedimento que registra todas as rotas REST da aplicação
procedure RegistrarRotas;

implementation

// Rota GET /tarefas - Retorna lista de todas as tarefas
procedure GetTarefas(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Factory: IFactoryConexao;
  Conexao: TFDConnection;
  DAO: TTarefaDAO;
  Lista: TJSONArray;
begin
  // Cria conexão com o banco via Factory
  Factory := TFactoryConexao.Create;
  Conexao := Factory.CriarConexao;
  DAO := TTarefaDAO.Create(Conexao);
  try
    // Chama método DAO para obter lista de tarefas
    Lista := DAO.ListarTarefas;
    Res.Send(Lista.ToString); // Envia resposta como JSON
    Lista.Free;
  finally
    DAO.Free;
    Conexao.Free;
  end;
end;

// Rota POST /tarefas - Insere uma nova tarefa
procedure PostTarefa(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Factory: IFactoryConexao;
  Conexao: TFDConnection;
  DAO: TTarefaDAO;
  JSON: TJSONObject;
begin
  // Converte corpo da requisição para JSON
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  if not Assigned(JSON) then
  begin
    Res.Status(400).Send('JSON inválido');
    Exit;
  end;

  // Conexão com banco e inserção via DAO
  Factory := TFactoryConexao.Create;
  Conexao := Factory.CriarConexao;
  DAO := TTarefaDAO.Create(Conexao);
  try
    DAO.InserirTarefa(JSON);
    Res.Status(201).Send('Tarefa inserida com sucesso!');
  finally
    DAO.Free;
    Conexao.Free;
    JSON.Free;
  end;
end;

// Rota PUT /tarefas/:id - Atualiza o status de uma tarefa
procedure PutTarefa(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  ID: Integer;
  NovoStatus: string;
  Factory: IFactoryConexao;
  Conexao: TFDConnection;
  DAO: TTarefaDAO;
  JSON: TJSONObject;
begin
  // Recupera ID da tarefa da URL
  ID := StrToIntDef(Req.Params['id'], 0);
  if ID = 0 then
  begin
    Res.Status(400).Send('ID inválido');
    Exit;
  end;

  // Converte corpo da requisição para JSON
  JSON := TJSONObject.ParseJSONValue(Req.Body) as TJSONObject;
  if not Assigned(JSON) then
  begin
    Res.Status(400).Send('JSON inválido');
    Exit;
  end;

  // Extrai novo status
  NovoStatus := JSON.GetValue<string>('Status');

  // Atualiza no banco
  Factory := TFactoryConexao.Create;
  Conexao := Factory.CriarConexao;
  DAO := TTarefaDAO.Create(Conexao);
  try
    DAO.AtualizarStatusTarefa(ID, NovoStatus);
    Res.Send('Status atualizado com sucesso!');
  finally
    DAO.Free;
    Conexao.Free;
    JSON.Free;
  end;
end;

// Rota DELETE /tarefas/:id - Remove uma tarefa
procedure DeleteTarefa(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  ID: Integer;
  Factory: IFactoryConexao;
  Conexao: TFDConnection;
  DAO: TTarefaDAO;
begin
  // Lê o ID da URL
  ID := StrToIntDef(Req.Params['id'], 0);
  if ID = 0 then
  begin
    Res.Status(400).Send('ID inválido');
    Exit;
  end;

  // Remove a tarefa via DAO
  Factory := TFactoryConexao.Create;
  Conexao := Factory.CriarConexao;
  DAO := TTarefaDAO.Create(Conexao);
  try
    DAO.RemoverTarefa(ID);
    Res.Send('Tarefa removida com sucesso!');
  finally
    DAO.Free;
    Conexao.Free;
  end;
end;

// Rota GET /estatisticas - Retorna estatísticas (total, média, últimos 7 dias)
procedure GetEstatisticas(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Factory: IFactoryConexao;
  Conexao: TFDConnection;
  DAO: TTarefaDAO;
  Estatisticas: TJSONObject;
begin
  // Recupera estatísticas agregadas via DAO
  Factory := TFactoryConexao.Create;
  Conexao := Factory.CriarConexao;
  DAO := TTarefaDAO.Create(Conexao);
  try
    Estatisticas := DAO.ObterEstatisticas;
    Res.Send(Estatisticas.ToString);
    Estatisticas.Free;
  finally
    DAO.Free;
    Conexao.Free;
  end;
end;

// Registra as rotas REST no servidor Horse
procedure RegistrarRotas;
begin
  THorse.Get('/tarefas', GetTarefas);            // Lista todas as tarefas
  THorse.Post('/tarefas', PostTarefa);           // Cria nova tarefa
  THorse.Put('/tarefas/:id', PutTarefa);         // Atualiza status de tarefa
  THorse.Delete('/tarefas/:id', DeleteTarefa);   // Remove tarefa
  THorse.Get('/estatisticas', GetEstatisticas);  // Consulta estatísticas SQL
end;

end.

