unit UCadastroTarefa;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.Samples.Spin, REST.Client, REST.Types,
  System.JSON, Data.Bind.Components, Data.Bind.ObjectScope, System.ImageList,
  Vcl.ImgList;

type
  TFormCadastroTarefa = class(TForm)
    LabelTitulo: TLabel;
    EditTitulo: TEdit;
    LabelDescricao: TLabel;
    EditDescricao: TEdit;
    LabelStatus: TLabel;
    ComboStatus: TComboBox;
    LabelPrioridade: TLabel;
    BtnSalvar: TButton;
    BtnCancelar: TButton;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    ComboPrioridade: TComboBox;
    ImageList1: TImageList;
    procedure BtnCancelarClick(Sender: TObject);
    procedure BtnSalvarClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSairClick(Sender: TObject);
  private
    procedure EnviarTarefaParaAPI;
  public
    Modo: string;     // 'novo' ou 'editar-status'
    TarefaID: string; // ID da tarefa (usado para PUT)
  end;

const
  BASE_URL = 'http://localhost:9000';

var
  FormCadastroTarefa: TFormCadastroTarefa;

implementation

{$R *.dfm}

// Fecha o modal sem salvar
procedure TFormCadastroTarefa.BtnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

// Fecha o formulário
procedure TFormCadastroTarefa.btnSairClick(Sender: TObject);
begin
  CLOSE;
end;

// Ao clicar em salvar, envia os dados para a API
procedure TFormCadastroTarefa.BtnSalvarClick(Sender: TObject);
begin
  EnviarTarefaParaAPI;
end;

// Método responsável por montar o JSON e fazer POST ou PUT via REST
procedure TFormCadastroTarefa.EnviarTarefaParaAPI;
var
  JsonToSend: TJSONObject;
  prioridadeValor: string;
begin
  JsonToSend := TJSONObject.Create;
  try
    // Se estiver apenas atualizando o status
    if Modo = 'editar-status' then
    begin
      JsonToSend.AddPair('Status', ComboStatus.Text);

      RESTClient.BaseURL := BASE_URL;
      RESTRequest.ResetToDefaults;
      RESTRequest.Resource := 'tarefas/' + TarefaID;
      RESTRequest.Method := rmPUT;
    end
    else
    begin
      // Cadastro de nova tarefa
      if Trim(EditTitulo.Text) = '' then
      begin
        ShowMessage('Informe o título da tarefa.');
        Exit;
      end;

      // Captura somente o número da prioridade
      prioridadeValor := Copy(ComboPrioridade.Text, 1, Pos(' ', ComboPrioridade.Text) - 1);

      JsonToSend.AddPair('Titulo', EditTitulo.Text);
      JsonToSend.AddPair('Descricao', EditDescricao.Text);
      JsonToSend.AddPair('Prioridade', prioridadeValor);
      JsonToSend.AddPair('Status', ComboStatus.Text);

      RESTClient.BaseURL := BASE_URL;
      RESTRequest.ResetToDefaults;
      RESTRequest.Resource := 'tarefas';
      RESTRequest.Method := rmPOST;
    end;

    // Envia o JSON montado
    RESTRequest.AddBody(JsonToSend.ToString, ctAPPLICATION_JSON);
    try
      RESTRequest.Execute;
      ShowMessage('Tarefa salva com sucesso!');
      ModalResult := mrOk;
    except
      on E: Exception do
        ShowMessage('Erro ao salvar: ' + E.Message);
    end;
  finally
    JsonToSend.Free;
  end;
end;

// Ao abrir o formulário, limpa os campos e ajusta visibilidade de acordo com o modo
procedure TFormCadastroTarefa.FormShow(Sender: TObject);
begin
  EditTitulo.Text := '';
  EditDescricao.Text := '';

  if Modo = 'editar-status' then
  begin
    // Oculta campos desnecessários para edição de status
    LabelTitulo.Visible := False;
    EditTitulo.Visible := False;
    LabelDescricao.Visible := False;
    EditDescricao.Visible := False;
    LabelPrioridade.Visible := False;
    ComboPrioridade.Visible := False;
  end;
end;

end.

