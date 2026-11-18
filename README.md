# Sistema de Avaliação de Melhoria — Produtos Injetados v2.3.0

Sistema leve (HTML + JavaScript, **frontend-only**) para avaliar oportunidades de melhoria em peças de injeção de plástico, com leitura automática de **PDF** (via **pdf.js**) e de **imagem JPG/PNG** (via **OCR - Tesseract.js**), com base nas regras dos guias **Bayer Thermoplastics Part & Mold Design**, **Xometry Design Guidelines**, **IIT Bombay/dsource** e **Boothroyd/Dewhurst/Knight DFMA**.

## Arquivos do projeto

| Arquivo | Descrição |
|---------|-----------|
| `index.html` | Sistema frontend v2.3.0 — leitura PDF + imagem (OCR), avaliação automática, **normas elétricas (tomadas/interruptores/instalações)**, relatório e exportação. |
| `schema_banco_dados.sql` | Banco de dados MySQL/MariaDB com regras consolidadas (Boothroyd + Bayer + Xometry + IIT). Tabelas `*_bayer`, `*_xometry`, `*_iit`, `*_fictiv` etc. |
| `libs/` | **Bibliotecas locais** (pdf.js v3.11.174, Tesseract.js v5.1.1, core WASM e dicionário PORTuguês). Não depende de internet/CDN. |
| `README.md` | Este arquivo. |
| `PASSO_A_PASSO_GITHUB.md` | Passo a passo detalhado para subir no GitHub e hospedar via GitHub Pages. |

> **Importante:** as bibliotecas ficam na pasta `libs/` e são carregadas localmente pelo `index.html` (`<script src="libs/pdf.min.js">`). Ao enviar para o GitHub, **envie também a pasta `libs/` inteira** (são ~15 MB). Assim o sistema funciona em qualquer rede, mesmo sem acesso a CDNs externos. Corrigido em 18/11/2026.

---

## 1. O que o sistema faz (v2.1.0)

| Etapa | O que ocorre |
|-------|--------------|
| **1. Envio de arquivo** | O usuário envia **PDF** (vetorial ou com texto) ou **imagem JPG/PNG** do desenho técnico. |
| **2. Leitura automática** | PDF → **pdf.js** extrai texto embutido. Imagem → **Tesseract.js (OCR)** roda direto no navegador e extrai texto/cotas. |
| **3. Extração de dados** | Regex identifica cotas no formato `valor ± tolerância` (ex: `121,0 ± 0,20`), raios (`R230,0 ± 0,20`), material (ABS, PP, PC, PA…) e revisão. |
| **4. Avaliação automática** | Compara espessura de parede, draft, ribs, bosses, undercuts, gate, tolerâncias e força de fechamento contra as tabelas de conhecimento embutidas (Bayer/Xometry). Gera alertas críticos, avisos e sugestões de melhoria com cálculo. |
| **5. Relatório** | Exibe KPIs na tela e permite exportar `.txt` com o diagnóstico completo. |
| **6. Simulação** | Botão "Modo Simulação" carrega dados padrão da linha Dunas/Romazi_A2 para testar sem arquivo. |

> **Importante sobre leitura de desenhos:** PDFs exportados do CAD geralmente são **vetoriais** (cotas são linhas, não texto). O pdf.js não lê isso; o Tesseract.js (OCR) tenta reconhecer a imagem, mas a precisão depende da qualidade/nítideza do desenho. Para leitura 100% automática de cotas vetoriais/GD&T seria necessário backend com OCR avançado ou integração CAD. Enquanto isso, o **Modo Simulação** permite testar o fluxo completo.

---

## 2. Banco de dados (`schema_banco_dados.sql)

O script SQL cria o banco `db_engenharia_injecao` (utf8mb4) com as tabelas principais e as tabelas de conhecimento consolidadas:

- `versoes_sistema` — controle de releases (v1.0.0, v1.1.0, v1.2.0 …)
- `usuários` — engenheiros, projetistas, analistas de custo
- `conhecimento_engenharia` — fórmulas, regras e tabelas técnicas
- `regras_dfma` — critérios Boothroyd/Dewhurst/Knight
- `moldes_injecao`, `defeitos_injecao`, `desenhos_avaliados`, `avaliacoes_melhoria`, `pecas_injetadas`, `melhorias_implementadas`
- Tabelas **Bayer** (`materiais_bayer`, `regras_espessura_parede_bayer`, `regras_costelas_bayer`, `regras_bosses_bayer`, `regras_draft_bayer`, `regras_ventos_bayer`, `regras_gates_bayer`, `regras_resfriamento_bayer`, `formulas_estruturais_bayer`, `aco_moldes_bayer`, etc.)
- Tabelas **Xometry** (`materiais_xometry`, `acabamentos_superficie_xometry`, `regras_projeto_xometry`, `defeitos_injecao_xometry`, `regras_overmolding_xometry`, `padroes_xometry`)
- Tabelas **IIT/Fictiv** (materiais de resina, regras de parede, fluxo, gates, draft, ribs, bosses, etc.)

Você pode importar esse SQL no **MySQL**, **MariaDB** ou adaptar para **PostgreSQL/SQL Server**.

> O `index.html` atual é **estático**: roda no navegador e não grava no SQL. Para persistir avaliações de verdade, conecte o frontend a uma API (Node.js/Express, Python/FastAPI, PHP) que salve no banco.

---

## 3. Como usar o sistema HTML

