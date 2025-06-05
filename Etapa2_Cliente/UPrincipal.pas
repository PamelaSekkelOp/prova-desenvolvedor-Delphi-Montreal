unit UPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls, REST.Client, REST.Types,
  Data.Bind.Components, Data.Bind.ObjectScope, Vcl.ComCtrls, System.JSON,
  System.ImageList, Vcl.ImgList;

type
  TFormPrincipal = class(TForm)
    GridTarefas: TStringGrid;
    BtnAtualizar: TButton;
    BtnAdicionar: TButton;
    BtnRemover: TButton;
    BtnAtualizarStatus: TButton;
    PanelEstatisticas: TPanel;
    LabelTotal: TLabel;
    LabelMediaPrioridade: TLabel;
    LabelConcluidasSemana: TLabel;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    btnSair: TButton;
    ImageList1: TImageList;
    procedure BtnAtualizarClick(Sender: TObject);
    procedure BtnAdicionarClick(Sender: TObject);
    procedure BtnRemoverClick(Sender: TObject);
    procedure BtnAtualizarStatusClick(Sender: TObject);
    procedure BtnCarregarEstatisticasClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure GridTarefasDrawCell(Sender: TObject; ACol, ARow: LongInt;
      Rect: TRect; State: TGridDrawState);
    procedure btnSairClick(Sender: TObject);
  private
    procedure CarregarTarefas; // Carrega tarefas da API e popula a grid
    procedure CarregarEstatisticas; // Obtém estatísticas da API e exibe
    procedure RemoverTarefa; // Envia DELETE para remover tarefa selecionada
    procedure AtualizarStatusTarefa; // Atualiza o status de uma tarefa via PUT
  public
    { Public declarations }
  end;

var
  FormPrincipal: TFormPrincipal;
  const
  BASE_URL = 'http://localhost:9000';

implementation

{$R *.dfm}

uses UCadastroTarefa;

// Converte código numérico de prioridade para texto compreensível
function PrioridadeParaTexto(Prioridade: string): string;
begin
  case StrToIntDef(Prioridade, 3) of
    1: Result := 'Muito Baixa';
    2: Result := 'Baixa';
    3: Result := 'Média';
    4: Result := 'Alta';
    5: Result := 'Muito Alta';
  else
    Result := 'Desconhecida';
  end;
end;

// Inicializa a tela e carrega dados
procedure TFormPrincipal.FormShow(Sender: TObject);
begin
  // Configura colunas da grid
  GridTarefas.ColCount := 4;
  GridTarefas.RowCount := 1;

  GridTarefas.ColWidths[0] := 60;   // ID
  GridTarefas.ColWidths[1] := 250;  // Descrição
  GridTarefas.ColWidths[2] := 100;  // Status
  GridTarefas.ColWidths[3] := 120;  // Prioridade

  // Cabeçalhos
  GridTarefas.Cells[0, 0] := 'Registro';
  GridTarefas.Cells[1, 0] := 'Descrição';
  GridTarefas.Cells[2, 0] := 'Status';
  GridTarefas.Cells[3, 0] := 'Prioridade';

  CarregarTarefas;
  CarregarEstatisticas;
end;

// Aplica estilo visual para linhas da grid
procedure TFormPrincipal.GridTarefasDrawCell(Sender: TObject; ACol,
  ARow: LongInt; Rect: TRect; State: TGridDrawState);
var
  CorLinha: TColor;
  Texto: string;
begin
  if ARow = 0 then
  begin
    GridTarefas.Canvas.Brush.Color := clBtnFace;
    GridTarefas.Canvas.Font.Style := [fsBold];
  end
  else
  begin
    if ARow mod 2 = 0 then
      CorLinha := clWindow
    else
      CorLinha :=  RGB(220, 235, 250);

    GridTarefas.Canvas.Brush.Color := CorLinha;
    GridTarefas.Canvas.Font.Style := [];
  end;

  GridTarefas.Canvas.FillRect(Rect);
  Texto := GridTarefas.Cells[ACol, ARow];
  GridTarefas.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 2, Texto);
end;

// Botão de atualizar manualmente
procedure TFormPrincipal.BtnAtualizarClick(Sender: TObject);
begin
  CarregarTarefas;
  CarregarEstatisticas;
end;

// Remove tarefa selecionada na grid
procedure TFormPrincipal.RemoverTarefa;
var
  ID: string;
  Row: Integer;
