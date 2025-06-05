
# Gerenciador de Tarefas - Delphi (Etapa Técnica)

Este projeto foi desenvolvido como parte de uma prova técnica. Ele é composto por duas etapas:

- **Etapa 1**: Um serviço REST desenvolvido com Horse e FireDAC, responsável por cadastrar, listar, atualizar e excluir tarefas, além de fornecer estatísticas.
- **Etapa 2**: Uma aplicação VCL cliente que consome esse serviço via REST.

## 🔧 Requisitos

- Delphi com suporte a FireDAC e REST Client
- SQL Server Local (ou outro adaptável)
- Biblioteca [Horse](https://github.com/HashLoad/horse)
- Horse Middleware opcional: `horse-ssl` (HTTPS)

---

## 🗃️ Estrutura da Tabela `Tarefas`

```sql
CREATE TABLE Tarefas (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Titulo NVARCHAR(255) NOT NULL,
    Descricao NVARCHAR(MAX),
    Prioridade INT NOT NULL,
    Status NVARCHAR(50) NOT NULL,
    DataCriacao DATETIME DEFAULT GETDATE(),
    DataConclusao DATETIME NULL
);
```

---

## ▶️ Executando o Projeto

### 🧩 Etapa 1 – API com Horse

1. Certifique-se de que o banco **Etapa1DB** e a tabela `Tarefas` estão criados.
2. Abra o projeto `Etapa1.dpr`.
3. Compile e execute. A API estará disponível em:  
   `http://localhost:9000/ping`

### Endpoints Disponíveis

| Método | Rota                 | Ação                                |
|--------|----------------------|-------------------------------------|
| GET    | /tarefas             | Lista todas as tarefas              |
| POST   | /tarefas             | Insere uma nova tarefa              |
| PUT    | /tarefas/:id         | Atualiza o status da tarefa         |
| DELETE | /tarefas/:id         | Remove uma tarefa                   |
| GET    | /estatisticas        | Retorna estatísticas das tarefas    |

---

### 🖥️ Etapa 2 – Aplicação Cliente VCL

1. Abra o projeto `Etapa2.dpr`.
2. Execute o sistema.
3. Você poderá:
   - Visualizar tarefas
   - Adicionar tarefas
   - Atualizar status
   - Remover registros
   - Ver estatísticas no painel lateral

---

## 🔒 Segurança

A aplicação utiliza middleware para adicionar cabeçalhos de segurança:

```delphi
THorse.Use(
  procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
  begin
    Res.RawWebResponse.SetCustomHeader('X-Content-Type-Options', 'nosniff');
    Res.RawWebResponse.SetCustomHeader('X-Frame-Options', 'DENY');
    Res.RawWebResponse.SetCustomHeader('X-XSS-Protection', '1; mode=block');
    Next();
  end
);
```

Opcionalmente, o servidor pode ser iniciado com HTTPS usando Horse.SSL (com `cert.pem` e `key.pem`):

```delphi
StartSSL(9001, 'cert.pem', 'key.pem');
```

---

## 💡 Observações

- A conexão com o banco é criada por meio do padrão Factory, facilitando manutenção e testes.
- O código está estruturado com boa separação de responsabilidades entre controle, DAO, e camadas REST.
- A aplicação cliente utiliza `TStringGrid`, com personalização de cores e campos de estatísticas.

---

## 📁 Estrutura de Pastas

```
/Etapa1
  - uTarefaController.pas
  - TarefaDAO.pas
  - uIFactoryConexao.pas
  - uTFactoryConexao.pas

/Etapa2
  - UPrincipal.pas
  - UCadastroTarefa.pas
```

---

## 🚀 Autor

Desenvolvido por Pamela – [projeto técnico em Delphi]
