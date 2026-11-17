-- ============================================================================
-- BANCO DE DADOS: Engenharia, Desenvolvimento, Projetos e Design
-- Foco: Moldes de Injeção de Plástico e Produtos Injetados
-- Referência principal: Product Design for Manufacture and Assembly
--             (Boothroyd, Dewhurst e Knight)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS db_engenharia_injecao
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE db_engenharia_injecao;

-- ----------------------------------------------------------------------------
-- Tabela de versões do sistema (controle de release)
-- ----------------------------------------------------------------------------
CREATE TABLE versoes_sistema (
    id INT AUTO_INCREMENT PRIMARY KEY,
    versao VARCHAR(20) NOT NULL,           -- ex: 1.0.0
    data_lancamento DATE NOT NULL,
    descricao TEXT,
    arquivo_download VARCHAR(255),          -- link do GitHub Release
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Usuários do sistema (engenheiros, projetistas, analistas de custo)
-- ----------------------------------------------------------------------------
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    papel ENUM('analista','projetista','engenheiro','gerente','admin') DEFAULT 'analista',
    departamento VARCHAR(100),
    senha_hash VARCHAR(255) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Repositório de conhecimento de engenharia (fórmulas, regras, tabelas)
-- ----------------------------------------------------------------------------
CREATE TABLE conhecimento_engenharia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria ENUM('DFMA','Injecao_Plastico','Moldes','Materiais','Custo','Qualidade','Desenho_Tecnico') NOT NULL,
    subcategoria VARCHAR(100),
    codigo VARCHAR(50) UNIQUE,             -- ex: DFMA-001, INJ-010
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT,
    formula TEXT,                          -- fórmula em texto ou LaTeX
    unidade_medida VARCHAR(50),
    valor_referencia DECIMAL(15,4),
    pagina_livro INT,                      -- referência ao livro Boothroyd et al.
    capitulo_livro VARCHAR(100),
    referencia_bibliografica VARCHAR(255),
    criado_por INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (criado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Regras DFMA (Design for Manufacture and Assembly) - Boothroyd, Dewhurst, Knight
-- ----------------------------------------------------------------------------
CREATE TABLE regras_dfma (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo ENUM('DFA','DFM') NOT NULL,       -- DFA = Montagem, DFM = Fabricação
    criterio VARCHAR(200) NOT NULL,
    descricao TEXT,
    pergunta_avaliacao TEXT,               -- pergunta feita ao engenheiro
    pontuacao_peso DECIMAL(5,2) DEFAULT 1.0,
    referencia_pagina INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Dados técnicos de moldes de injeção
-- ----------------------------------------------------------------------------
CREATE TABLE moldes_injecao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_molde ENUM('Termoplastico','Termofixo','Elastomer','Bicor','Insercao') DEFAULT 'Termoplastico',
    classe_molde VARCHAR(20),              -- ex: Classe 101, 102, 103 (ABIMAPI/ABINIT)
    aco_molde VARCHAR(50),                 -- ex: P20, H13, NAK80, AISI 420
    numero_cavidades INT DEFAULT 1,
    tipo_canal_enxer VARCHAR(50),          -- ex: Frio, Quente
    tipo_gate VARCHAR(50),                 -- ex: Ponto, Casulo, Borda, Submarino, Valvula
    draft_angle_min DECIMAL(5,2),          -- ângulo de rascunho mínimo (graus)
    espessura_parede_min DECIMAL(7,3),     -- mm
    espessura_parede_max DECIMAL(7,3),     -- mm
    raio_minimo DECIMAL(7,3),              -- mm
    encolhimento_volumetrico DECIMAL(6,4), -- %
    temperatura_molde_min INT,             -- °C
    temperatura_molde_max INT,             -- °C
    pressao_injecao_max DECIMAL(7,2),      -- bar/MPa
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Catálogo de defeitos comuns em injeção e ações corretivas
-- ----------------------------------------------------------------------------
CREATE TABLE defeitos_injecao (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,            -- ex: Marca de retração, Rebarba, Linha de solda
    descricao TEXT,
    causas_provaveis TEXT,
    acoes_corretivas TEXT,
    parametro_processo_afetado VARCHAR(100), -- ex: Pressão, Temperatura, Tempo de resfriamento
    gravidade ENUM('Baixa','Media','Alta','Critica') DEFAULT 'Media',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Desenhos técnicos enviados (PDF) para avaliação
-- ----------------------------------------------------------------------------
CREATE TABLE desenhos_avaliados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    numero_peca VARCHAR(100) NOT NULL,
    revisao VARCHAR(20),
    nome_arquivo VARCHAR(255) NOT NULL,
    caminho_arquivo VARCHAR(500),          -- caminho no servidor/nuvem
    texto_extraido LONGTEXT,               -- texto lido do PDF via pdf.js / OCR
    paginas INT,
    data_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    enviado_por INT,
    status ENUM('Recebido','Em_Avaliacao','Avaliado','Rejeitado') DEFAULT 'Recebido',
    observacoes TEXT,
    FOREIGN KEY (enviado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Avaliações de melhoria (resultado do sistema)
-- ----------------------------------------------------------------------------
CREATE TABLE avaliacoes_melhoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    desenho_id INT NOT NULL,
    criterio_dfma_id INT,
    nota_criterio DECIMAL(5,2),            -- nota de 0 a 10
    indice_eficiencia_montagem DECIMAL(5,2),-- % (método Boothroyd)
    numero_pecas_atual INT,
    numero_pecas_proposto INT,
    tempo_montagem_atual DECIMAL(10,2),    -- segundos
    tempo_montagem_proposto DECIMAL(10,2),
    custo_peca_atual DECIMAL(15,4),
    custo_peca_proposto DECIMAL(15,4),
    economia_estimada DECIMAL(15,4),
    sugestao_melhoria TEXT,
    acao_recomendada TEXT,
    prioridade ENUM('Baixa','Media','Alta','Critica') DEFAULT 'Media',
    avaliado_por INT,
    data_avaliacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (desenho_id) REFERENCES desenhos_avaliados(id),
    FOREIGN KEY (criterio_dfma_id) REFERENCES regras_dfma(id),
    FOREIGN KEY (avaliado_por) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Dados da peça injetada (para cálculo de custo e molde)
-- ----------------------------------------------------------------------------
CREATE TABLE pecas_injetadas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    desenho_id INT NOT NULL,
    material VARCHAR(100),                 -- ex: ABS, PP, PC, PA66-GF30
    densidade DECIMAL(7,4),                -- g/cm3
    peso_peca DECIMAL(9,4),                -- gramas
    volume_peca DECIMAL(9,4),              -- cm3
    area_projetada DECIMAL(10,4),          -- cm2 (para força de fechamento)
    numero_cavidades INT DEFAULT 1,
    tempo_injecao DECIMAL(7,2),            -- segundos
    tempo_resfriamento DECIMAL(7,2),       -- segundos
    tempo_ciclo_total DECIMAL(7,2),        -- segundos
    forca_fechamento_estimada DECIMAL(10,2),-- toneladas
    pressao_cavidade DECIMAL(7,2),         -- bar
    custo_material_kg DECIMAL(10,4),
    custo_ciclo_hora DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (desenho_id) REFERENCES desenhos_avaliados(id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- Histórico de melhorias implementadas (fechamento do ciclo PDCA)
-- ----------------------------------------------------------------------------
CREATE TABLE melhorias_implementadas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    avaliacao_id INT NOT NULL,
    descricao_implementacao TEXT,
    data_implementacao DATE,
    responsavel INT,
    economia_realizada DECIMAL(15,4),
    validacao_qualidade BOOLEAN DEFAULT FALSE,
    observacoes TEXT,
    FOREIGN KEY (avaliacao_id) REFERENCES avaliacoes_melhoria(id),
    FOREIGN KEY (responsavel) REFERENCES usuarios(id)
) ENGINE=InnoDB;

-- Índices úteis para consultas frequentes
CREATE INDEX idx_conhecimento_categoria ON conhecimento_engenharia(categoria);
CREATE INDEX idx_regras_dfma_tipo ON regras_dfma(tipo);
CREATE INDEX idx_desenho_status ON desenhos_avaliados(status);
CREATE INDEX idx_avaliacao_desenho ON avaliacoes_melhoria(desenho_id);
CREATE INDEX idx_peca_material ON pecas_injetadas(material);

-- Exemplo de inserção de regras DFMA essenciais (Boothroyd, Dewhurst & Knight)
INSERT INTO regras_dfma (tipo, criterio, descricao, pergunta_avaliacao, pontuacao_peso, referencia_pagina) VALUES
('DFA', 'Peça mínima - Movimento relativo', 'A peça se move em relação a todas as outras peças já montadas?', 'A peça tem movimento relativo às peças adjacentes?', 1.0, NULL),
('DFA', 'Peça mínima - Material diferente', 'A peça precisa ser de material diferente das outras?', 'Exige material diferente (isolamento, vedação, etc.)?', 1.0, NULL),
('DFA', 'Peça mínima - Separação para manutenção', 'A peça deve ser separada para manutenção ou ajuste?', 'Precisa ser removível para manutenção?', 1.0, NULL),
('DFM', 'Ângulo de rascunho (Draft)', 'Superfícies paralelas à direção de abertura do molde precisam de rascunho.', 'O draft atende ao mínimo para o material?', 1.0, NULL),
('DFM', 'Espessura de parede', 'Espessura uniforme evita marcas de retração e empenamento.', 'Espessura está entre min e max recomendados?', 1.0, NULL),
('DFM', 'Raio em cantos', 'Cantos vivos concentram tensão e dificultam o escoamento.', 'Cantos têm raio mínimo adequado?', 1.0, NULL);

-- Exemplo de conhecimentos de injeção
INSERT INTO conhecimento_engenharia (categoria, subcategoria, codigo, titulo, descricao, formula, unidade_medida, referencia_bibliografica) VALUES
('Injecao_Plastico', 'Forca de fechamento', 'INJ-001', 'Força de fechamento da máquina', 'Força necessária para manter o molde fechado durante a injeção.', 'F = (P_cavidade × A_projetada) / 1000', 'toneladas', 'Product Design for Manufacture and Assembly - Boothroyd et al.'),
('Injecao_Plastico', 'Encolhimento', 'INJ-002', 'Encolhimento volumétrico', 'Diferença entre dimensão do molde e da peça após resfriamento.', 'Encolhimento % = ((D_molde - D_peca) / D_molde) × 100', '%', 'Tabelas de resinas termoplásticas'),
('DFMA', 'Eficiência de montagem', 'DFMA-001', 'Índice de eficiência DFA', 'Relação entre tempo teórico mínimo e tempo real de montagem.', 'Eficiência % = (Tempo mínimo teórico / Tempo real) × 100', '%', 'Boothroyd, Dewhurst & Knight - Cap. Montagem'),
('Moldes', 'Classes de molde', 'MOL-001', 'Classificação ABIMAPI/ABINIT', 'Classes 101 a 105 definem vida útil e precisão do molde.', NULL, NULL, 'ABIMAPI / ABINIT');

-- ============================================================================
-- FONTE 4 — BAYER CORPORATION: "Thermoplastics: Part and Mold Design"
-- (KU-GE028, 2000, 174 páginas) — Polímeros de engenharia
-- Valores em polegadas do original convertidos para mm (1 in = 25,4 mm)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- BAYER 1. Famílias de resinas Bayer citadas no guia
-- ----------------------------------------------------------------------------
CREATE TABLE materiais_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    familia VARCHAR(60) NOT NULL,
    nome_comercial VARCHAR(80),
    tipo_polimero VARCHAR(40),
    descricao TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO materiais_bayer (familia, nome_comercial, tipo_polimero, descricao) VALUES
('PC', 'Makrolon', 'Amorfo', 'Policarbonato. Espessura crítica ~4,76 mm (3/16 in) a 23 C: acima disso o impacto torna-se frágil. Sensível a solventes e graxas de rosca. Draft 1 grau recomendado.'),
('PC alta temperatura', 'Apec', 'Amorfo', 'Policarbonato de alta temperatura de uso.'),
('PC/ABS', 'Bayblend', 'Amorfo', 'Blend policarbonato/ABS.'),
('PC blend', 'Makroblend', 'Amorfo', 'Blend policarbonato/poliester.'),
('PA/ABS', 'Triax', 'Amorfo', 'Blend poliamida/ABS.'),
('ABS', 'Lustran / Novodur', 'Amorfo', 'ABS de engenharia; grades especiais para galvanoplastia.'),
('SAN', 'Lustran SAN', 'Amorfo', 'SAN exige draft de 1 a 2 graus; não recomenda punção/die cutting nem roscamento (tapping).'),
('SMA', 'Cadon', 'Amorfo', 'Sensível a cisalhamento (15.000 1/s); molde de 3 placas não recomendado; cuidado com FR e pigmentos sensíveis a cisalhamento.'),
('ASA/AES', 'Centrex', 'Amorfo', 'Resistência ao intemperismo (ASA, AES e ASA/AES).'),
('PA 6 e PA 6/6', 'Durethan', 'Semicristalino', 'Poliamidas; alta retração; absorvem umidade e incham. Draft maior em peças com muitos núcleos.'),
('TPU', 'Texin / Desmopan', 'Elastomérico', 'Poliuretanos termoplásticos; ejeta melhor de moldes jateados (frosted SPI D2); draft mínimo 2 graus.'),
('PBT', 'Pocan', 'Semicristalino', 'Poliéster PBT, carregado ou não.');

-- ----------------------------------------------------------------------------
-- BAYER 2. Propriedades mecânicas — Tabela 3-1 (metais x plásticos)
-- ----------------------------------------------------------------------------
CREATE TABLE propriedades_mecanicas_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material VARCHAR(80) NOT NULL,
    modulo_elastico_10e6_psi DECIMAL(8,3),
    tensile_strength_ksi DECIMAL(8,2),
    yield_strength_ksi DECIMAL(8,2),
    poisson DECIMAL(5,3),
    obs TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO propriedades_mecanicas_bayer (material, modulo_elastico_10e6_psi, tensile_strength_ksi, yield_strength_ksi, poisson, obs) VALUES
('Aco (referencia)', 28.500, 70.00, 40.00, 0.290, 'Referência estrutural.'),
('Cobre recozido', 15.600, 32.00, 5.00, 0.360, NULL),
('Aluminio', 10.000, 56.00, 34.00, 0.330, NULL),
('SAN', 0.470, 4.00, 5.00, 0.350, NULL),
('PC', 0.350, 10.00, 9.00, 0.380, NULL),
('ABS', 0.340, NULL, 6.00, 0.390, NULL),
('PA condicionada (nao carregada)', 0.160, 8.00, 6.00, 0.400, NULL),
('PA 30% vidro', 0.720, 15.00, NULL, 0.340, NULL),
('PC/ABS', 0.350, 7.00, 8.00, 0.380, NULL);

-- ----------------------------------------------------------------------------
-- BAYER 3. Limites de deformação de curto prazo a 23 C (Tabelas 3-3 e 4-1)
-- ----------------------------------------------------------------------------
CREATE TABLE limites_deformacao_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material VARCHAR(80) NOT NULL,
    vidro_pct INT NULL,
    condicao VARCHAR(40),
    limite_deformacao_pct DECIMAL(5,2),
    obs TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO limites_deformacao_bayer (material, vidro_pct, condicao, limite_deformacao_pct, obs) VALUES
('Apec (PC alta temp)', NULL, 'seco', 4.00, NULL),
('Bayblend (PC/ABS)', NULL, 'seco', 2.50, NULL),
('Centrex (ASA)', NULL, 'seco', 1.90, NULL),
('Durethan (PA)', NULL, 'condicionada', 6.00, NULL),
('Durethan (PA)', NULL, 'seca', 4.00, NULL),
('Lustran (ABS)', NULL, 'seco', 1.80, NULL),
('Makroblend (PC blend)', NULL, 'seco', 3.50, NULL),
('Makrolon (PC)', NULL, 'seco', 4.00, NULL),
('Triax (PA/ABS)', NULL, 'seco', 3.40, NULL),
('Makrolon (PC)', 10, 'seco', 2.20, NULL),
('Triax (PA/ABS)', 15, 'seco', 2.20, NULL),
('Makrolon (PC)', 20, 'seco', 2.00, NULL),
('Durethan (PA)', 30, 'condicionada', 2.00, NULL),
('Durethan (PA)', 30, 'seca', 1.50, NULL),
('REGRA GERAL', NULL, 'uso repetido/frequente', NULL, 'Para junções separadas com frequência usar 60% dos limites. Fator de segurança >=2,0 no cálculo de tensão (>=2,5 a 3,0 em aplicações críticas).');

-- ----------------------------------------------------------------------------
-- BAYER 4. Coeficiente de expansão térmica linear — Tabela 3-8
-- ----------------------------------------------------------------------------
CREATE TABLE coef_expansao_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material VARCHAR(60) NOT NULL,
    clte_10e5_in_in_f DECIMAL(6,2),
    clte_10e5_mm_mm_c DECIMAL(6,2),
    obs TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO coef_expansao_bayer (material, clte_10e5_in_in_f, clte_10e5_mm_mm_c, obs) VALUES
('Vidro', 0.5, 0.9, NULL),
('Aco', 0.8, 1.4, NULL),
('RIM composto', 0.8, 1.4, NULL),
('Latão', 1.0, 1.8, NULL),
('Aluminio', 1.3, 2.3, NULL),
('Nylon GF', 1.3, 2.3, NULL),
('Poliéster GF', 1.4, 2.5, NULL),
('PPS GF', 1.5, 2.7, NULL),
('PC GF', 1.7, 3.0, NULL),
('ABS GF', 1.7, 3.0, NULL),
('PP GF', 1.8, 3.2, NULL),
('Acetal GF', 2.5, 4.5, NULL),
('Acrílico', 3.8, 6.8, NULL),
('PC', 3.9, 7.0, NULL),
('PC/ABS', 4.0, 7.2, NULL),
('RIM elastomérico GF', 4.0, 7.2, NULL),
('Nylon', 4.5, 8.1, NULL),
('ABS', 5.0, 9.0, NULL),
('PP', 5.0, 9.0, NULL),
('Acetal', 5.8, 10.4, NULL),
('Poliéster', 6.0, 10.8, NULL),
('PE', 7.0, 12.6, NULL),
('RIM elastomérico sem carga', 7.8, 14.0, NULL);

-- ----------------------------------------------------------------------------
-- BAYER 5. Limite PV (rolamentos/engrenagens) — Tabela 2-2 a 100 ft/min
-- ----------------------------------------------------------------------------
CREATE TABLE regras_pv_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material VARCHAR(60) NOT NULL,
    pv_limit_psi_ft_min INT,
    condicao VARCHAR(80),
    obs TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_pv_bayer (material, pv_limit_psi_ft_min, condicao, obs) VALUES
('PC', 500, '100 ft/min', 'Lubrificante compatível pode mais que dobrar o PV limit.'),
('TPU', 1500, '100 ft/min', NULL),
('PA6', 2000, '100 ft/min', NULL),
('PA6/6', 2500, '100 ft/min', NULL),
('PA6 30% GF', 8500, '100 ft/min', NULL),
('REGRA — folga mínima', NULL, 'faixa de temperatura', 'Manter folga mínima de 0,005 in por polegada de diâmetro (0,127 mm/mm).'),
('REGRA — material vs aço', NULL, 'desgaste', 'Plástico contra aço: usar carga de vidro p/ aumentar vida. Mesmo material: mais desgaste.'),
('REGRA — lubrificante', NULL, 'compatibilidade', 'Verificar compatibilidade do lubrificante com a resina; PC sensível a many compostos.');

-- ----------------------------------------------------------------------------
-- BAYER 6. Regras de espessura de parede (Cap. 2 e 3)
-- ----------------------------------------------------------------------------
CREATE TABLE regras_espessura_parede_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_espessura_parede_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-WALL-001','Rigidez x espessura','Aumento de rigidez',NULL,10,33,'%','Seção de parede plana','Cada aumento de 10% na espessura aumenta ~33% a rigidez (curto prazo). Preferir ribs/coroamento a engrossar.','p.19'),
('BAYER-WALL-002','Faixa prática','Espessura típica',NULL,1.524,4.064,'mm','Partes sólidas','Faixa típica 0,060–0,160 in; a moldagem limita ~0,25 in (6,35 mm) em partes sólidas.','p.46'),
('BAYER-WALL-003','Parede fina','Thin-wall',NULL,0,1.5,'mm','Máquina high-performance','Paredes principais <1,5 mm exigem altas velocidades de preenchimento; partes >2 mm também são thin-wall se a razão comprimento de fluxo/espessura for alta.','p.20'),
('BAYER-WALL-004','Variação tolerável','Variação de espessura',NULL,0,25,'%','Amorfos e carregados (baixa retração)','Resinas cristalinas não carregadas (alta retração) toleram ~metade (~12%).','p.20'),
('BAYER-WALL-005','Flow leader','Canal espessado',NULL,0,25,'% da parede nominal','≤25% p/ baixa retração; ≤15% p/ cristalinas','Canal espessado a partir do gate ajuda preenchimento/packing longe do gate; transição cuidadosa p/ evitar read-through.','p.22'),
('BAYER-WALL-006','Flow restrictor','Restrição de fluxo',NULL,0,50,'% de redução','≤33% alta retração; ≤50% baixa retração','Reduz espessura p/ corrigir padrão de preenchimento/air traps; estender por todo o perfil do canal; alongar para reduzir fluxo.','p.22-23'),
('BAYER-WALL-007','Espessura crítica','PC Makrolon',NULL,0,4.76,'mm','A 23 C','Acima da espessura crítica (~3/16 in) o impacto torna-se frágil; cai com temperatura e peso molecular menores.','p.20'),
('BAYER-WALL-008','Gas entrapment','Thin-to-thick',NULL,NULL,NULL,'—','Proibição de projeto','Evitar áreas finas cercadas por perímetros espessos; evitar variações que causem preenchimento do fino para o grosso.','p.20'),
('BAYER-WALL-009','Cantos','Espessura uniforme',NULL,NULL,NULL,'—','R2 = R1 + t','Manter espessura constante no canto (raio externo = interno + t).','p.21'),
('BAYER-WALL-010','Transições','Blend de espessura',NULL,NULL,NULL,'—','Transições suaves','Arredondar ou conicar transições p/ minimizar read-through, blush e tensões.','p.21');

-- ----------------------------------------------------------------------------
-- BAYER 7. Costelas (ribs) — Tabela 2-1 e Cap. 3
-- ----------------------------------------------------------------------------
CREATE TABLE regras_costelas_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_costelas_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-RIB-001','Espessura base da costela','Retração mínima/leve','PC',50,66,'% da parede','40% se alto brilho','Tabela 2-1: 50% (40% se alto brilho) p/ retração mínima; 66% p/ leve retração.','p.26'),
('BAYER-RIB-002','Espessura base da costela','Retração mínima/leve','ABS',40,60,'% da parede',NULL,'Tabela 2-1.','p.26'),
('BAYER-RIB-003','Espessura base da costela','Retração mínima/leve','PC/ABS',50,66,'% da parede',NULL,'Tabela 2-1.','p.26'),
('BAYER-RIB-004','Espessura base da costela','Retração mínima/leve','PA não carregada',30,40,'% da parede',NULL,'Tabela 2-1.','p.26'),
('BAYER-RIB-005','Espessura base da costela','Retração mínima/leve','PA carregada (vidro)',33,50,'% da parede',NULL,'Tabela 2-1.','p.26'),
('BAYER-RIB-006','Espessura base da costela','Retração mínima/leve','PBT não carregado',30,40,'% da parede',NULL,'Tabela 2-1.','p.26'),
('BAYER-RIB-007','Espessura base da costela','Retração mínima/leve','PBT carregado',33,50,'% da parede',NULL,'Tabela 2-1.','p.26'),
('BAYER-RIB-008','Raio da base','Concordância',NULL,0.125,0.125,'x espessura (T)','Padrão','Raio da base = 0,125T.','p.26'),
('BAYER-RIB-009','Draft da costela','Ejeção',NULL,0.5,NULL,'graus por lado','Mínimo','≥0,5 grau por lado; >1 grau por lado pode finar demais o topo de ribs altas e causar problemas de enchimento.','p.25'),
('BAYER-RIB-010','Altura da costela','Moldabilidade',NULL,NULL,3,'x espessura da base','Padrão','Altura ≈3x a espessura da base; ribs mais altas têm topo fino, buckling; usar 2+ ribs mais curtas/finas.','p.26'),
('BAYER-RIB-011','Espaçamento','Resfriamento do molde',NULL,2,NULL,'x espessura da parede','Ribs curtas','Espaçamento mínimo 2x espessura da parede p/ resfriamento.','p.26'),
('BAYER-RIB-012','Parede fina','Costela = parede',NULL,NULL,1.0,'mm de parede','Paredes ≤1,0 mm','Espessura da costela igual à espessura da parede (percentuais não se aplicam).','p.26'),
('BAYER-RIB-013','Flow hesitation','Perto do gate',NULL,NULL,NULL,'—','Enchimento','Ribs finas perto do gate podem hesitar/congelar enquanto a parede espessa enche.','p.25'),
('BAYER-RIB-014','Dobrar rigidez','Comparação',NULL,7,NULL,'% de volume adicional','Fig. 3-23','Adicionar rib dobra a rigidez com +7% de volume vs +25% ao engrossar a parede.','p.71'),
('BAYER-RIB-015','Substituir rib','Opções equivalentes',NULL,NULL,NULL,'—','Opção C','Trocar rib muito espessa (sink) ou muito alta (tensão na aresta) por par de ribs mais finas/curtas.','p.73'),
('BAYER-RIB-016','Momento de inércia','Fórmula',NULL,NULL,NULL,'—','I = b*h^3/12','Rigidez da rib proporcional a altura ao cubo e linear à largura.','p.72');

-- ----------------------------------------------------------------------------
-- BAYER 8. Bosses e gussets
-- ----------------------------------------------------------------------------
CREATE TABLE regras_bosses_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_bosses_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-BOSS-001','Diâmetro externo','Boss x parafuso/insert',NULL,2.0,2.4,'x OD do parafuso/insert','Regra geral','OD do boss entre 2,0 e 2,4x o diâmetro externo do parafuso ou insert.','p.27'),
('BAYER-BOSS-002','Espessura de parede','Boss',NULL,NULL,NULL,'% da parede','Tabela 2-1','Manter a mesma proporção da regra de ribs p/ evitar sink na face oposta.','p.28'),
('BAYER-BOSS-003','Fillet na base','Concordância',NULL,0.381,0.381,'mm','0,015 in','Raio de concordância na base reduz concentração de tensão; raio maior aumenta risco de sink/void.','p.28'),
('BAYER-BOSS-004','Profundidade do furo','Boss',NULL,NULL,NULL,'—','Até o nível da parede base','Furo deve descer até o nível da parede base: curto demais deixa seção espessa (sink); profundo demais enfraquece a base.','p.29'),
('BAYER-BOSS-005','Altura do boss','Bosses altos',NULL,NULL,5,'x OD','Bosses altos','Bosses >5x o OD criam problema de enchimento no topo ou seção espessa na base; core por 2 lados ou gusset até a altura de standoff.','p.29'),
('BAYER-BOSS-006','Recess na base','Redução de sink',NULL,NULL,NULL,'—','Quando parede do boss excede o recomendado','Recesso de 30 graus e 0,3t ao redor da base reduz severidade do sink.','p.28'),
('BAYER-BOSS-007','Boss junto a lateral','Evitar fusão',NULL,NULL,NULL,'—','Thick section','Bosses fundidos à lateral formam seções espessas (sink); afastar do sidewall e conectar com rib, se preciso; considerar open boss.','p.28');

CREATE TABLE regras_gussets_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_gussets_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-GUS-001','Espessura do gusset','Gusset',NULL,50,66.7,'% da parede conectada','Se sink é preocupação','Limitar a 1/2 a 2/3 da espessura das paredes conectadas.','p.30'),
('BAYER-GUS-002','Ejeção do gusset','Formado por EDM',NULL,NULL,NULL,'—','Draft e draw polish','Especificar draft e draw polishing; gussets têm problemas de ejeção.','p.30'),
('BAYER-GUS-003','Ventilação do gusset','Air trap',NULL,NULL,NULL,'—','Evitar aprisionamento','Gussets raramente podem ser ventilados diretamente; ajustar forma/espessura p/ empurrar gases para áreas ventiláveis.','p.30');

-- ----------------------------------------------------------------------------
-- BAYER 9. Cantos, draft, furos, undercuts
-- ----------------------------------------------------------------------------
CREATE TABLE regras_cantos_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_cantos_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-COR-001','Razão raio/espessura','R/T',NULL,0.15,0.2,'adimensional','Impacto leve a moderado','R/T ~0,15 é bom compromisso; a concentração de tensão sobe bruscamente quando R/T cai abaixo de ~0,2.','p.31-32'),
('BAYER-COR-002','Raio externo x interno','Espessura uniforme',NULL,NULL,NULL,'—','R2 = R1 + t','Manter espessura constante no canto.','p.21'),
('BAYER-COR-003','Especificação de raio','Áreas críticas',NULL,NULL,NULL,'—','Usar faixa (mínimo) e não máximo','Máximo permite o moldeiro deixar o canto usinado <0,005 in; evitar spec universal que arredonda tudo (custo do molde).','p.31'),
('BAYER-COR-004','Impacto — raio do notch','Izod PC não carregado',NULL,0.127,0.254,'mm','0,005 → 0,010 in','Aumentar raio do notch de 0,005 para 0,010 in eleva o Izod em ~400% (2–4 → 16–18 ft-lb/in).','p.77'),
('BAYER-COR-005','Fillet p/ fadiga','Compromisso',NULL,0.381,0.762,'mm','0,015–0,030 in','Compromisso entre desempenho em fadiga e moldabilidade.','p.79'),
('BAYER-COR-006','Materiais de alta retração','Durethan PA',NULL,NULL,NULL,'—','Baixa sensibilidade a entalhe','Começar com raio mínimo (evitar sink/read-through) e aumentar conforme teste de protótipo.','p.31');

CREATE TABLE regras_draft_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_draft_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-DRAFT-001','Draft padrão','Superfícies',NULL,1,NULL,'graus','Regra geral','1 grau padrão em superfícies paralelas à direção de abertura.','p.32'),
('BAYER-DRAFT-002','Draft mínimo','Maioria dos materiais',NULL,0.5,NULL,'graus','Mínimo','Mínimo 0,5 grau; SAN 1–2 graus; Desmopan/Texin TPU 2 graus (ejetam melhor de moldes jateados).','p.32; p.130'),
('BAYER-DRAFT-003','Draft p/ textura','Textura',NULL,1,NULL,'graus por 0,0254 mm de textura','Textura','Acrescentar 1 grau adicional por cada 0,001 in (0,0254 mm) de profundidade de textura.','p.32; p.119'),
('BAYER-DRAFT-004','Draft em features de furo cego','Bosses/ribs/posts',NULL,NULL,NULL,'—','Furos cegos','Features formadas por furos cegos afinam conforme se estendem para dentro do molde.','p.32'),
('BAYER-DRAFT-005','Draft em superfícies polidas','Acabamento',NULL,NULL,NULL,'—','Polimento','Superfícies polidas exigem menos draft que usinadas; exceção: TPU ejeta melhor de superfícies jateadas (frosted).','p.32');

CREATE TABLE regras_furos_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_furos_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-HOLE-001','Furo cego','Blind hole',NULL,NULL,3,'P:D (máx)','Regra geral','Profundidade/diâmetro ≤3:1; até 5:1 se o preenchimento for simétrico ao redor do core ou em área de fluxo lento.','p.33'),
('BAYER-HOLE-002','Furo passante','Interlocked',NULL,NULL,6,'P:D (máx)','Core apoiado nos dois lados','6:1 típico; até 10:1 se o preenchimento ao redor do core for simétrico.','p.33'),
('BAYER-HOLE-003','Mismatch de cores','Furos formados por 2 cores',NULL,NULL,NULL,'—','Core maior de um lado','Fazer um core ligeiramente maior p/ acomodar mismatch; interlocks p/ tolerância apertada (aumentam custo).','p.33'),
('BAYER-HOLE-004','Furo curto de um core','Furo passante curto',NULL,NULL,NULL,'—','Sem mismatch','Arredondar aresta em apenas um lado elimina o core oposto.','p.34');

CREATE TABLE regras_undercut_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_undercut_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-UNC-001','Percentual de undercut','Fórmula',NULL,NULL,NULL,'%','Fórmula','%Undercut = (D - d)/D x 100; ângulo de entrada (lead) 30–45 graus.','p.34'),
('BAYER-UNC-002','Strip em resinas rígidas','PC, blends, PA6 reforçada',NULL,NULL,2,'%','Rígidas','Evitar strip; até 2% possível se paredes flexíveis e arestas arredondadas/inclinadas.','p.34'),
('BAYER-UNC-003','Strip em resinas flexíveis','PA6 não carregada, TPU',NULL,5,10,'%','Flexíveis','5% típico; até 10% em condições ideais; longe de features rígidas (cantos/ribs).','p.34'),
('BAYER-UNC-004','Alternativas a mecanismos','Custo do molde',NULL,NULL,NULL,'—','Reduzir custo','Bypass steel (janelas), snap hook através de furo, guias de fio; slides/lifters/jiggler/collapsible/unscrewing aumentam custo e manutenção.','p.35; p.125-127');

CREATE TABLE regras_rosca_moldada_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_rosca_moldada_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-THR-001','Rosca externa','Parting line',NULL,NULL,NULL,'—','Custo baixo','Rosca externa centrada na PL molda nas duas metades com pouco custo; risco de rebarba/mismatch.','p.37'),
('BAYER-THR-002','Rosca interna','Custo alto',NULL,NULL,NULL,'—','Custo alto','Exige collapsible/unscrewing cores; considerar auto-atarraxantes p/ desmontagem rara.','p.37'),
('BAYER-THR-003','Passo máximo','Enchimento/anti-cross-thread',NULL,NULL,32,'TPI','Passo','Limitar passo a 32 fios por polegada (aprox. passo >=0,79 mm).','p.38'),
('BAYER-THR-004','Cristas e raízes','Perfil',NULL,NULL,NULL,'—','Arredondar','Usar o maior raio permitido em cristas e raízes; perfis Acme (29 graus) e Buttress funcionam melhor que Unified 60 graus.','p.37'),
('BAYER-THR-005','Fim da rosca','Feather edge',NULL,NULL,NULL,'—','Evitar fio em pena','Parar a rosca antes do fim p/ evitar fio em pena que cross-thread com facilidade.','p.38'),
('BAYER-THR-006','Roscas cônicas (NPT)','Hoop stress',NULL,NULL,NULL,'—','Evitar','Tapered pipe threads geram hoop stress excessivo no plástico; usar rosca reta + O-ring.','p.38'),
('BAYER-THR-007','Strip de rosca','Resinas flexíveis',NULL,NULL,NULL,'—','Diametro/parede >20:1','Apenas em PA6 não carregada ou TPU; roscas generosas; raro em PC/carregadas.','p.37');

CREATE TABLE regras_letreiros_tolerancias_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_letreiros_tolerancias_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-LET-001','Letreiros','Profundidade/altura',NULL,0,0.254,'mm','0,010 in (máx.)','Letreiros fundos/altos perto do gate causam streaks/teardrops; profundidade ≤0,010 in.','p.40'),
('BAYER-LET-002','Letreiros','Paredes das letras',NULL,30,NULL,'graus','α >= 30','Inclinar ou arredondar paredes das letras (W >= 2*d).','p.40'),
('BAYER-TOL-001','Tolerâncias','Tolerancing geométrico',NULL,NULL,NULL,'—','MMC','Expandir tolerância efetiva: posição pode variar com o tamanho da feature (ex.: furo 0,500 ±0,003 + posição 0,006M → zona ±0,006 no MMC).','p.41-42'),
('BAYER-TOL-002','Tolerâncias','Alocação',NULL,NULL,NULL,'—','Custo total','Reservar tolerância mais apertada p/ feature de menor custo; evitar tolerâncias apertadas em dimensões longas/pronas a empenamento; ajustar molde p/ meio da faixa.','p.41-42');

-- ----------------------------------------------------------------------------
-- BAYER 10. Fórmulas estruturais (Cap. 3)
-- ----------------------------------------------------------------------------
CREATE TABLE formulas_estruturais_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    formula TEXT,
    descricao TEXT,
    exemplo TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO formulas_estruturais_bayer (codigo, tema, formula, descricao, exemplo, referencia) VALUES
('BAYER-FOR-001','Tensão de flexão','sigma_b = M*c/I = M/Z','Tensão máxima na fibra externa; c = distância à fibra externa.','Ex. 3-2: I-beam 1 x 1 in, t 0,2 in → Z 0,1378 in^3; sigma 4354 psi.','p.61-64'),
('BAYER-FOR-002','Deflexão de viga','y = PL^3/(3EI) (cantilever); PL^3/(48EI) (simples apoiada)','Usar módulo secante ou fluência conforme regime; tabela 3-5 lista outros casos (carga distribuída, apoios).',NULL,'p.63, Tab.3-5'),
('BAYER-FOR-003','Momento de inércia','I = b*h^3/12 (retângulo); Z = I/c','Seção retangular; tabela 3-4 traz fórmulas para T, U, C, tubo, etc.',NULL,'p.62, Tab.3-4'),
('BAYER-FOR-004','Torsão','tau = T*c/J; phi = T*L/(J*G)','J = pi*d^4/32 (círculo); phi em radianos.',NULL,'p.66'),
('BAYER-FOR-005','Módulo de cisalhamento','G ≈ E/[2*(1+nu)]; gamma ≈ (1+nu)*epsilon; sigma ≈ 2*tau','Conversão de deformação de tração para cisalhamento.','Ex. 3-4: PC shaft 0,2 in dia, 0,5 in long, 5 in-lb → tau 3185 psi, phi 9,1 graus.','p.66'),
('BAYER-FOR-006','Deflexão de placa','delta = 3*p*r^4*(5-4*nu-nu^2)/(16*E*t^3); sigma = 3*p*r^2*(3+nu)/(8*t^2)','Placa circular simplesmente apoiada, carga uniforme.',NULL,'p.65'),
('BAYER-FOR-007','Módulo secante','E_sec = sigma/epsilon (da curva tensão-deformação)','Não usar Young além do limite proporcional; erro até ~19% no exemplo 3-1 (PC 4000 psi → 1,35% vs 1,1%).',NULL,'p.49, p.60'),
('BAYER-FOR-008','Módulo de fluência (creep)','E_app = sigma/epsilon(t,T)','Ler strain na curva isócrona para a duração desejada. Ex.: PC 23 C, 2800 psi, 1000 h → ~1,2% → ~220.000 psi.','p.55'),
('BAYER-FOR-009','Fator de segurança','SF >= 2,0 (>=2,5 a 3,0 crítico)','Limite geral de tensão: 25% da tensão de escoamento. Cargas repetidas: 60% dos limites de deformação.','p.59'),
('BAYER-FOR-010','Espessura equivalente','t_eq = t_atual*(E_atual/E_proposta)^(1/3)','Para igualar deflexão (forma plana, curto prazo, 23 C).',NULL,'p.70'),
('BAYER-FOR-011','ETF — substituir aço','ABS 4,2x; PC 4,4x; PC/ABS 4,3x; Makroblend 4,4x; PA6-GF30 3,4x; Al 1,4x; aço 1,0x','Tabela 3-6.','Ex. 3-5: alumínio 0,030 in → PA6-50%GF 0,062 in.','p.70-71'),
('BAYER-FOR-012','Relaxação de tensão','Retenção cai ~25% no 1º mês, ~33% em 6 anos','Exemplo 3-7: cantilever PC 1 in x 0,080 in x 0,25 in, deflexão 0,1 in; força 1,00/0,75/0,67/0,59.','p.75, Tab.3-7'),
('BAYER-FOR-013','Expansão térmica','delta_L = (alpha_plastico - alpha_metal)*delta_T*L','Acomodar com furos alongados/slot.','Ex.: PC shield 10 in, Al housing, 20–120 F → 0,013 in; strain 0,13%.','p.80');

-- ----------------------------------------------------------------------------
-- BAYER 11. Regras de rigidez (Cap. 3)
-- ----------------------------------------------------------------------------
CREATE TABLE regras_rigidez_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_rigidez_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-STF-001','Coroamento (crown)','Domo',NULL,6.35,NULL,'mm','Disco 254 mm, parede 2,54 mm','Domo de 0,25 in em disco de 10 in (parede 0,100 in) aumenta a rigidez em ~300%.','p.67, Fig.3-17'),
('BAYER-STF-002','Corrugações','Superfícies não cosméticas',NULL,NULL,NULL,'—','Rigidez','Corrugações (altura/espaçamento ajustáveis) aumentam rigidez e distribuem carga.','p.68'),
('BAYER-STF-003','Curvatura nas laterais','Caixas',NULL,NULL,NULL,'—','Em caixas','Curvar laterais aumenta rigidez e reduz empenamento (hourglass).','p.68'),
('BAYER-STF-004','Perfis de borda','Bordas sem apoio',NULL,NULL,NULL,'—','Edge stiffening','Perfis retos (straight-draw) p/ moldar sem slide; manter espessura uniforme.','p.68'),
('BAYER-STF-005','Componentes do conjunto','Apoio interno',NULL,NULL,NULL,'—','Reforço','Usar componentes rígidos do conjunto (ventoinhas, blindagens, heat sinks) como apoio.','p.68');

-- ----------------------------------------------------------------------------
-- BAYER 12. Regras de montagem (DFA) — Cap. 4
-- ----------------------------------------------------------------------------
CREATE TABLE regras_montagem_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_montagem_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-ASM-001','Consolidação de peças','Redução de contagem',NULL,NULL,NULL,'—','DFA','Consolidar funcionalidades em uma única peça moldada (ex.: engrenagem e eixo; dobradiça moldada).','p.83-84'),
('BAYER-ASM-002','Fixadores','Auto-atarraxantes',NULL,NULL,NULL,'—','Custo','Preferir fixadores off-the-shelf; self-tapping screws; inserts metálicos p/ desmontagem frequente; hex holes p/ cativar porcas; clipes mola.','p.84-85'),
('BAYER-ASM-003','Snap-fits','Braço perpendicular',NULL,50,66.7,'% da parede','Projeção','Braço projetado perpendicularmente ≤1/2 a 2/3 da espessura da parede; raio mínimo 0,381 mm (0,015 in) na base; limite de deformação Tabela 4-1; 60% p/ uso frequente.','p.87'),
('BAYER-ASM-004','Solda ultrassônica','Energy director',NULL,NULL,NULL,'—','60–90 graus','Energy director 60–90 graus, altura 0,25*W; shear joint p/ estanqueidade; limitação de tamanho de chifre (horn).','p.89'),
('BAYER-ASM-005','Solda vibração/placa quente','Juntas largas',NULL,NULL,NULL,'—','Flash traps','Juntas largas p/ vibração; hot-plate p/ não cosmético; flash traps p/ junta sem rebarba; spin welding com tongue-groove.','p.90-91'),
('BAYER-ASM-006','Colagem','PC sensível',NULL,NULL,NULL,'—','Vapores retidos','Solvent bonding limita material (solvente compatível); PC sensível a vapores retidos; adesivos UV exigem linha de visada.','p.91'),
('BAYER-ASM-007','Alinhamento','Features de alinhamento',NULL,NULL,NULL,'—','Lead-in', 'Chamfers/lead-in (1/32 in), tongue-and-groove, borda escalonada, dedos de alinhamento, pino-em-furo, boss-alignment.','p.92-93'),
('BAYER-ASM-008','Orientação','Poka-yoke e simetria',NULL,NULL,NULL,'—','Montagem','Features que impedem montagem incorreta; simetria simplifica montagem.','p.94'),
('BAYER-ASM-009','Diferença de CLTE','Furos alongados',NULL,NULL,NULL,'—','Poliamidas incham','Acomodar expansão com furos alongados (slot); poliamidas incham com umidade.','p.94'),
('BAYER-ASM-010','Tolerâncias','Alocação p/ menor custo',NULL,NULL,NULL,'—','Custo total','Tolerância mais apertada p/ feature/processo de menor custo; evitar tolerâncias apertadas em dimensões longas/pronas a empenamento.','p.95');

-- ----------------------------------------------------------------------------
-- BAYER 13. Limites de taxa de cisalhamento — Tabela 7-1 (1/s)
-- ----------------------------------------------------------------------------
CREATE TABLE limites_cisalhamento_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material VARCHAR(80) NOT NULL,
    limite_1_s INT,
    obs TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO limites_cisalhamento_bayer (material, limite_1_s, obs) VALUES
('Makrolon PC', 40000, 'Usar metade p/ retardante de chama e aplicações transparentes/cosméticas críticas.'),
('Apec', 40000, NULL),
('Bayblend PC/ABS', 40000, NULL),
('Makroblend', 40000, NULL),
('Triax PA/ABS', 50000, NULL),
('Lustran ABS', 40000, NULL),
('Lustran SAN', 40000, NULL),
('Cadon SMA', 15000, NULL),
('Centrex', 40000, NULL),
('Durethan PA6', 60000, NULL),
('Durethan carregado', 40000, NULL),
('Texin TPU', 20000, NULL),
('Texin PC/TPU', 10000, NULL),
('Desmopan TPU', 20000, NULL),
('REGRA — fórmulas', NULL, 'Round: 4Q/(pi*r^3); rectangular: 6Q/(w*t^2). Dobrar largura → metade da taxa; +25% diâmetro → metade.'),
('REGRA — gate', NULL, 'Diâmetro do gate >80% da espessura da parede p/ evitar shear excessivo; alimentar seções espessas; poços espessados.');

-- ----------------------------------------------------------------------------
-- BAYER 14. Regras de projeto de molde — Cap. 7
-- ----------------------------------------------------------------------------
CREATE TABLE regras_molde_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_molde_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-MLD-001','Tipos de molde','2 placas / 3 placas / stack',NULL,NULL,NULL,'—','Escolha','2 placas padrão; 3 placas p/ gates pontuais internos (regrind alto, shear; evitar em Cadon SMA/FR/pigmentos sensíveis); stack mold reduz força de fechamento (cavidades empilhadas).','p.121-123'),
('BAYER-MLD-002','Undercuts','Redesign primeiro',NULL,NULL,NULL,'—','Custo do molde','Redesenhar p/ evitar undercuts (bypass steel, furo passante); mecanismos (slides/lifters/jiggler/collapsible/unscrewing) aumentam custo e manutenção.','p.125-127'),
('BAYER-MLD-003','Undercut — collapsible core','Diâmetro mínimo',NULL,15.875,NULL,'mm','0,625 in (mín.)','Collapsible cores raramente usados para diâmetros internos <0,625 in.','p.127'),
('BAYER-MLD-004','Ejeção','Pinos KO/lâminas/luvas/stripper',NULL,NULL,NULL,'—','Witness marks','Pinos padrão +0,127 mm (0,005 in) p/ reajuste de furos gastos; lâminas p/ ribs/paredes finas; luvas p/ bordas circulares; stripper plate.','p.128-129'),
('BAYER-MLD-005','Ejeção','Paredes finas',NULL,NULL,NULL,'—','Maior área de ejeção','Paredes finas exigem ejetores maiores e mais área de contato.','p.129'),
('BAYER-MLD-006','Ejeção','Draw polish / TPU',NULL,NULL,NULL,'—','Direção de ejeção','Draw polish na direção de ejeção; TPU ejeta melhor de superfície jateada (SPI D2).','p.129; p.163'),
('BAYER-MLD-007','Ejeção','Vácuo em partes fundas',NULL,NULL,NULL,'—','Air-poppet valve','Válvula air-poppet p/ aliviar vácuo em partes fundas de fundo fechado.','p.130'),
('BAYER-MLD-008','Core shift','Gateamento',NULL,NULL,NULL,'—','Simétrico','Gateamento simétrico ao redor de núcleos longos p/ evitar deslocamento do core.','p.148'),
('BAYER-MLD-009','Base do molde','Componentes',NULL,NULL,NULL,'—','Standard','Locating ring, sprue bushing, leader pins, return pins, support pillars; inserts em áreas de desgaste; cavity units p/ troca rápida.','p.124-125');

-- ----------------------------------------------------------------------------
-- BAYER 15. Ventilação do molde — Cap. 7
-- ----------------------------------------------------------------------------
CREATE TABLE regras_ventos_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_ventos_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-VEN-001','Profundidade do vento','Amorfas',NULL,0.0254,0.0508,'mm','0,0010–0,0020 in','Profundidade do vento: amorfas 0,0010–0,0020 in; semicristalinas 0,0005–0,0015 in; reduzir limite superior em 0,0005 in p/ flash mínimo.','p.131'),
('BAYER-VEN-002','Profundidade do vento','Semicristalinas',NULL,0.0127,0.0381,'mm','0,0005–0,0015 in','Idem acima.','p.131'),
('BAYER-VEN-003','Land e canal','Geometria do vento',NULL,3.81,7.62,'mm','land 0,15–0,30 in; canal >=0,04 in','Land do vento 0,15–0,30 in; canal do vento >=0,04 in.','p.131, Fig.7-14'),
('BAYER-VEN-004','Quantidade de ventos','Exceção FR',NULL,NULL,NULL,'—','Mais ventos melhor','Mais ventos são melhores; exceção: resinas com FR/aditivos voláteis (ventar com parcimônia).','p.131'),
('BAYER-VEN-005','Posição dos ventos','Últimas áreas a encher',NULL,NULL,NULL,'—','Parting line','Ventar as últimas áreas a encher; furos cegos (posts/bosses) precisam vento na ponta (ejector-pin vents, flats 0,002 in).','p.131-132'),
('BAYER-VEN-006','Poços de transbordo','Overflow wells',NULL,NULL,NULL,'—','~1/3 da espessura','Poços de transbordo (~1/3 da espessura) melhoram linhas de solda.','p.132, Fig.7-17');

-- ----------------------------------------------------------------------------
-- BAYER 16. Canais (sprue/runner) — Cap. 7
-- ----------------------------------------------------------------------------
CREATE TABLE regras_canais_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_canais_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-RUN-001','Sprue','Esfera e conicidade',NULL,12.7,19.05,'mm','0,5/0,75 in esfera; 0,5 in/ft taper','Sprue: esfera 0,5/0,75 in; conicidade 0,5 in/ft; orifício 5/32–11/32 in (3,97–8,73 mm, 1/32 ímpares).','p.133-134'),
('BAYER-RUN-002','Sprue','Orifício maior',NULL,NULL,NULL,'—','Peças grandes/enchimento rápido','Orifício maior p/ peças grandes/enchimento rápido; amorfas exigem sprue/canais maiores que semicristalinas.','p.134'),
('BAYER-RUN-003','Sprue','Hot sprue/extension nozzle',NULL,NULL,NULL,'—','Sprues longos','Hot sprue ou extension nozzle p/ sprues longos (base grande = ciclo longo + regrind).','p.134'),
('BAYER-RUN-004','Runner','Espessura e seção',NULL,NULL,NULL,'—','≥ parede; round full','Runner ≥ espessura da parede; round full = melhor; trapezoidal round-bottom (5 graus) em uma metade.','p.135'),
('BAYER-RUN-005','Runner secundário','Diâmetro',NULL,NULL,NULL,'—','r_sec = sqrt(r_prim^2/2)','Diâmetro secundário: área total = área primária; arredondar p/ cima p/ cutter padrão (ex.: primária 0,25 in → 2 secundárias 0,177 in ≈ 3/16 in).','p.136'),
('BAYER-RUN-006','Runner secundário','Comprimento mínimo',NULL,NULL,NULL,'—','≥1/5','Comprimento secundária ≥1/5 da distância junção→gates externos.','p.138'),
('BAYER-RUN-007','Balanceamento natural','Potência de 2',NULL,NULL,NULL,'—','2,4,8,16,32...','Balanceamento natural: nº de cavidades potência de 2; family mold: todas preenchem juntas; spoked runner + poço de slug frio.','p.137-138'),
('BAYER-RUN-008','Balanceamento artificial','Redução de diâmetro',NULL,NULL,NULL,'—','Caminho mais curto','Balanceamento artificial: reduzir diâmetro das secundárias de caminho mais curto.','p.139'),
('BAYER-RUN-009','Runner de 3 placas','Drops',NULL,NULL,NULL,'—','d = 0,6*s','Drops cônicos 0,5 in/ft; sucker pins; d = 0,6*s; evitar drops longos.','p.139, Fig.7-27');

-- ----------------------------------------------------------------------------
-- BAYER 17. Gates — Cap. 7
-- ----------------------------------------------------------------------------
CREATE TABLE regras_gates_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_gates_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-GAT-001','Edge gate','Land',NULL,0,1.524,'mm','0,060 in (máx.)','Land ≤0,060 in (1,524 mm).','p.140'),
('BAYER-GAT-002','Edge gate','Espessura do gate',NULL,0.5,0.65,'x land C','0,5–0,65*C','Espessura do gate = 0,5 a 0,65 vezes o land C.','p.140, Fig.7-28'),
('BAYER-GAT-003','Tipos de gate','Fan/chisel/tab',NULL,NULL,NULL,'—','Cosmética/remoção','Fan/chisel gates p/ cosmética; tab gate p/ remoção rápida.','p.140'),
('BAYER-GAT-004','Tunnel gate','Conicidade',NULL,40,50,'graus','Drop 40–50; cônico 20–30','Tunnel gate: drop 40–50 graus, cônico 20–30 graus; modificado 45–65 graus com 5–10 graus; ejetor ≥2 diâmetros de runner do gate.','p.142-143'),
('BAYER-GAT-005','Curved tunnel','Geometria',NULL,4,6,'mm','X>2,5*d1 ou >=15 mm','Curved tunnel: X > 2,5*d1 ou ≥15 mm; D = 4–6 mm; d1–d2 cônico incluso 3–5 graus; L1 > L2; r = 2,5–3*d1.','p.143, Fig.7-38'),
('BAYER-GAT-006','Pinpoint gate','Diâmetro',NULL,0,2.032,'mm','0,080 in (máx.)','Pinpoint gate ≤0,080 in (2,032 mm) de diâmetro; gate well rebaixada; ponto de quebra definido.','p.144'),
('BAYER-GAT-007','Tipos especiais','Filter-bowl/diaphragm',NULL,NULL,NULL,'—','Sem knitline','Filter-bowl (sem linha de solda); diaphragm (2ª operação).','p.145'),
('BAYER-GAT-008','Otimização','Espessura por material',NULL,NULL,NULL,'—','Não carregado ≥1/2; cosmético 2/3; nylon carregado ≥1/3','Espessura do gate: não carregado ≥1/2 da parede; cosmético 2/3; nylon carregado ≥1/3; thin-wall <1,5 mm → gates desproporcionalmente grandes; diâmetro >80% da parede p/ shear; alimentar seções espessas; poços espessados.','p.145-146'),
('BAYER-GAT-009','Posição do gate','Direção do esforço',NULL,NULL,NULL,'—','Orientação de fluxo','Posicionar p/ direção do esforço (GF 2x mais forte no fluxo); gatear na seção mais espessa; evitar áreas de alta tensão (bosses, snap arms); simétrico ao redor de núcleos; fluxo uniforme ao longo do comprimento p/ GF.','p.147-148'),
('BAYER-GAT-010','Comprimento de fluxo','Spiral flow',NULL,NULL,NULL,'—','Flow leaders','Comprimento de fluxo ≤ dados de spiral flow; flow leaders; evitar thin-to-thick; hesitação.','p.148');

-- ----------------------------------------------------------------------------
-- BAYER 18. Resfriamento do molde — Cap. 7
-- ----------------------------------------------------------------------------
CREATE TABLE regras_resfriamento_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_resfriamento_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-COO-001','Tempo de resfriamento','Proporcional a t^2',NULL,NULL,NULL,'—','t^2','Tempo de resfriamento ∝ t^2 (dobrar espessura → 4x tempo); core-out de seções espessas.','p.154'),
('BAYER-COO-002','Posicionamento','Centroline e espaçamento',NULL,2.5,3,'x diâmetro do canal','2,5D da superfície; ≤3D entre canais','Canais: centroline ~2,5*D da superfície da cavidade; espaçamento ≤3*D.','p.155'),
('BAYER-COO-003','Diâmetro do canal','Por parede',NULL,4.7625,7.9375,'mm','t<1,6 mm','D 4,76–7,94 mm (t<1,6 mm); 7,94–11,11 mm (t<3,2 mm); 11,11–15,88 mm (t<6,35 mm).','p.155, Fig.7-50'),
('BAYER-COO-004','Núcleos profundos','Bubblers/baffles/espiral',NULL,NULL,NULL,'—','Resfriamento','Bubblers/baffles p/ núcleos profundos; canais espirais p/ núcleos grandes; ajustar comprimento do bubbler.','p.156'),
('BAYER-COO-005','Cantos internos','Hourglass',NULL,NULL,NULL,'—','Calor concentrado','Cantos internos: calor concentrado → hourglass; aproximar canal, corar canto, bubblers/inserts condutivos, sem pinos ejetores em cantos.','p.157-158'),
('BAYER-COO-006','Circuitos','Série/paralelo',NULL,NULL,NULL,'—','Múltiplos em série','Série = fluxo uniforme; paralelo divide vazão; múltiplos em série = melhor; espessas/núcleos quentes primeiro.','p.158'),
('BAYER-COO-007','Vazão do refrigerante','Reynolds',NULL,NULL,NULL,'—','Re = 3160*Q/(D*eta); alvo 10.000','η água: 1,3 cSt @10 C; 0,7 @38 C; 0,4 @66 C; 0,3 @93 C. Ex.: canal 11,11 mm @66 C → 0,5 gal/min (1,9 L/min).','p.159'),
('BAYER-COO-008','Delta T do refrigerante','≤2,2 C',NULL,NULL,2.2,'C','4 F (máx.)','ΔT refrigerante ≤2,2 C (4 F); medidores de fluxo; evitar desconexões rápidas/obstruções.','p.160'),
('BAYER-COO-009','Temperatura de molde','Gloss e skin',NULL,NULL,NULL,'—','Superfície','Molde mais quente → melhor replicação de microtextura (menor brilho em texturizados); em GF → skin rica em resina (menos efeito prateado).','p.154');

-- ----------------------------------------------------------------------------
-- BAYER 19. Condutividade térmica do molde — Tabela 7-2
-- ----------------------------------------------------------------------------
CREATE TABLE condutividade_termica_molde_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material VARCHAR(60) NOT NULL,
    btu_ft_hr_ft2_f DECIMAL(8,2),
    w_m_c DECIMAL(8,2),
    uso VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO condutividade_termica_molde_bayer (material, btu_ft_hr_ft2_f, w_m_c, uso) VALUES
('420 Stainless', 14.4, 25.0, 'Corrosão; evitar quando ciclo rápido é crítico.'),
('H13', 16.3, 28.3, NULL),
('P20', 20.0, 34.5, NULL),
('S7', 21.0, 36.4, NULL),
('BeCu C-17200', 68.0, 118.0, NULL),
('Aluminio QC-7', 80.0, 138.8, NULL),
('BeCu C-17510', 135.0, 234.2, 'Alta condutividade.');

-- ----------------------------------------------------------------------------
-- BAYER 20. Encolhimento do molde — Cap. 7
-- ----------------------------------------------------------------------------
CREATE TABLE regras_encolhimento_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_encolhimento_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-SHK-001','Fórmula','Encolhimento',NULL,NULL,NULL,'—','(dim molde - dim peça)/dim molde','Encolhimento = (dimensão molde - dimensão peça)/dimensão molde x 100 (medido à temperatura ambiente).','p.160'),
('BAYER-SHK-002','Seções espessas','Maior encolhimento',NULL,NULL,NULL,'—','Resfriamento lento','Seções espessas encolhem mais; carregados encolhem menos no fluxo (fluxo vs transversal separado).','p.160, Fig.7-59'),
('BAYER-SHK-003','Packing','Redução',NULL,NULL,NULL,'—','Porta do gate', 'Packing reduz encolhimento; diminui longe do gate; gate grande e molde quente atrasam o congelamento do gate.','p.161'),
('BAYER-SHK-004','Uso do dado','Extremo inferior',NULL,NULL,NULL,'—','Peças <2,54 mm','Usar extremo inferior p/ peças <0,100 in (2,54 mm) e features restringidas (furos); design steel-safe.','p.161'),
('BAYER-SHK-005','Faixas típicas 2 mm','Fig. 7-60 (indicativo)',NULL,NULL,NULL,'—','Confirmar ficha','PC ~0,5–0,7%; ABS ~0,4–0,7%; PC/ABS ~0,4–0,7%; PA6 ~1,0–2,0% fluxo / 0,4–0,6 transversal; PBT ~1,2–2,0%; PA6-GF30 ~0,2–0,5% fluxo / 0,3–0,8 transversal (confirmar fig. 7-60 e ficha do fornecedor).','p.161, Fig.7-60'),
('BAYER-SHK-006','Melhor dado','Medição real',NULL,NULL,NULL,'—','Moldes existentes','Medir encolhimento real em moldes existentes com peças similares (gating/fluxo/resfriamento/processing semelhantes).','p.161');

-- ----------------------------------------------------------------------------
-- BAYER 21. Aços de molde — Tabela 7-3 e critérios
-- ----------------------------------------------------------------------------
CREATE TABLE aco_moldes_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    componente VARCHAR(60) NOT NULL,
    acos_recomendados VARCHAR(200),
    dureza_hrc VARCHAR(60),
    obs TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO aco_moldes_bayer (componente, acos_recomendados, dureza_hrc, obs) VALUES
('Blocos/inserts de cavidade', 'P20, H13, S7, L6, A2, A6, P2, P6, 420SS', 'P20 30–36; 420SS 30–35 (médico 50–52)', NULL),
('Placas de cavidade', 'P20, H13, S7, 420SS', NULL, NULL),
('Placas de fixação', 'P20, H13, S7', NULL, NULL),
('Blocos/inserts de núcleo', 'P20, H13, S7, L6, A2, A6, P2, P6, 420SS', NULL, NULL),
('Pinos ejetor', 'H13 nitretado', NULL, NULL),
('Placas ejetoras', 'P20, H13, S7', NULL, NULL),
('Pinos guia / leader pins', 'O1, A2, P6 / H13 nitretado', NULL, NULL),
('Slides', 'P20, O1, O2, O6, A2, A6, P6 (nitretado)', NULL, NULL),
('Sprue bushings', 'O1, O2, L6, A2, A6, S7, P6', NULL, NULL),
('CRITÉRIO — base', 'P20 30–35 HRC; 420SS pré 30–35 (corrosão); 420SS temperado 50–52 (médico, sem carga abrasiva)', NULL, 'Resinas carregadas (vidro/mineral) exigem ≥54 HRC (H13, S7, D2).'),
('CRITÉRIO — alto desgaste', 'D2 54–56 HRC (runners/gates de materiais abrasivos); O-1/O-6/A-2/A-10 >56 HRC (aço-aço)', NULL, NULL),
('CRITÉRIO — alumínio', 'QC-7 + coatings >50 HRC (protótipos/produção moderada); inserts de aço em áreas de desgaste', NULL, NULL),
('CRITÉRIO — deslizamento', 'Superfícies deslizantes com dureza diferente por ≥2 HRC (menor dureza no componente mais barato/trocável)', NULL, NULL),
('CRITÉRIO — condutividade', 'BeCu/condutivos em áreas difíceis de resfriar (inseridos em aço mais duro)', NULL, NULL),
('CRITÉRIO — gloss', '≥30 HRC brilho moderado; >50 HRC alto brilho', NULL, NULL);

-- ----------------------------------------------------------------------------
-- BAYER 22. Acabamento e revestimento do molde — Cap. 7
-- ----------------------------------------------------------------------------
CREATE TABLE acabamento_molde_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO acabamento_molde_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-SUR-001','Polimento','Direção de ejeção',NULL,NULL,NULL,'—','Polir na direção da ejeção','Polir na direção da ejeção; 240–320 grit = escovado; alto brilho: pedras SiC 220→900 + pasta diamante 3 µm.','p.163'),
('BAYER-SUR-002','Textura','Spark erosion vs photoetch',NULL,NULL,NULL,'—','EDM arredondado','EDM/erosão texturas arredondadas (melhor resistência a riscos) vs photoetched (arestas finas; melhor replicação por resinas de baixa viscosidade PA6/PBT; PC/ABS arredondam a microtextura).','p.119; p.163'),
('BAYER-SUR-003','Textura','Uniformidade e draft',NULL,NULL,NULL,'—','Mesmo aço + tratamento','Textura uniforme: mesmo aço + mesmo tratamento térmico; +1 grau de draft por 0,0254 mm de textura.','p.119; p.163'),
('BAYER-SUR-004','Revestimentos','Flash chrome / hard chrome / Ni',NULL,NULL,NULL,'—','Corrosão/desgaste','Flash chrome e Ni eletrolítico <0,001 in (corrosão); hard chrome >0,002 in (materiais carregados); PTFE-modified (problemas de ejeção).','p.164'),
('BAYER-SUR-005','Textura — esconder defeitos',NULL,NULL,NULL,NULL,'—','Spark erosion','Spark-eroded textures escondem weld lines; perfis (linhas/xadrez) escondem read-through de ribs.','p.119');

-- ----------------------------------------------------------------------------
-- BAYER 23. Usinagem de plásticos — Cap. 5
-- ----------------------------------------------------------------------------
CREATE TABLE usinagem_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO usinagem_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-MCH-001','Furação','Ponta e velocidade',NULL,30,61,'m/min','100–200 fpm','Ponta 60–90 graus; 100–200 fpm (30–61 m/min); avanço ≤1/8 in: 0,001–0,002 in/rev; 1/8–1/4: 0,002–0,004; 1/4–1/2: 0,004–0,006; 1/2–1: 0,006–0,008; broca de 2 estágios; carbide; ar comprimido; sem óleo de corte.','p.97-98, Tab.5-2'),
('BAYER-MCH-002','Roscamento','Tapping',NULL,0,15,'m/min','~50 fpm','Furo p/ ~75% de rosca; NC (passo grosso); ~50 fpm (15 m/min); não roscar SAN.','p.99'),
('BAYER-MCH-003','Serra fita','Velocidade',NULL,305,610,'m/min','1000/1500/2000 fpm','Lâminas precision/standard <3,2 mm; buttress/skip >3,2 mm; 1000/1500/2000 fpm (305/457/610 m/min); PC +50% dentes/−33% velocidade; PA6 +25% dentes/+50% velocidade; serra circular 8–10 dentes/in (lâmina 4 in).','p.99-100, Tab.5-3'),
('BAYER-MCH-004','Punção/die','Folga',NULL,0.127,0.127,'mm','0,005 in','Folga ~0,005 in (0,127 mm); não usar em SAN; PC só seções finas.','p.100'),
('BAYER-MCH-005','Fresa','Faceamento/topo',NULL,NULL,NULL,'—','Tab. 5-4','Faceamento 1/8 in: 0,015 in/dente, 600–800 fpm; 1/16: 0,005, 800–1000; topo 1/4: 0,003, 250–500; 1/16: 0,002, 300–600; PC: avanço 5–10 in/min (127–254 mm/min), 100–200 sfm.','p.101-102, Tab.5-4'),
('BAYER-MCH-006','Alívio de tensões','PC',NULL,127,132,'C','260–270 F','Aquecer peça suportada a 260–270 F (127–132 C), 1/2 h por 0,2 in (5,08 mm) de espessura.','p.101'),
('BAYER-MCH-007','Torneamento','PC',NULL,NULL,NULL,'—','Rake 5–25','PC: rake 5–25 graus; folga 10–15 graus; raio do nariz 1/16–3/16 in; borda 1–2 graus acima do centro; DOC 0,003–0,012 in.','p.102, Tab.5-5'),
('BAYER-MCH-008','Laser','CO2',NULL,0.051,1.27,'mm','0,002–0,050 in','Furos 0,002–0,050 in (0,051–1,27 mm); cônico ~3 graus.','p.102'),
('BAYER-MCH-009','Lima','Dentes',NULL,NULL,NULL,'—','ABS/PC/PA/TPU','Dentes grossos ABS; single-hatched PC; não limar PA/TPU.','p.103'),
('BAYER-MCH-010','Rebarba/flash','Métodos',NULL,NULL,NULL,'—','Hot-air/vapor honing','Hot-air remelting, vapor honing; posicionar gate oculto; tumbling não serve p/ termoplásticos Bayer.','p.104');

-- ----------------------------------------------------------------------------
-- BAYER 24. Pintura, galvanoplastia e decoração — Cap. 6
-- ----------------------------------------------------------------------------
CREATE TABLE pintura_decoracao_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO pintura_decoracao_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-DEC-001','Tintas','Tipos',NULL,NULL,NULL,'—','PU/epóxi/vinílica/acrilica','PU flexível; epóxi duro/brilhante; vinílica borrachosa; acrílica frágil/anti-risco.','p.105'),
('BAYER-DEC-002','Cura','PC bake',NULL,NULL,120,'C','~250 F','PC tolera bake ~120 C (250 F); 2K pot life minutos.','p.106'),
('BAYER-DEC-003','Substratos','Semicristalinos',NULL,NULL,NULL,'—','Primer/pretreatment','Semicristalinos (PA, acetal, PP, PE) exigem primer/pretreatment; amorfos (PC, ABS) boa adesão; PC sensível a solventes (crazing/paint soak) perto de gates/linhas de solda.','p.106-107'),
('BAYER-DEC-004','Spray','Eletrostático',NULL,NULL,NULL,'—','Cobertura','Spray eletrostático melhora cobertura e reduz overspray.','p.107'),
('BAYER-DEC-005','Mascaramento','Distância da borda',NULL,3.175,3.175,'mm','1/8 in','Mascaramento ≥1/8 in (3,175 mm) da borda.','p.108'),
('BAYER-DEC-006','Film-insert','Primeira/segunda superfície',NULL,NULL,NULL,'—','Multi-cor','Film-insert molding: multi-cor em 1 passo; first-surface (protege gráfico) vs second-surface (protege do ambiente, risco no gate).','p.110-111'),
('BAYER-DEC-007','Galvanoplastia','Radios e cantos',NULL,0.254,1.5875,'mm','Borda ≥0,010 in; canto externo 1/16 in','Raio ≥0,010 in (0,254 mm) em bordas galvanizadas; 1/16 in (1,5875 mm) cantos externos; sem recessos profundos; crown 0,015 in/in; ABS grades plating; Triax/Bayblend razoável.','p.112-113'),
('BAYER-DEC-008','Metalização a vácuo','Espessura',NULL,1.5,1.5,'µm','1,5 µm típico','Metalização a vácuo ~1,5 µm (Al); sputtering melhor adesão/abrasão.','p.114'),
('BAYER-DEC-009','Blindagem EMI/RFI','Aberturas',NULL,NULL,NULL,'—','Overlap e ajuste','Aberturas determinam frequência escapada; overlap e ajuste apertado nas juntas; dedos de contato; UL 746C QMSS2/QMRX2.','p.115'),
('BAYER-DEC-010','Impressão','Métodos',NULL,NULL,NULL,'—','Pad/serigrafia/laser/hot stamp','Pad printing, serigrafia, laser (queima), hot stamping, dome printing (almofada silicone), sublimação penetra ~0,008 in (0,203 mm).','p.116-118'),
('BAYER-DEC-011','Textura','Esconder defeitos',NULL,NULL,NULL,'—','Spark erosion','Spark erosion arredondada; esconde weld lines; perfis (linhas/xadrez) escondem read-through de ribs.','p.119');

-- ----------------------------------------------------------------------------
-- BAYER 25. Custos de produção — Cap. 1
-- ----------------------------------------------------------------------------
CREATE TABLE custos_producao_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO custos_producao_bayer (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('BAYER-CST-001','Amortização de molde','Custo por peça',NULL,0.10,50,'USD/peça','50.000 USD/1.000 peças = 50 USD/peça; 500.000 peças = 0,10 USD/peça','Molde 50.000 USD amortizado: 1.000 peças = 50 USD/peça; 500.000 peças = 0,10 USD/peça.','p.11'),
('BAYER-CST-002','Redução de custo','Materiais e overhead',NULL,NULL,NULL,'—','Core-out, ribs, canais', 'Core-out de espessura; ribs p/ rigidez; canais otimizados; cores padrão; maximizar peças/hora; evitar seções espessas (ciclo); bom draft/resfriamento; mais cavidades.','p.15-17'),
('BAYER-CST-003','Scrap/retrabalho','Qualidade',NULL,NULL,NULL,'—','Seguir guidelines','Seguir guidelines; não sobre-especificar tolerâncias; ajustar molde p/ meio da faixa; não escolher molde por preço; protótipo antes do ferramental produtivo.','p.17-18'),
('BAYER-CST-004','Mão de obra','Degating e montagem',NULL,NULL,NULL,'—','Automatizar','Degating automático/posicionamento de gate; parting line orientada p/ rebarba menos crítica; automatizar montagem.','p.17');

-- ----------------------------------------------------------------------------
-- BAYER 26. Checklist de projeto de peça — p.169-170
-- ----------------------------------------------------------------------------
CREATE TABLE checklist_produto_bayer (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria VARCHAR(60) NOT NULL,
    item VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO checklist_produto_bayer (categoria, item) VALUES
('Material/Requisitos','Cargas: magnitude, duração, impacto, fadiga, desgaste.'),
('Material/Requisitos','Ambiente: temperatura, químicos, umidade, agentes de limpeza, lubrificantes, UV.'),
('Material/Requisitos','Especiais: transparência, pintabilidade, galvanoplastia, empenamento/encolhimento, inflamabilidade (UL 94), custo, aprovações (UL/FDA/USDA/NSF/MIL).'),
('Revisão do produto','Espessura: uniformidade, áreas espessas/finas, mudanças abruptas, picture framing, orientação.'),
('Revisão do produto','Fluxo: comprimento de fluxo, muito fino, thin-to-thick, racetracking.'),
('Revisão do produto','Cantos: cantos vivos, raio mínimo.'),
('Revisão do produto','Ribs: radii, draft, altura, espaçamento, espessura base.'),
('Revisão do produto','Bosses: radii, draft, DI/DO, espessura base, L/D.'),
('Revisão do produto','Linhas de solda: proximidade a carga, força vs carga, área visual.'),
('Revisão do produto','Draft: draw polish, profundidade de textura, mínimo 0,5 grau.'),
('Revisão do produto','Tolerâncias: geometria da peça, material, tool design (across parting line, slides).'),
('Montagem','Press fit: tolerâncias, hoop stress, retenção longa.'),
('Montagem','Snap fits: deformação admissível, força de montagem, braço cônico, múltiplas montagens.'),
('Montagem','Roscas moldadas: evitar feather edges, cantos vivos, pipe threads.'),
('Montagem','Ultrassom: energy director, shear joint, interferência.'),
('Montagem','Adesivos/solventes: cisalhamento vs topo, compatibilidade, vapores retidos.'),
('Montagem','Geral: tolerâncias empilhadas, rivets e inserts moldados, expansão térmica, compatibilidade de componentes.'),
('Molde','Empenamento: resfriamento (cantos), posicionamento de ejetores.'),
('Molde','Gates: tipo, tamanho, posição.'),
('Molde','Runners: tamanho e forma, sprue, balanceamento, cold-slug well, cantos vivos.'),
('Molde','Geral: draft, ejeção, cores finos/longos.'),
('Evitar/Preferir (p.170)','Raio mínimo 0,015 in em cantos; evitar cantos vivos; evitar undercut; draft mínimo 0,5 grau; preferir thread cutting a forming em PC/PC blends; lead-in 1/32 in; ribs: evitar muito espessa/muito próxima/muito alta; boss height vs wall; gussets thick; ejection pins e mold cooling adequados.');

INSERT INTO versoes_sistema (versao, data_lancamento, descricao, arquivo_download) VALUES
('1.1.0','2026-11-17','Inclusão do guia Bayer Thermoplastics Part and Mold Design (KU-GE028, 174 pág.) — 26 tabelas BAYER-xxx.','schema_banco_dados.sql');

-- ============================================================================
-- FONTE 5 — XOMETRY: "Design Guidelines and Best Practices for Injection Molding"
-- (Xometry Team, 86 páginas) — guia prático de DFM e moldagem
-- ============================================================================

-- ----------------------------------------------------------------------------
-- XOMETRY 1. Seleção de material e espessura recomendada (p.16-18, p.33)
-- ----------------------------------------------------------------------------
CREATE TABLE materiais_xometry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    categoria VARCHAR(40),
    material VARCHAR(60) NOT NULL,
    caracteristicas TEXT,
    aplicacoes TEXT,
    custo_relativo VARCHAR(10),
    espessura_min_mm DECIMAL(8,3),
    espessura_max_mm DECIMAL(8,3),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO materiais_xometry (categoria, material, caracteristicas, aplicacoes, custo_relativo, espessura_min_mm, espessura_max_mm) VALUES
('Commodity','Polipropileno (PP)','Boa resistência química e à umidade; boa elasticidade e impacto.','Dobradiças vivas, ventiladores, tampas snap-over, tubulação médica.','$',0.89,3.81),
('Commodity','Poliestireno (PS)','Leve, barato, resistente a umidade e bactéria; claro, duro, frágil.','Utensílios, recipientes, óptica, brinquedos.','$',0.89,3.81),
('Commodity','ABS','Leve, resistente a químicos, ambientalmente amigável; alto impacto e tração.','Tanques de combustível, isolantes de conector, recipientes de alimento.','$',1.14,3.56),
('Commodity','Acrílico (PMMA)','Forte, leve, resistente a impacto, ópticamente claro, UV e intempérie.','Tubos de luz, lentes, abajures, fibras ópticas, placas.','$',0.64,12.70),
('Commodity','Polietileno (PE)','Resistente a químicos, food-safe, alto impacto, boa a baixa temperatura, isolante elétrico.','Isolamento elétrico, recipientes domésticos, brinquedos, baldes, garrafas.','$$',0.76,5.08),
('Commodity','PVC','Resistente a intempérie, químicos, corrosão e impacto; rígido ou borracha.','Tubos, esquadrias, garrafas, caixas de distribuição elétrica.','$$',NULL,NULL),
('Engenharia','Policarbonato (PC)','Forte, leve, transparente natural; estável em ampla faixa de temperatura.','Automotivo, eletrônica, telecomunicações.','$',1.02,3.81),
('Engenharia','PC/ABS','Alto impacto, flexão e resistência térmica; mais flexível que PC puro.','Painéis, caixas eletrônicas, caixas médicas, corpos de ferramentas.','$',NULL,NULL),
('Engenharia','PA (Nylon)','Alta resistência térmica, abrasão, tração e fadiga.','Instrumentação médica/química, utensílios, HVAC, fluidos, elétrica/iluminação.','$$',0.76,2.92),
('Engenharia','PBT','Alta tração, rigidez, resistência a manchas; bom creep e baixa absorção de umidade.','Mancais deslizantes, engrenagens, cames, bicos de secador, aspiradores, maçanetas.','$$',NULL,NULL),
('Engenharia','Acetal (POM/Delrin)','Alta tração, rigidez e tenacidade; bom impacto mesmo a baixa temp; baixa absorção de umidade, boa usinabilidade, creep e estabilidade dimensional.','Engrenagens, bombas, impelidores, correntes, dispensadores de sabão, pás de ventilador, switches automotivos.','$$',0.76,3.05),
('Elastômero','TPE','Alto impacto, flexível, borracha; excelente resistência química e à intempérie.','Equipamentos médicos, ferramentas, utilidades domésticas, telefones, mice, correias.','$',NULL,NULL),
('Elastômero','TPU','Elasticidade borracha com boa capacidade de carga; excelente abrasão, adesão a substratos, retardante de chama, resistência microbiana.','Capas de cabos, mangueiras, tubos, revestimentos têxteis.','$',2.03,19.05),
('Elastômero','TPV (Santoprene)','Borracha sintética com resistência térmica, compressão e elasticidade.','Pneus, mangueiras, grips, maçanetas, tubulação médica, gaxetas.','$$',NULL,NULL),
('High-performance','PEI (ULTEM)','Extrema resistência térmica e a chama, baixa fumaça, alta rigidez e dureza.','Instrumentação médica/química, utilidades, HVAC, fluidos, elétrica/iluminação.','$$$',NULL,NULL),
('High-performance','PEEK','Alta tração e resistência a químicos e degradação térmica; biocompatibilidade, UV, radiolucência, resistência a gama.','Implantes médicos, mancais, pistões, bombas, isolamento elétrico, válvulas e gaxetas.','$$$',NULL,NULL),
('Amorfo vs semicristalino','—','Semicristalinos: ordenados, maior resistência química/desgaste/mecânica, mais difíceis de processar, maior retração. Amorfos: desordenados, fáceis de processar, transparentes/translúcidos, menor retração.','—','—',NULL,NULL);

-- ----------------------------------------------------------------------------
-- XOMETRY 2. Acabamentos de superfície (SPI/VDI/Mold-Tech)
-- ----------------------------------------------------------------------------
CREATE TABLE acabamentos_superficie_xometry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    padrao VARCHAR(20) NOT NULL,
    codigo VARCHAR(20),
    descricao VARCHAR(120),
    ra_min_um DECIMAL(8,3),
    ra_max_um DECIMAL(8,3),
    materiais_exemplo TEXT,
    custo_adicional VARCHAR(10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO acabamentos_superficie_xometry (padrao, codigo, descricao, ra_min_um, ra_max_um, materiais_exemplo, custo_adicional) VALUES
('SPI','A-1','Grade #3, 6000 Grit Diamond Buff — alto brilho',0.012,0.025,'Acrílico','$$$$$'),
('SPI','A-2','Grade #6, 3000 Grit Diamond Buff — alto brilho',0.025,0.050,'Acrílico, PC','$$$$'),
('SPI','A-3','Grade #15, 1200 Grit Diamond Buff — baixo brilho',0.050,0.100,'ABS, Acrílico, PS, Nylon, PC','$$$$'),
('SPI','B-1','600 Grit Paper — brilho médio',0.050,0.100,'ABS, Acrílico, PP, PS, HDPE, Nylon, PC','$$'),
('SPI','B-2','400 Grit Paper — brilho médio',0.100,0.150,'ABS, Acrílico, PP, PS, HDPE, Nylon, PC','$$'),
('SPI','B-3','320 Grit Paper — brilho médio-baixo',0.280,0.320,'ABS, Acrílico, PP, PS, HDPE, Nylon','$$'),
('SPI','C-1','600 Stone — baixo brilho',0.350,0.400,'ABS, Acrílico, PP, PS, HDPE, Nylon, TPU','$'),
('SPI','C-2','400 Stone — baixo brilho',0.450,0.550,'ABS, Acrílico, PP, PS, HDPE, Nylon, TPU','$'),
('SPI','C-3','320 Stone — baixo brilho',0.630,0.700,'ABS, Acrílico, PP, PS, HDPE, Nylon, TPU','$'),
('SPI','D-1','Dry Blast Glass Bead — satin',0.800,1.000,'ABS, PP, PS, HDPE, Nylon, PC, TPU','$'),
('SPI','D-2','Dry Blast #240 Oxide — dull',1.000,2.800,'ABS, PP, PS, HDPE, Nylon, TPU','$'),
('SPI','D-3','Dry Blast #24 Oxide — dull',3.200,18.000,'ABS, PP, PS, HDPE, Nylon, TPU','$'),
('VDI','12','600 Stone — baixo brilho',0.400,0.400,NULL,'$'),
('VDI','15','400 Stone — baixo brilho',0.560,0.560,NULL,'$'),
('VDI','18','Dry Blast Glass Bead — soft satin',0.800,0.800,NULL,'$'),
('VDI','21','Dry Blast #240 Oxide — light satin',1.120,1.120,NULL,'$'),
('VDI','24','Dry Blast #240 Oxide — satin',1.600,1.600,NULL,'$'),
('VDI','27','Dry Blast #240 Oxide — light matte',2.240,2.240,NULL,'$'),
('VDI','30','Dry Blast #24 Oxide — medium matte',3.150,3.150,NULL,'$'),
('VDI','33','Dry Blast #24 Oxide — textured matte',4.500,4.500,NULL,'$'),
('VDI','36','Dry Blast #24 Oxide — fine grain',6.300,6.300,NULL,'$'),
('VDI','39','Dry Blast #24 Oxide — medium grain',9.000,9.000,NULL,'$'),
('VDI','42','Dry Blast #24 Oxide — coarse grain',12.500,12.500,NULL,'$'),
('VDI','45','Dry Blast #24 Oxide — very coarse grain',18.000,18.000,NULL,'$'),
('Mold-Tech','MT-11010','Dull matte finish',NULL,NULL,'Profundidade 0,001 in; draft mínimo 1,5 graus','$$$'),
('Mold-Tech','MT-11020','Coarse matte finish',NULL,NULL,'Profundidade 0,0015 in; draft mínimo 2,25 graus','$$$'),
('Mold-Tech','MT-11030','Coarse matte finish',NULL,NULL,'Profundidade 0,002 in; draft mínimo 3 graus','$$$');

-- ----------------------------------------------------------------------------
-- XOMETRY 3. Regras de projeto (DFM) — Cap. Design Guidelines
-- ----------------------------------------------------------------------------
CREATE TABLE regras_projeto_xometry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_projeto_xometry (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('XY-DRAFT-001','Draft','Near-vertical',NULL,0.5,0.5,'graus','Requisito near-vertical','0,5 graus p/ near-vertical; 2 graus geral; 3 graus shutoff; 3 graus textura leve; 5+ graus textura média/pesada.','p.32'),
('XY-DRAFT-002','Draft','Textura pesada',NULL,5,NULL,'graus','Textura média/pesada','Textura pesada: draft ≥5 graus; Mold-Tech: +1,5 graus por 0,001 in de textura (vs Bayer +1 grau).','p.28; p.32'),
('XY-WALL-001','Espessura de parede','Faixa geral',NULL,2,4,'mm','Muitas aplicações','Faixa geral 2–4 mm; tabela por material (ABS 1,14–3,56; Acetal 0,76–3,05; Acrílico 0,64–12,70; LCP 0,76–3,05; LFRT 1,91–27,94; Nylon 0,76–2,92; PC 1,02–3,81; Poliéster 0,64–3,18; PE 0,76–5,08; PPSU 0,51–4,57; PP 0,89–3,81; PS 0,89–3,81; PU 2,03–19,05 mm).','p.33'),
('XY-WALL-002','Consistência','Variação máxima',NULL,0,15,'%','Nominal','Variações de espessura não devem exceder 15% da espessura nominal (evitar warping/sink).','p.64'),
('XY-WALL-003','Consistência','Transição',NULL,3,NULL,'x diferença de espessura','Transição','Transição suave: comprimento ~3x a diferença de espessuras.','p.35'),
('XY-RAD-001','Radii/fillets','Cantos',NULL,NULL,NULL,'—','Consistência de parede','Raio interno = metade da espessura da parede; raio externo = 1,5x a espessura da parede; manter espessura constante no arredondamento.','p.36'),
('XY-RIB-001','Costelas','Espessura',NULL,40,60,'% da parede principal','Regra geral','Espessura da rib 40–60% da parede principal.','p.37'),
('XY-RIB-002','Costelas','Altura',NULL,0,3,'x espessura da parede','Máximo','Altura da rib <3x espessura da parede.','p.37'),
('XY-RIB-003','Costelas','Draft',NULL,0.25,0.5,'graus','Ejeção','Draft 0,25–0,5 grau p/ ribs.','p.37'),
('XY-RIB-004','Costelas','Raio na base',NULL,25,NULL,'% da parede principal','Mínimo','Raio na base da rib ≥1/4 da parede principal.','p.37'),
('XY-RIB-005','Costelas','Espaçamento',NULL,4,NULL,'x espessura da rib','Mínimo','Distância entre ribs e paredes adjacentes ≥4x espessura da rib.','p.37'),
('XY-BOSS-001','Bosses','OD x parafuso',NULL,2.5,2.5,'x diâmetro do parafuso','Self-tapping','OD do boss ≈2,5x diâmetro do parafuso (Xometry).','p.38'),
('XY-GUS-001','Gussets','Espessura',NULL,0,60,'% da espessura total','Máximo','Gussets não devem exceder 60% da espessura total da peça.','p.38'),
('XY-HINGE-001','Dobradiça viva','Material',NULL,NULL,NULL,'—','PP/PE/Nylon','PP mais adequado (flexibilidade e fadiga); PE em segundo; Nylon p/ engenharia (maior resistência e temperatura).','p.39-40'),
('XY-HINGE-002','Dobradiça viva','Espessura',NULL,0.25,0.5,'mm','PP/PE','0,25–0,5 mm p/ plásticos flexíveis (PP/PE).','p.40'),
('XY-HINGE-003','Dobradiça viva','Raio',NULL,0.75,1.5,'mm','Ambos os lados','Raio 0,75–1,50 mm de cada lado p/ reduzir concentração de tensão.','p.40'),
('XY-HINGE-004','Dobradiça viva','Alívio (relief)',NULL,0.2,0.2,'mm','Verso','Alívio de 0,2 mm no verso, estendendo por toda a largura; usar radii nas transições.','p.40'),
('XY-HINGE-005','Dobradiça viva','Comprimento',NULL,1.5,1.5,'mm','Típico','Comprimento da dobradiça ~1,5 mm (ajustável).','p.40'),
('XY-SNAP-001','Snap-fits','Raio na base',NULL,0.38,NULL,'mm','Mínimo 0,015 in','Raio na base do cantilever ≥ metade da espessura da base e ≥0,38 mm (0,015 in).','p.46'),
('XY-SNAP-002','Snap-fits','Taper do cantilever',NULL,50,50,'% da base','Ponta','Reduzir espessura linearmente para a ponta ter metade da espessura da base.','p.46'),
('XY-SNAP-003','Snap-fits','Largura mínima da ponta',NULL,5,NULL,'mm','Mínimo','Largura da ponta ≥5 mm p/ maior resistência.','p.46'),
('XY-SNAP-004','Snap-fits','Gap entre superfícies de acoplamento',NULL,0.2,0.4,'mm','0,2 apertado; 0,3 fechado; 0,4 deslizante/pivô','Gap: 0,2 mm apertado; 0,3 mm fechado; 0,4 mm deslizante/pivô.','p.46'),
('XY-SNAP-005','Snap-fits','Cantilever na borda',NULL,NULL,NULL,'—','Evitar undercut','Mover cantilevers para a borda externa p/ evitar undercuts e ferramental complexo; ou projetar slot sob o gancho.','p.46'),
('XY-TEXT-001','Textos e símbolos','Altura emboss',NULL,0.5,0.5,'mm','Recomendado','Altura do texto embossado ~0,5 mm; fonte 20 pt; sans-serif; alinhar perpendicularmente à PL ou linha de tiragem.','p.51'),
('XY-GATE-001','Gate','Posicionamento',NULL,NULL,NULL,'—','Seção mais espessa','Posicionar gate na seção mais espessa, longe de áreas de alto stress/impacto; múltiplos gates p/ peças grandes/complexas; gate na PL reduz vestígio.','p.52-53'),
('XY-GATE-002','Tipos de gate','Comuns',NULL,NULL,NULL,'—','Edge/hot tip/fan/pin','Edge (mais comum, pequeno vestígio); hot tip (massa, vestígio visível); fan (grandes, espessura variável); pin (alta velocidade, estética).','p.53'),
('XY-PL-001','Parting line','Posicionamento',NULL,NULL,NULL,'—','Otimizar visibilidade','Posicionar PL ao longo de arestas (rims, botões, tampas) p/ minimizar visibilidade e facilitar ejeção; evitar áreas funcionais críticas.','p.54-55'),
('XY-UNC-001','Undercuts','Sliding cores',NULL,1,NULL,'graus','Draft mínimo','Sliding cores: draft ≥1 grau nas superfícies de contato; folga suficiente p/ movimento; minimizar uso.','p.58'),
('XY-UNC-002','Undercuts','Shut-off',NULL,3,5,'graus','Draft mínimo','Shut-off: draft 3–5 graus; alternativa de baixo custo a sliding cores.','p.59'),
('XY-UNC-003','Undercuts','Bump-offs',NULL,NULL,NULL,'—','Materiais flexíveis','Bump-offs: eficazes em TPE/PE/PP (flexíveis, não carregados); menos adequados p/ materiais rígidos/carregados.','p.60'),
('XY-TOL-001','Tolerâncias','Molde',NULL,0.13,0.13,'mm','±0,005 in','Molde usinado ±0,005 in (0,13 mm) salvo especificação mais apertada.','p.61'),
('XY-TOL-002','Tolerâncias','Encolhimento',NULL,0.05,0.05,'mm/mm','±0,002 in/in','Variação devido ao encolhimento ≈ ±0,002 in/in (0,05 mm/mm).','p.61'),
('XY-TOL-003','Tolerâncias','Repetibilidade',NULL,0.10,0.10,'mm','±0,004 in','Repetibilidade peça a peça tipicamente < ±0,004 in (0,10 mm).','p.61'),
('XY-TOL-004','Tolerâncias','Peça grande',NULL,NULL,NULL,'—','Exemplo','Peça ABS de 4 in → tolerância ~ ±0,010–0,011 in (0,28 mm).','p.61'),
('XY-TOL-005','Tolerâncias','Considerações',NULL,NULL,NULL,'—','Material/parede', 'Semicristalinos (Nylon, PP) têm maior retração que amorfos (ABS, PC); aplicar tolerâncias apertadas só em dimensões críticas; paredes uniformes; considerar desgaste do molde em produção longa.','p.62');

-- ----------------------------------------------------------------------------
-- XOMETRY 4. Defeitos comuns e prevenção
-- ----------------------------------------------------------------------------
CREATE TABLE defeitos_injecao_xometry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    defeito VARCHAR(60) NOT NULL,
    descricao TEXT,
    causas TEXT,
    prevencao TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO defeitos_injecao_xometry (defeito, descricao, causas, prevencao) VALUES
('Warping (empenamento)','Distorção por resfriamento/encolhimento não uniforme.','Espessura não uniforme; resfriamento desigual.','Variação de espessura ≤15% do nominal; transições suaves/tapered.'),
('Sink marks (marcas de retração)','Afundamentos em seções espessas.','Superfície externa esfria antes do interior; interior encolhe puxando a superfície.','Espessura uniforme; ribs/ocós p/ remover material; aditivos de retração.'),
('Knit lines (linhas de solda)','Linhas fracas onde frentes de fluxo se encontram.','Fluxo se divide em obstáculos (furo, boss, insert) e reúne frio.','Ajustar posicionamento do gate e geometria; resinas de melhor fluxo; reforços.'),
('Drag marks (marcas de arrasto)','Arranhões/riscos na ejeção.','Fricção do desmolde; paredes verticais; draft insuficiente.','Draft 1–3 graus por lado; superfície mais lisa em áreas críticas; evitar undercuts/features que resistam.'),
('Splay (estrias/prateado)','Estrias prateadas na superfície.','Umidade, ar aprisionado, voláteis na resina.','Secagem adequada (nylon, PET); velocidade/pressão otimizadas; material limpo; ventilação/degassing do molde.');

-- ----------------------------------------------------------------------------
-- XOMETRY 5. Overmolding / insert molding / compression molding
-- ----------------------------------------------------------------------------
CREATE TABLE regras_overmolding_xometry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(30) UNIQUE,
    tema VARCHAR(120),
    parametro VARCHAR(180),
    material VARCHAR(80),
    valor_min DECIMAL(12,4),
    valor_max DECIMAL(12,4),
    unidade VARCHAR(30),
    condicao VARCHAR(200),
    descricao TEXT,
    referencia VARCHAR(60),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO regras_overmolding_xometry (codigo, tema, parametro, material, valor_min, valor_max, unidade, condicao, descricao, referencia) VALUES
('XY-OVM-001','Overmolding','Espessura de parede',NULL,1.5,3.0,'mm','0,060–0,120 in','Espessuras 1,5–3,0 mm (0,060–0,120 in) geralmente dão melhor adesão.','p.81'),
('XY-OVM-002','Overmolding','Raio em cantos',NULL,0.5,NULL,'mm','Mínimo 0,020 in','Raio ≥0,5 mm (0,020 in) em cantos p/ reduzir tensões localizadas.','p.81'),
('XY-OVM-003','Overmolding','Seções espessas de TPE',NULL,NULL,NULL,'—','Core-out','Core-out de seções espessas de TPE p/ minimizar encolhimento, peso e ciclo.','p.81'),
('XY-OVM-004','Overmolding','Transição de espessura',NULL,NULL,NULL,'—','Gradual','Transições graduais entre espessuras p/ evitar problemas de fluxo (back fills, gas traps).','p.81'),
('XY-OVM-005','Overmolding','TPE vs substrato',NULL,NULL,NULL,'—','TPE mais fino','TPE/TPV mais fino que o substrato p/ evitar empenamento (especialmente peças planas/longas).','p.81'),
('XY-OVM-006','Overmolding','Adesão',NULL,NULL,NULL,'—','Mecânica/química','Overmold precisa de adesão mecânica ou química ao substrato; escolher materiais que a permitam.','p.81'),
('XY-OVM-007','Insert molding','Benefícios',NULL,NULL,NULL,'—','Elimina montagem','Elimina montagem pós-processo; reduz custo, tamanho/peso; melhora confiabilidade e resistência (roscas metálicas).','p.82'),
('XY-OVM-008','Compression molding','Aplicação',NULL,NULL,NULL,'—','Termofixos/borracha','Para borracha/termofixos com paredes espessas/irregulares (solados, capas, utensílios de silicone).','p.83');

-- ----------------------------------------------------------------------------
-- XOMETRY 6. Padrões de moldagem Xometry
-- ----------------------------------------------------------------------------
CREATE TABLE padroes_xometry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    item VARCHAR(120) NOT NULL,
    valor VARCHAR(120),
    obs TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO padroes_xometry (item, valor, obs) VALUES
('Tolerância de usinagem do molde','±0,005 in (0,13 mm)','Salvo especificação mais apertada.'),
('Encolhimento adicional','±0,002 in/in (0,05 mm/mm)','Para cálculo da retração.'),
('Repetibilidade peça a peça','< ±0,004 in (0,10 mm)','Típico.'),
('First article','10 peças','Pode variar por tamanho/origem/material.'),
('Lead time','First article shipment','Tempo de produção restante confirmado após aprovação do first article.'),
('Cor','Sem garantia de match perfeito Pantone','—'),
('Pressupostos de projeto','Draft, radii e coring adequados','A critério da Xometry, salvo discussão explícita.'),
('Estratégia de ferramental','Cores, side actions e estratégia','A critério da Xometry, salvo discussão explícita.'),
('Gating/ejeção/knit lines/parting lines','A critério da Xometry','Salvo discussão explícita.'),
('Materiais','Prefere lista padrão p/ cotação rápida','Materiais do cliente podem ser aceitos.'),
('Preenchimento','Família de materiais','Moldes família economizam custo mas têm maior taxa de defeito.'),
('Runner','Cold vs hot','Cold: baixo volume, baixo custo de molde, vestígio; hot: alto volume, baixo desperdício, maior custo de molde/manutenção.'),
('Aditivos e cargas','Tipos','Fibras de vidro/carbono (resistência/rigidez/impacto, mais frágil); cerâmicos (condutividade térmica); talco/carbonato de cálcio (redução de custo); colorantes; retardantes de chama/UV.'),
('Enchimento','Orientação de fibra','Marcas de orientação ao redor do gate (circular); mitigar com posicionamento do gate e fluxo uniforme.');

INSERT INTO versoes_sistema (versao, data_lancamento, descricao, arquivo_download) VALUES
('1.2.0','2026-11-17','Inclusão do guia Xometry Design Guidelines and Best Practices for Injection Molding (86 pág.) — 7 tabelas XY-xxx + acabamentos SPI/VDI/Mold-Tech.','schema_banco_dados.sql');

SELECT 'Banco de dados criado com sucesso — v1.2.0 (Boothroyd + Bayer + Xometry).' AS msg;