begin
  Row := GridTarefas.Row;
  if Row <= 0 then Exit;

  ID := GridTarefas.Cells[0, Row];
  if MessageDlg('Deseja realmente remover a tarefa ID ' + ID + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    RESTClient.BaseURL := BASE_URL;
    RESTRequest.ResetToDefaults;
    RESTRequest.Resource := 'tarefas/' + ID;
    RESTRequest.Method := rmDELETE;
    try
        RESTRequest.Execute;
        ShowMessage('Tarefa removida com sucesso.');
    except
        on E: Exception do
        ShowMessage('Erro ao remover tarefa: ' + E.Message);
    end;
    CarregarTarefas;
    CarregarEstatisticas;
  end;
end;

// Atualiza o status da tarefa selecionada
procedure TFormPrincipal.AtualizarStatusTarefa;
var
  ID, NovoStatus: string;
  Row: Integer;
  JsonToSend: TJSONObject;
begin
  Row := GridTarefas.Row;
  if Row <= 0 then Exit;

  ID := GridTarefas.Cells[0, Row];
  NovoStatus := InputBox('Atualizar Status', 'Novo status:', 'Concluída');
  if NovoStatus = '' then Exit;

  JsonToSend := TJSONObject.Create;
  JsonToSend.AddPair('Status', quotedstr(NovoStatus));

  RESTClient.BaseURL := BASE_URL;
  RESTRequest.ResetToDefaults;
  RESTRequest.Resource := 'tarefas/' + ID;
  RESTRequest.Method := rmPUT;
  RESTRequest.Params.Clear;
  RESTRequest.AddBody(JsonToSend.ToString, ctAPPLICATION_JSON);

  try
    RESTRequest.Execute;
    ShowMessage('Status atualizado com sucesso!');
  except
    on E: Exception do
      ShowMessage('Erro ao atualizar tarefa: ' + E.Message);
  end;

  CarregarTarefas;
  CarregarEstatisticas;
  JsonToSend.Free;
end;

// Abre o modal de cadastro
procedure TFormPrincipal.BtnAdicionarClick(Sender: TObject);
begin
  Application.CreateForm(TFormCadastroTarefa, FormCadastroTarefa);
  FormCadastroTarefa.Modo := 'adicionar';
  FormCadastroTarefa.TarefaID := '';

  if FormCadastroTarefa.ShowModal = mrOk then
  begin
    CarregarTarefas;
    CarregarEstatisticas;
  end;
end;

procedure TFormPrincipal.BtnRemoverClick(Sender: TObject);
begin
  RemoverTarefa;
end;

procedure TFormPrincipal.btnSairClick(Sender: TObject);
begin
  Close;
end;

procedure TFormPrincipal.BtnCarregarEstatisticasClick(Sender: TObject);
begin
  CarregarEstatisticas;
end;

// Botão que abre o modal para editar o status da tarefa
procedure TFormPrincipal.BtnAtualizarStatusClick(Sender: TObject);
var
  ID: string;
begin
  ID := GridTarefas.Cells[0, GridTarefas.Row];
  if ID = '' then Exit;

  Application.CreateForm(TFormCadastroTarefa, FormCadastroTarefa);
  FormCadastroTarefa.Modo := 'editar-status';
  FormCadastroTarefa.TarefaID := ID;

  if FormCadastroTarefa.ShowModal = mrOk then
  begin
    CarregarTarefas;
    CarregarEstatisticas;
  end;

  FreeAndNil(FormCadastroTarefa);
end;

// Chamada GET para listar tarefas e preencher o grid
procedure TFormPrincipal.CarregarTarefas;
var
  JSONArray: TJSONArray;
  JSONObject: TJSONObject;
  I: Integer;
begin
  RESTClient.BaseURL := BASE_URL;
  RESTRequest.ResetToDefaults;
  RESTRequest.Resource := 'tarefas';
  RESTRequest.Method := rmGET;
  RESTRequest.Params.Clear;
  try
    RESTRequest.Execute;
    JSONArray := TJSONObject.ParseJSONValue(RESTResponse.Content) as TJSONArray;

    if JSONArray = nil then
    begin
      ShowMessage('Não existe tarefa a ser carregada!');
      Exit;
    end;

    GridTarefas.RowCount := JSONArray.Count + 1;

    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONObject := JSONArray.Items[I] as TJSONObject;
      GridTarefas.Cells[0, I + 1] := JSONObject.GetValue('ID').Value;
      GridTarefas.Cells[1, I + 1] := JSONObject.GetValue('Titulo').Value;
      GridTarefas.Cells[2, I + 1] := JSONObject.GetValue('Status').Value;
      GridTarefas.Cells[3, I + 1] := PrioridadeParaTexto(JSONObject.GetValue('Prioridade').Value);
    end;
  except
    on E: Exception do
      ShowMessage('Erro ao carregar tarefas: ' + E.Message);
  end;

  JSONArray.Free;
end;

// Busca estatísticas gerais e atualiza os labels
procedure TFormPrincipal.CarregarEstatisticas;
var
  JSONObject: TJSONObject;
begin
  RESTClient.BaseURL := BASE_URL;
  RESTRequest.ResetToDefaults;
  RESTRequest.Resource := 'estatisticas';
  RESTRequest.Method := rmGET;
  RESTRequest.Params.Clear;
  try
    RESTRequest.Execute;
    JSONObject := TJSONObject.ParseJSONValue(RESTResponse.Content) as TJSONObject;

    if JSONObject = nil then
    begin
      ShowMessage('Erro ao obter estatísticas');
      Exit;
    end;

    LabelTotal.Caption := 'Total de Tarefas: ' + JSONObject.GetValue('TotalTarefas').Value;
    LabelMediaPrioridade.Caption := 'Média Prioridade Pendentes: ' + JSONObject.GetValue('MediaPrioridadePendentes').Value;
    LabelConcluidasSemana.Caption := 'Concluídas Últimos 7 dias: ' + JSONObject.GetValue('ConcluidasUltimos7Dias').Value;
  except
    on E: Exception do
      ShowMessage('Erro ao carregar estatísticas: ' + E.Message);
  end;
  JSONObject.Free;
end;

end.

