# 🔄 TUpdateManager – Componente de Atualização Automática para Aplicações Lazarus

`TUpdateManager` é um componente não-visual para Lazarus/Free Pascal que facilita a verificação, o download e a aplicação de atualizações automáticas em aplicações desktop. Ideal para softwares que precisam manter versões atualizadas com mínimo esforço por parte do usuário final.

---

## ✅ Funcionalidades

- 🔍 Verificação automática de versão via arquivo hospedado (SourceForge)
- 🌐 Download de atualizações com barra de progresso integrada
- 🧾 Download de changelog (arquivo .txt com descrição das mudanças)
- 💬 Mensagens personalizáveis para erros, progresso e confirmação
- 📦 Execução automática do instalador ou atualizador após download

---

## ⚙️ Como Funciona

O componente compara a versão atual (`CurrentVersion`) com o conteúdo do arquivo hospedado (`VersionFileURL`). Se houver nova versão:

1. Exibe uma confirmação (se habilitado)
2. Mostra o progresso do download (se um formulário for atribuído)
3. Salva o arquivo de atualização localmente
4. Executa o arquivo baixado e finaliza o processo atual (opcional)

---

## 📋 Principais Propriedades

| Propriedade visual              | Descrição |
|---------------------------|-----------|
| `VersionFileURL`          | URL do arquivo de versão hospedado |
| `ChangeLogURL`            | URL do changelog (arquivo de texto) |
| `DownloadURL`             | URL do instalador/atualizador |
| `DownloadFileName`        | Nome do arquivo que será salvo localmente |
| `ChangeLogFileName`       | Nome local do changelog |

| Funções e propriedades              | Descrição |
| `CurrentVersion` ou `GetExeVersion`        | Versão atual da aplicação |
| `LatestVersion` ou `GetLatestVersion`          | Versão mais recente da aplicação |
| `CheckForUpdates`  | Verifica se há uma versão mais recente disponível |
| `DownloadNewVersion`  | Inicia o download da versão mais recente | 
| `GetChangeLogFile`  | Baixa o arquivo ChangeLog e exibe |

---

## 🧪 Exemplo de Uso

### Verificar e atualizar
```pascal
var
  lver, cver: String;
begin
  if UpdateManager1.CheckForUpdates then
  begin
    cver := UpdateManager1.CurrentVersion;
    lver := UpdateManager1.LatestVersion;
    if MessageDlg('Atualização disponível',
      'Uma nova atualização de software está disponível.' + #13 +
      'Versão atual: '+cver+#13+
      'Nova versão: '+lver+#13+
      'Deseja baixar a nova atualização?',
      mtConfirmation, [mbYes, mbNo], 0, mbYes) = mrYes
    then
      UpdateManager1.DownloadNewVersion;
  end else
    MessageDlg('Atualização', 'Nenhuma atualização disponível.', mtInformation, [mbOk], 0, mbOk);
```

### Obter changelog

```pascal
  if UpdateManager1.GetChangeLogFile then
    Memo1.Lines.LoadFromFile(UpdateManager1.ChangeLogFileName);
```

## 🖥 Requisitos

- Bibliotecas: `fphttpclient`, `ssl_openssl`
- Compatível com Windows e Linux (modo gráfico)

## 🤝 Contribuições
- Pull requests são bem-vindos! Relate bugs ou sugestões abrindo uma issue.

## ✉️ Contato
- Para dúvidas ou sugestões, entre em contato por [email ou redes sociais].

