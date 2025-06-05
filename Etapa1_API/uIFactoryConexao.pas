unit uIFactoryConexao;

interface

uses
  FireDAC.Comp.Client;

// Interface para o padrão Factory de criação de conexões com o banco de dados
type
  IFactoryConexao = interface
    // Método abstrato que retorna uma instância de TFDConnection
    function CriarConexao: TFDConnection;
  end;

implementation

end.