1. Abra o `index.html` em qualquer navegador moderno (Chrome, Edge, Firefox).
2. Na aba **Upload de Arquivo**, selecione o PDF ou imagem (JPG/PNG) do desenho.
3. Clique em **Processar e Avaliar**.
   - Se for PDF com texto: o pdf.js extrai automaticamente.
   - Se for imagem/PDF vetorial: o Tesseract.js faz OCR na imagem (pode levar alguns segundos).
4. Revise o **Texto extraído**. O sistema já detecta material, cotas e revisão.
5. Na aba **Resultado / Relatório**, veja os alertas automáticos e sugestões de melhoria com cálculo.
6. Clique em **Exportar relatório (.txt)** para salvar o diagnóstico.
7. Use a aba **Modo Simulação** para testar com dados padrão da linha Dunas/Romazi_A2 sem precisar de arquivo.
8. Na aba **Normas Elétricas**, escolha o tipo de produto (Tomada/Interruptor) e a corrente (10/16/20 A), e clique em **Aplicar Normas ao Desenho** para verificar conformidade com NBR 14136 / IEC 60884 / NBR NM 60669-1 / IEC 60669-1.

O sistema funciona **offline** (bibliotecas na pasta `libs/`). Para acessar de qualquer lugar sem instalar nada, hospede via **GitHub Pages** (veja `PASSO_A_PASSO_GITHUB.md`).

### 3.1 Normas elétricas aplicadas (v2.2.0)

| Norma | Produto | Principais verificações no desenho |
|-------|---------|------------------------------------|
| **ABNT NBR 14136** | Tomadas e plugues 2P+T | Ø do pino 4,0 mm (10 A) / 4,8 mm (20 A) ±0,05; espaçamento 19 ±0,2 mm; ângulo 90°; pino terra; marcações 10/20 A, 250 V~; compatibilidade 20 A aceita 10 A (não o contrário). |
| **IEC 60884-1** | Tomadas/Plugues | Pinos 4,8 mm, espaçamento 19 mm; durabilidade 5.000 inserções/10.000 cursos; grau IP. |
| **ABNT NBR NM 60669-1 / IEC 60669-1** | Interruptores | Correntes 10A/10AX/16A/16AX; tensão até 440 V; durabilidade 40.000 operações (≤16 A); graus IP20/IP40/IP44/IP54/IP55; marcações obrigatórias. |
| **ABNT NBR 5410** | Instalações elétricas (≤1000 V CA) | Aterramento PE obrigatório; DR 30 mA em áreas úmidas/externas; bitolas mínimas (iluminação 1,5 mm², tomadas 2,5 mm², comando 0,5 mm²); esquemas TT/TN/IT; BEP; DPS; separação de circuitos; ampacidade I_z ≥ I_b; verificação final (sec.7). |
| Materiais (todos) | Isolamento | Termoplástico autoextinguível 850 °C; UL 94 V-0/V-1; aterramento obrigatório. |

> **Aviso:** valores extraídos de fontes públicas (ABNT, catálogos de fabricantes, relatórios de ensaio IEC). Confirme sempre na norma oficial antes de uso crítico.

O `schema_banco_dados.sql` v1.4.0 contém as tabelas `normas_eletricas`, `regras_dimensao_norma`, `regras_material_norma`, `regras_marcacao_norma` e `regras_instalacao_nbr5410` (17 regras de instalação) com esses dados.

---

## 4. Limitações conhecidas

- **PDF vetorial (CAD):** cotas como linhas/vetores não são texto. O OCR de imagem pode falhar se o desenho tiver pouca resolução ou muitas linhas cruzadas.
- **GD&T / símbolos de tolerância geométrica:** exigem OCR + visão computacional para leitura confiável.
- **Sem backend:** não salva automaticamente no banco SQL. É necessário preencher/revisar manualmente ou construir a API de conexão.

---

## 5. Vantagem do GitHub + GitHub Pages

- Controle de versão (Git), backup na nuvem, branches, releases/tags.
- **GitHub Pages:** hospede o `index.html` gratuitamente e acesse de qualquer navegador via URL (`seuusuario.github.io/sistema-avaliacao-injetado`).
- Issues/Projects para registrar melhorias (ex: "backend MySQL", "OCR avançado", "CAD integration").

---

## 6. Bibliotecas usadas (via CDN, nada para instalar)

- **mozilla/pdf.js** (v4.8.69) — leitura de PDF no navegador.
- **Tesseract.js** (v5) — OCR de imagens no navegador.
- CSS/JS puro (sem frameworks).

---

## 7. Próximos passos sugeridos

1. Subir o projeto para o GitHub (veja `PASSO_A_PASSO_GITHUB.md`).
2. Ativar **GitHub Pages** para acessar de qualquer lugar.
3. Construir uma API simples (Node.js/Express ou PHP) que conecte o `index.html` ao MySQL (`schema_banco_dados.sql`) para salvar avaliações.
4. Para leitura avançada de cotas vetoriais, avaliar backend com **OCR (Tesseract server)** ou serviços de visão computacional.

---

**Versão do sistema:** 2.1.0  
**Referências técnicas:**  
- Boothroyd, Dewhurst & Knight — *Product Design for Manufacture and Assembly*  
- Bayer Corporation — *Thermoplastics: Part and Mold Design* (KU-GE028)  
- Xometry — *Design Guidelines and Best Practices for Injection Molding*  
- IIT Bombay / dsource.in — Curso de Design de Injeção de Plástico
