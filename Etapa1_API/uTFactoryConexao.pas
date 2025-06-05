unit uTFactoryConexao;

interface

uses
  uIFactoryConexao,           // Interface da Factory para padronizar criação de conexões
  FireDAC.Comp.Client,        // Componentes principais do FireDAC
  System.SysUtils;

type
  // Implementação da Factory de conexão com banco de dados usando FireDAC
  TFactoryConexao = class(TInterfacedObject, IFactoryConexao)
  public
    // Método que cria e retorna uma conexão TFDConnection
    function CriarConexao: TFDConnection;
  end;

implementation

uses
  FireDAC.Stan.Def,           // Definições de conexão
  FireDAC.Stan.Async,         // Suporte a operações assíncronas
  FireDAC.Phys,               // Camada física do FireDAC
  FireDAC.Phys.MSSQL,         // Driver para SQL Server
  FireDAC.VCLUI.Wait;         // Componente visual de espera (ex: ao conectar)

function TFactoryConexao.CriarConexao: TFDConnection;
begin
  // Cria instância de TFDConnection sem owner
  Result := TFDConnection.Create(nil);

  // Não solicitará login manual
  Result.LoginPrompt := False;

  // Define o driver como MSSQL (SQL Server)
  Result.Params.DriverID := 'MSSQL';

  // Nome do banco de dados
  Result.Params.Database := 'Etapa1DB';

  // Nome do servidor (localhost para ambiente local)
  Result.Params.Add('Server=localhost');

  // Autenticação via Windows (sem usuário/senha no código)
  Result.Params.Add('OSAuthent=Yes');

  // Abre a conexão
  Result.Connected := True;
end;

end.

