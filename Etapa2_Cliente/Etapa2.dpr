program Etapa2;

uses
  Vcl.Forms,
  UPrincipal in 'UPrincipal.pas' {FormPrincipal},
  UCadastroTarefa in 'UCadastroTarefa.pas' {FormCadastroTarefa};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormPrincipal, FormPrincipal);
  Application.CreateForm(TFormCadastroTarefa, FormCadastroTarefa);
  Application.Run;
end.
