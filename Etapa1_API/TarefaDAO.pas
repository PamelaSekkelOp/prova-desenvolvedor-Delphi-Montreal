unit TarefaDAO;

interface

uses
  FireDAC.Comp.Client,     // Componentes FireDAC para acesso ao banco
  System.JSON,             // Manipulação de JSON
  FireDAC.DApt,            // Suporte a comandos SQL dinâmicos
  Variants, Data.DB;

type
  // Classe DAO (Data Access Object) para operações CRUD de tarefas
  TTarefaDAO = class
  private
    FConexao: TFDConnection; // Conexão ativa com o banco de dados
  public
    constructor Create(AConexao: TFDConnection);
    function ListarTarefas: TJSONArray;
    procedure InserirTarefa(const JSON: TJSONObject);
    procedure AtualizarStatusTarefa(ID: Integer; const NovoStatus: string);
    procedure RemoverTarefa(ID: Integer);
    function ObterEstatisticas: TJSONObject;
  end;

implementation

uses
  System.SysUtils;

{ TTarefaDAO }

constructor TTarefaDAO.Create(AConexao: TFDConnection);
begin
  // Inicializa DAO com uma conexão ativa recebida via parâmetro
  FConexao := AConexao;
end;

// Lista todas as tarefas do banco e converte para JSON
function TTarefaDAO.ListarTarefas: TJSONArray;
var
  Qry: TFDQuery;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;
    Qry.SQL.Text := 'SELECT * FROM Tarefas';
    Qry.Open;

    while not Qry.Eof do
    begin
      Item := TJSONObject.Create;
      Item.AddPair('ID', TJSONNumber.Create(Qry.FieldByName('ID').AsInteger));
      Item.AddPair('Titulo', Qry.FieldByName('Titulo').AsString);
      Item.AddPair('Descricao', Qry.FieldByName('Descricao').AsString);
      Item.AddPair('Prioridade', TJSONNumber.Create(Qry.FieldByName('Prioridade').AsInteger));
      Item.AddPair('Status', Qry.FieldByName('Status').AsString);
      Item.AddPair('DataCriacao', Qry.FieldByName('DataCriacao').AsString);
      Result.AddElement(Item);
      Qry.Next;
    end;
  finally
    Qry.Free;
  end;
end;

// Insere uma nova tarefa no banco, incluindo DataConclusao se o status for 'Concluída'
procedure TTarefaDAO.InserirTarefa(const JSON: TJSONObject);
var
  Qry: TFDQuery;
  Status: string;
  DataConclusao: Variant;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;

    Status := JSON.GetValue<string>('Status');
    if SameText(Status, 'Concluída') then
      DataConclusao := Now
    else
      DataConclusao := Null;

    Qry.SQL.Text :=
      'INSERT INTO Tarefas (Titulo, Descricao, Prioridade, Status, DataCriacao, DataConclusao) ' +
      'VALUES (:Titulo, :Descricao, :Prioridade, :Status, GETDATE(), :DataConclusao)';

    Qry.ParamByName('Titulo').AsString := JSON.GetValue<string>('Titulo');
    Qry.ParamByName('Descricao').AsString := JSON.GetValue<string>('Descricao');
    Qry.ParamByName('Prioridade').AsInteger := JSON.GetValue<Integer>('Prioridade');
    Qry.ParamByName('Status').AsString := Status;

    Qry.ParamByName('DataConclusao').DataType := ftDateTime;
    Qry.ParamByName('DataConclusao').Value := DataConclusao;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

// Atualiza o status de uma tarefa e registra ou limpa a DataConclusao
procedure TTarefaDAO.AtualizarStatusTarefa(ID: Integer; const NovoStatus: string);
var
  Qry: TFDQuery;
  DataConclusao: Variant;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;

    if SameText(NovoStatus, 'Concluída') then
      DataConclusao := Now
    else
      DataConclusao := Null;

    Qry.SQL.Text :=
      'UPDATE Tarefas SET ' +
      '  Status = :Status, ' +
      '  DataConclusao = :DataConclusao ' +
      'WHERE Id = :Id';

    Qry.ParamByName('Status').AsString := NovoStatus;
    Qry.ParamByName('DataConclusao').DataType := ftDateTime;
    Qry.ParamByName('DataConclusao').Value := DataConclusao;
    Qry.ParamByName('Id').AsInteger := ID;

    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

// Remove uma tarefa pelo ID
procedure TTarefaDAO.RemoverTarefa(ID: Integer);
var
  Qry: TFDQuery;
begin
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;
    Qry.SQL.Text := 'DELETE FROM Tarefas WHERE ID = :ID';
    Qry.ParamByName('ID').AsInteger := ID;
    Qry.ExecSQL;
  finally
    Qry.Free;
  end;
end;

// Retorna estatísticas agregadas (total, média, últimos 7 dias)
function TTarefaDAO.ObterEstatisticas: TJSONObject;
var
  Qry: TFDQuery;
begin
  Result := TJSONObject.Create;
  Qry := TFDQuery.Create(nil);
  try
    Qry.Connection := FConexao;

    // Total de tarefas
    Qry.SQL.Text := 'SELECT COUNT(*) AS Total FROM Tarefas';
    Qry.Open;
    Result.AddPair('TotalTarefas', TJSONNumber.Create(Qry.FieldByName('Total').AsInteger));
    Qry.Close;

    // Média de prioridade das tarefas pendentes
    Qry.SQL.Text := 'SELECT AVG(Prioridade * 1.0) AS MediaPrioridade FROM Tarefas WHERE Status = ''Pendente''';
    Qry.Open;
    Result.AddPair('MediaPrioridadePendentes', TJSONNumber.Create(Qry.FieldByName('MediaPrioridade').AsFloat));
    Qry.Close;

    // Tarefas concluídas nos últimos 7 dias
    Qry.SQL.Text :=
      'SELECT COUNT(*) AS Concluidas7Dias ' +
      'FROM Tarefas ' +
      'WHERE Status = ''Concluída'' AND DataConclusao >= DATEADD(DAY, -7, GETDATE())';
    Qry.Open;
    Result.AddPair('ConcluidasUltimos7Dias', TJSONNumber.Create(Qry.FieldByName('Concluidas7Dias').AsInteger));
  finally
    Qry.Free;
  end;
end;

end.

