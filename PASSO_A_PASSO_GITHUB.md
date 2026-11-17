# Passo a passo — Subir o projeto no GitHub e hospedar no GitHub Pages

Este guia ensina a publicar o **Sistema de Avaliação de Melhoria — Produtos Injetados** para que qualquer pessoa possa acessar pelo navegador, sem precisar instalar nada.  
Foi escrito para quem já tem conta no GitHub.

O projeto é **frontend-only** (HTML + JS puro), então funciona perfeitamente no **GitHub Pages** (hospedagem gratuita e estática).

---

## Pré-requisitos

- Conta no GitHub (https://github.com) criada e com acesso confirmado.
- Navegador web (Chrome, Edge, Firefox).
- Opcional: **Git** instalado no computador (https://git-scm.com). Se não quiser instalar o Git, use a alternativa "Upload direto pelo site" (Passo A, opção 2).

Arquivos que já estão na pasta do projeto:

- `index.html` — sistema v2.1.0 (PDF + OCR de imagem + avaliação automática).
- `schema_banco_dados.sql` — banco de conhecimento SQL (Bayer + Xometry + IIT + Boothroyd).
- `README.md` — documentação.
- `PASSO_A_PASSO_GITHUB.md` — este arquivo.

---

## Passo A — Criar o repositório e enviar os arquivos

### Opção 1: Usando Git (recomendado se você já tem Git instalado)

Abra o terminal (PowerShell ou Prompt de Comando) na pasta do projeto:

```powershell
# 1. Inicializa o repositório local (se ainda não for um repo Git)
git init

# 2. Adiciona todos os arquivos
git add .

# 3. Faz o primeiro commit
git commit -m "v2.1.0 - Sistema avaliador injetado com OCR de imagem e PDF"

# 4. Crie um repositório vazio no GitHub (não inicialize com README)
#    Acesse: https://github.com/new
#    Nome sugerido: sistema-avaliacao-injetado
#    Deixe público ou privado, conforme preferir.

# 5. Liga o repositório local ao remoto (substitua SEU_USUARIO e NOME_DO_REPO)
git remote add origin https://github.com/SEU_USUARIO/NOME_DO_REPO.git

# 6. Renomeia a branch principal para main (padrão do GitHub)
git branch -M main

# 7. Envia para o GitHub
git push -u origin main
```

### Opção 2: Upload direto pelo site do GitHub (sem instalar Git)

1. Acesse https://github.com e faça login.
2. Clique no ícone **+** (canto superior direito) → **New repository**.
3. Nome do repositório: `sistema-avaliacao-injetado` (ou o nome que preferir).
4. Descrição: `Sistema de avaliação automática de melhoria para produtos de injeção de plástico (PDF + OCR imagem)`.
5. Escolha **Público** (necessário para GitHub Pages gratuito) ou **Privado** (Pages disponível em planos pagos).
6. **Não** marque "Add a README file" (nós já temos os nossos).
7. Clique em **Create repository**.
8. Na próxima tela, clique em **uploading an existing file**.
9. Arraste os 4 arquivos (`index.html`, `schema_banco_dados.sql`, `README.md`, `PASSO_A_PASSO_GITHUB.md`) para a área de upload.
10. Digite um commit message, exemplo: `v2.1.0 - Sistema avaliador com OCR de imagem`.
11. Clique em **Commit changes**.

---

## Passo B — Ativar o GitHub Pages (hospedagem gratuita)

1. No seu repositório no GitHub, clique na aba **Settings** (Configurações).
2. No menu esquerdo, clique em **Pages**.
3. Em **Build and deployment > Source**, selecione:
   - **Branch:** `main` (ou `master`, se for o nome da sua branch).
   - **Pasta:** `/ (root)`.
4. Clique em **Save**.
5. Aguarde cerca de 1–2 minutos. O GitHub vai exibir uma mensagem como:
   > Your site is live at `https://SEU_USUARIO.github.io/sistema-avaliacao-injetado/`

Esse é o endereço que você pode acessar de qualquer computador, celular ou tablet.

> **Dica:** se a página não carregar na primeira vez, aguarde um pouco e recarregue o navegador. O GitHub Pages pode demorar uns minutos na primeira publicação.

---

## Passo C — Rotina de trabalho diária (atualizar o sistema)

Se você fizer melhorias no `index.html` ou no SQL e quiser publicar:

### Usando Git
```powershell
git add .
git commit -m "Descrição da alteração"
git push origin main
```
O GitHub Pages atualiza automaticamente em até 1 minuto.

### Usando o site do GitHub
1. Acesse o repositório no github.com.
2. Clique no arquivo que quer alterar (ex: `index.html`).
3. Clique no ícone de lápis (✏️) para editar, ou clique em **Add file → Upload files** para substituir.
4. Faça as alterações, digite o commit message e clique em **Commit changes**.
5. O GitHub Pages republica automaticamente.

---

## Passo D — Trabalhar com branches e tags (controle de versão)

### Criar uma branch para uma nova funcionalidade
```powershell
git checkout -b nova-funcionalidade-ocr
# faça suas alterações nos arquivos
git add .
git commit -m "Melhora no OCR de imagem"
git push origin nova-funcionalidade-ocr
```
Depois, no GitHub, abra um **Pull Request** para mesclar essa branch na `main`.

### Criar uma tag de release (versão oficial)
```powershell
git tag v2.1.0
git push origin v2.1.0
```
No GitHub, acesse **Releases → Draft a new release**, selecione a tag `v2.1.0`, escreva notas do release e publique. Isso gera um histórico oficial de versões.

---

## Passo E — Testar o sistema após subir no GitHub Pages

1. Abra o navegador e acesse:  
   `https://SEU_USUARIO.github.io/NOME_DO_REPO/index.html`
2. Você deve ver o cabeçalho "Sistema de Avaliação de Melhoria - Produtos Injetados v2.1.0".
3. Teste as duas formas de leitura:
   - **Upload de PDF ou imagem:** envie um desenho e clique em "Processar e Avaliar".
   - **Modo Simulação:** clique na aba correspondente e carregue os dados padrão Dunas/Romazi_A2.
4. Na aba **Resultado / Relatório**, confirme que aparecem alertas e sugestões automáticas.
5. Clique em **Exportar relatório (.txt)** e verifique se o arquivo baixa corretamente.

> **Nota importante:** o GitHub Pages serve arquivos via HTTPS, então o pdf.js e o Tesseract.js (carregados de CDN) funcionam normalmente. Se você abrir o `index.html` diretamente pelo navegador usando `file://` (duplo clique no arquivo), o pdf.js será bloqueado pelo navegador. Por isso o GitHub Pages é a forma recomendada de usar o sistema em qualquer lugar.

---

## Passo F — Conectar ao banco de dados MySQL (próximo passo)

O `index.html` atual é estático: não grava no SQL automaticamente. Para persistir as avaliações no banco (`schema_banco_dados.sql`), você precisará de um backend simples. Opções:

- **Node.js + Express** + `mysql2` — roda em qualquer servidor ou no Render/Railway/Heroku.
- **PHP + MySQL** — hospedagem compartilhada barata.
- **Python + FastAPI/Flask** + `mysql-connector-python`.

O fluxo seria: o `index.html` envia os dados extraídos (via `fetch`) para a API, e a API insere nas tabelas `desenhos_avaliados` e `avaliacoes_melhoria` do banco SQL.

Se quiser, posso criar esse backend para você em um próximo passo.

---

## Resumo rápido de comandos Git

| Ação | Comando |
|------|---------|
| Ver status | `git status` |
| Adicionar tudo | `git add .` |
| Commit | `git commit -m "mensagem"` |
| Enviar | `git push origin main` |
| Baixar atualizações | `git pull origin main` |
| Criar tag | `git tag vX.Y.Z` |
| Enviar tag | `git push origin vX.Y.Z` |

---

## Dicas finais

- Mantenha os 4 arquivos na **raiz** do repositório para o GitHub Pages encontrar o `index.html` automaticamente.
- Se mudar o nome do repositório, atualize o link nas configurações do Pages.
- Use **Issues** no GitHub para anotar melhorias futuras (ex: "adicionar backend MySQL", "OCR avançado para cotas vetoriais").
- O banco SQL (`schema_banco_dados.sql`) pode ser importado em qualquer MySQL/MariaDB local ou em nuvem (AWS RDS, Azure MySQL, etc.) quando você estiver pronto para persistir dados.

---

**Versão do guia:** 1.0  
**Data:** 17/11/2026  
**Projeto:** Sistema de Avaliação de Melhoria — Produtos Injetados v2.1.0
