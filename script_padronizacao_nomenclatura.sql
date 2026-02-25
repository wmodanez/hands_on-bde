-- =====================================================
-- SCRIPT DE PADRONIZAÇÃO DE NOMENCLATURA
-- =====================================================
-- Data: 25/02/2026
-- Versão: 2.0
-- Banco de dados: imp
-- Objetivo: Renomear tabelas e colunas conforme padrão definido,
--           criar estrutura de regiões de trabalho por órgão
--           (Snowflake parcial + SCD Tipo 2)
-- =====================================================
-- 
-- IMPORTANTE: Este script deve ser executado ANTES do script
-- de criação de PKs e FKs (criar_chaves_primarias_estrangeiras_v2.sql)
--
-- =====================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- =====================================================
-- PARTE 1: RENOMEAR COLUNAS (antes de renomear tabelas)
-- =====================================================

-- ----- dim_aspecto (tb_aspecto) -----
ALTER TABLE tb_aspecto 
    CHANGE COLUMN cod_asp aspecto_id INT NOT NULL,
    CHANGE COLUMN nome_asp aspecto_nome VARCHAR(50);

-- ----- dim_nota (tb_nota) -----
ALTER TABLE tb_nota 
    CHANGE COLUMN nota_cod nota_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN nota_nome nota_txt TEXT NOT NULL;

-- ----- dim_fonte (tb_fonte) -----
ALTER TABLE tb_fonte 
    CHANGE COLUMN fnt_cod fonte_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN fnt_sigla fonte_sigla VARCHAR(20),
    CHANGE COLUMN fnt_nome fonte_nome VARCHAR(255);

-- ----- dim_unidade (tb_unidade) -----
ALTER TABLE tb_unidade 
    CHANGE COLUMN unid_cod unidade_id SMALLINT NOT NULL,
    CHANGE COLUMN unid_nome unidade_nome VARCHAR(150);

-- ----- dim_localidade (tb_localidade) -----
ALTER TABLE tb_localidade 
    CHANGE COLUMN loc_cod localidade_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN loc_pai localidade_pai_id SMALLINT UNSIGNED,
    CHANGE COLUMN loc_nome localidade_nome VARCHAR(250),
    CHANGE COLUMN loc_nivel localidade_nivel TINYINT UNSIGNED,
    CHANGE COLUMN loc_ordem localidade_ordem VARCHAR(255),
    CHANGE COLUMN loc_cep_cod_adm localidade_cep_adm VARCHAR(8),
    CHANGE COLUMN loc_cod_ibge localidade_cod_ibge VARCHAR(8),
    CHANGE COLUMN loc_reg_plan regiao_planejamento_id SMALLINT,
    CHANGE COLUMN loc_id_sig sig_id SMALLINT,
    CHANGE COLUMN loc_reg_plan_macro_saude regiao_macro_saude_id SMALLINT,
    CHANGE COLUMN loc_reg_plan_micro_saude regiao_micro_saude_id SMALLINT;

-- ----- dim_variavel (tb_variavel) -----
ALTER TABLE tb_variavel 
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN var_cod_old variavel_cod_legado VARCHAR(8),
    CHANGE COLUMN var_ordem variavel_ordem INT UNSIGNED,
    CHANGE COLUMN unid_cod unidade_id SMALLINT,
    CHANGE COLUMN var_nome variavel_nome VARCHAR(250),
    CHANGE COLUMN var_periodo variavel_periodo VARCHAR(250),
    CHANGE COLUMN var_ultano variavel_ultimo_ano YEAR,
    CHANGE COLUMN var_def variavel_definicao_txt TEXT,
    CHANGE COLUMN var_historico variavel_historico_txt VARCHAR(250),
    CHANGE COLUMN var_mapa_possivel mapa_disponivel_ind TINYINT,
    CHANGE COLUMN var_nome_grafico grafico_nome VARCHAR(200),
    CHANGE COLUMN var_nome_grafico2 grafico_nome_alt VARCHAR(200),
    CHANGE COLUMN var_grafico grafico_disponivel_ind TINYINT,
    CHANGE COLUMN var_grafico_ordem grafico_ordem TINYINT,
    CHANGE COLUMN var_mascara valor_mascara VARCHAR(10),
    CHANGE COLUMN var_agregacao agregacao_tipo SMALLINT,
    CHANGE COLUMN var_funcao funcao_id SMALLINT UNSIGNED,
    CHANGE COLUMN var_variavel variavel_pai_id INT UNSIGNED,
    CHANGE COLUMN var_campo campo_id SMALLINT UNSIGNED,
    CHANGE COLUMN var_asp aspecto_id INT,
    CHANGE COLUMN var_sig sig_codigo VARCHAR(8),
    CHANGE COLUMN var_geo geo_disponivel_ind TINYINT(1),
    CHANGE COLUMN var_estatistica_geo estatistica_geo_ind TINYINT(1);

-- ----- dim_base_cartografica (tb_base_cart) -----
ALTER TABLE tb_base_cart 
    CHANGE COLUMN cod_base base_cartografica_id INT NOT NULL,
    CHANGE COLUMN nome_base base_cartografica_nome VARCHAR(25),
    CHANGE COLUMN ano base_ano VARCHAR(50),
    CHANGE COLUMN nro_munic municipio_qtd INT;

-- ----- dim_territorio (tb_rel_ter) -----
ALTER TABLE tb_rel_ter 
    CHANGE COLUMN ter_cod territorio_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN ter_tipo territorio_tipo TINYINT UNSIGNED;

-- ----- fact_indicador (tb_dados) -----
-- Apenas as colunas chave, os d_YYYY serão mantidos até normalização
ALTER TABLE tb_dados 
    CHANGE COLUMN loc_cod localidade_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL;

-- ----- rel_base_ponto (tb_base_cart_ptos) -----
ALTER TABLE tb_base_cart_ptos 
    CHANGE COLUMN Cod_loc localidade_id INT NOT NULL,
    CHANGE COLUMN base base_cartografica_id INT NOT NULL,
    CHANGE COLUMN PtoX ponto_x INT,
    CHANGE COLUMN PtoY ponto_y INT;

-- ----- rel_variavel_fonte (tb_rel_var_fnt) -----
ALTER TABLE tb_rel_var_fnt 
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN fnt_cod fonte_id SMALLINT UNSIGNED NOT NULL;

-- ----- rel_variavel_nota (tb_rel_var_nota) -----
ALTER TABLE tb_rel_var_nota 
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN nota_cod nota_id SMALLINT UNSIGNED NOT NULL;

-- ----- rel_territorio_variavel (tb_rel_ter_var) -----
ALTER TABLE tb_rel_ter_var 
    CHANGE COLUMN ter_cod territorio_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN var_tipo relacao_tipo TINYINT UNSIGNED;

-- ----- aux_localidade_hierarquia (tb_loc_pai) -----
ALTER TABLE tb_loc_pai 
    CHANGE COLUMN loc_cod localidade_id INT NOT NULL,
    CHANGE COLUMN loc_pai localidade_pai_id INT,
    CHANGE COLUMN loc_reg regiao_id INT;

-- ----- aux_localidade_historico (tb_localidade_historico) -----
ALTER TABLE tb_localidade_historico 
    CHANGE COLUMN loc_cod localidade_id SMALLINT NOT NULL,
    CHANGE COLUMN loc_historico historico_txt VARCHAR(10000);

-- ----- aux_localidade_regiao_saude (tb_localidade_regiao_planejamento_saude) -----
ALTER TABLE tb_localidade_regiao_planejamento_saude 
    CHANGE COLUMN loc_cod_ibge localidade_cod_ibge VARCHAR(8),
    CHANGE COLUMN loc_nome localidade_nome VARCHAR(250),
    CHANGE COLUMN loc_reg_plan_macro_saude regiao_macro_saude_id SMALLINT,
    CHANGE COLUMN loc_nome_reg_plan_macro_saude regiao_macro_saude_nome VARCHAR(50),
    CHANGE COLUMN loc_reg_plan_micro_saude regiao_micro_saude_id SMALLINT,
    CHANGE COLUMN loc_nome_reg_plan_micro_saude regiao_micro_saude_nome VARCHAR(50);

-- ----- cfg_consulta (tb_consulta) -----
ALTER TABLE tb_consulta 
    CHANGE COLUMN con_cod consulta_id BIGINT UNSIGNED NOT NULL,
    CHANGE COLUMN con_nome consulta_nome VARCHAR(250),
    CHANGE COLUMN con_usu usuario_id BIGINT UNSIGNED,
    CHANGE COLUMN con_vars variaveis_json TEXT NOT NULL,
    CHANGE COLUMN con_locs localidades_json TEXT NOT NULL,
    CHANGE COLUMN con_anos anos_json TEXT NOT NULL,
    CHANGE COLUMN con_ordem ordem_json VARCHAR(250);

-- ----- log_busca (tb_log_busca) -----
ALTER TABLE tb_log_busca 
    CHANGE COLUMN log_data busca_dh TIMESTAMP NOT NULL,
    CHANGE COLUMN log_busca busca_termo VARCHAR(255);

-- ----- log_erro_movimento (tb_erro_mvto) -----
ALTER TABLE tb_erro_mvto 
    CHANGE COLUMN seq_mvto movimento_seq BIGINT,
    CHANGE COLUMN seq_cpo campo_seq TINYINT,
    CHANGE COLUMN msg_erro erro_msg VARCHAR(100);

-- ----- Tabelas vazias -----

-- tb_dados_mensal
ALTER TABLE tb_dados_mensal 
    CHANGE COLUMN loc_cod localidade_id SMALLINT,
    CHANGE COLUMN var_cod variavel_id SMALLINT;

-- tb_infmun
ALTER TABLE tb_infmun 
    CHANGE COLUMN loc_cod localidade_id SMALLINT UNSIGNED;

-- tb_var_calculado
ALTER TABLE tb_var_calculado 
    CHANGE COLUMN var_cod variavel_id SMALLINT;

-- tb_var_produto
ALTER TABLE tb_var_produto 
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED;


-- =====================================================
-- PARTE 2: RENOMEAR TABELAS
-- =====================================================

-- Tabelas de Dimensão
RENAME TABLE tb_aspecto TO dim_aspecto;
RENAME TABLE tb_nota TO dim_nota;
RENAME TABLE tb_fonte TO dim_fonte;
RENAME TABLE tb_unidade TO dim_unidade;
RENAME TABLE tb_localidade TO dim_localidade;
RENAME TABLE tb_variavel TO dim_variavel;
RENAME TABLE tb_base_cart TO dim_base_cartografica;
RENAME TABLE tb_rel_ter TO dim_territorio;

-- Tabelas de Fato
RENAME TABLE tb_dados TO fact_indicador;
RENAME TABLE tb_dados_mensal TO fact_indicador_mensal;

-- Tabelas de Relacionamento
RENAME TABLE tb_rel_var_fnt TO rel_variavel_fonte;
RENAME TABLE tb_rel_var_nota TO rel_variavel_nota;
RENAME TABLE tb_rel_ter_var TO rel_territorio_variavel;
RENAME TABLE tb_base_cart_ptos TO rel_base_ponto;

-- Tabelas Auxiliares
RENAME TABLE tb_loc_pai TO aux_localidade_hierarquia;
RENAME TABLE tb_localidade_historico TO aux_localidade_historico;
RENAME TABLE tb_localidade_regiao_planejamento_saude TO aux_localidade_regiao_saude;
RENAME TABLE tb_infmun TO aux_info_municipio;

-- Tabelas de Configuração
RENAME TABLE tb_consulta TO cfg_consulta;
RENAME TABLE tb_var_calculado TO cfg_variavel_calculada;
RENAME TABLE tb_var_produto TO cfg_variavel_produto;

-- Tabelas de Log
RENAME TABLE tb_log_busca TO log_busca;
RENAME TABLE tb_erro_mvto TO log_erro_movimento;


-- =====================================================
-- PARTE 3: CRIAR DIMENSÃO TEMPO (SE NÃO EXISTIR)
-- =====================================================

CREATE TABLE IF NOT EXISTS dim_tempo (
    tempo_id INT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate Key',
    ano YEAR NOT NULL COMMENT 'Ano (1980-2030)',
    mes TINYINT NULL COMMENT 'Mês (1-12), NULL = registro anual',
    trimestre TINYINT NULL COMMENT 'Trimestre (1-4), NULL = registro anual',
    semestre TINYINT NULL COMMENT 'Semestre (1-2), NULL = registro anual',
    decada VARCHAR(10) NOT NULL COMMENT 'Década',
    seculo TINYINT NOT NULL COMMENT 'Século',
    ano_bissexto_ind BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'É ano bissexto?',
    descricao VARCHAR(50) NOT NULL COMMENT 'Descrição do período',
    PRIMARY KEY (tempo_id),
    UNIQUE KEY uk_ano_mes (ano, mes),
    INDEX idx_decada (decada),
    INDEX idx_ano (ano),
    INDEX idx_mes (mes)
) ENGINE=InnoDB COMMENT='Dimensão Tempo — granularidade anual e mensal';

-- Popular dim_tempo se estiver vazia
-- Etapa 1: Registros anuais (mes = NULL) — compatibilidade com dados existentes
INSERT IGNORE INTO dim_tempo (ano, mes, trimestre, semestre, decada, seculo, ano_bissexto_ind, descricao)
WITH RECURSIVE anos AS (
    SELECT 1980 as ano
    UNION ALL
    SELECT ano + 1 FROM anos WHERE ano < 2030
)
SELECT 
    ano,
    NULL as mes,
    NULL as trimestre,
    NULL as semestre,
    CONCAT(FLOOR(ano/10)*10, 's') as decada,
    CASE WHEN ano < 2000 THEN 20 ELSE 21 END as seculo,
    (ano % 4 = 0 AND (ano % 100 != 0 OR ano % 400 = 0)) as ano_bissexto_ind,
    CONCAT('Ano ', ano) as descricao
FROM anos;

-- Etapa 2: Registros mensais (12 por ano) — granularidade expandida
INSERT IGNORE INTO dim_tempo (ano, mes, trimestre, semestre, decada, seculo, ano_bissexto_ind, descricao)
WITH RECURSIVE anos AS (
    SELECT 1980 as ano
    UNION ALL
    SELECT ano + 1 FROM anos WHERE ano < 2030
),
meses AS (
    SELECT 1 as mes UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
    UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
)
SELECT 
    a.ano,
    m.mes,
    CEIL(m.mes / 3) as trimestre,
    CEIL(m.mes / 6) as semestre,
    CONCAT(FLOOR(a.ano/10)*10, 's') as decada,
    CASE WHEN a.ano < 2000 THEN 20 ELSE 21 END as seculo,
    (a.ano % 4 = 0 AND (a.ano % 100 != 0 OR a.ano % 400 = 0)) as ano_bissexto_ind,
    CONCAT(
        CASE m.mes
            WHEN 1 THEN 'Jan' WHEN 2 THEN 'Fev' WHEN 3 THEN 'Mar'
            WHEN 4 THEN 'Abr' WHEN 5 THEN 'Mai' WHEN 6 THEN 'Jun'
            WHEN 7 THEN 'Jul' WHEN 8 THEN 'Ago' WHEN 9 THEN 'Set'
            WHEN 10 THEN 'Out' WHEN 11 THEN 'Nov' WHEN 12 THEN 'Dez'
        END, '/', a.ano
    ) as descricao
FROM anos a
CROSS JOIN meses m;


-- =====================================================
-- PARTE 4: CRIAR TABELA FATO NORMALIZADA
-- =====================================================

CREATE TABLE IF NOT EXISTS fact_indicador (
    indicador_id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Surrogate Key',
    localidade_id SMALLINT UNSIGNED NOT NULL COMMENT 'FK - Localidade',
    variavel_id SMALLINT UNSIGNED NOT NULL COMMENT 'FK - Variável',
    tempo_id INT NOT NULL COMMENT 'FK - Tempo',
    indicador_vlr DECIMAL(20,6) NULL COMMENT 'Valor numérico',
    indicador_txt VARCHAR(100) NULL COMMENT 'Valor texto original',
    carga_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Data de carga',
    atualizacao_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última atualização',
    PRIMARY KEY (indicador_id),
    UNIQUE KEY uk_indicador (localidade_id, variavel_id, tempo_id),
    INDEX idx_localidade (localidade_id),
    INDEX idx_variavel (variavel_id),
    INDEX idx_tempo (tempo_id)
) ENGINE=InnoDB COMMENT='Tabela Fato normalizada';


-- =====================================================
-- PARTE 5: CRIAR TABELA DE METADADOS
-- =====================================================

CREATE TABLE IF NOT EXISTS cfg_metadados (
    metadado_id INT NOT NULL AUTO_INCREMENT,
    chave VARCHAR(100) NOT NULL COMMENT 'Nome do metadado',
    valor TEXT NULL COMMENT 'Valor',
    descricao VARCHAR(255) NULL COMMENT 'Descrição',
    criacao_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    atualizacao_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (metadado_id),
    UNIQUE KEY uk_chave (chave)
) ENGINE=InnoDB COMMENT='Metadados do Data Warehouse';

INSERT IGNORE INTO cfg_metadados (chave, valor, descricao) VALUES
('schema_versao', '3.0', 'Versão do schema (inclui modelo de regiões por órgão)'),
('nomenclatura_versao', '2.0', 'Versão do padrão de nomenclatura (inclui bridge_)'),
('modelo_regioes_versao', '1.0', 'Versão do modelo Snowflake de regiões de trabalho'),
('ultima_carga_dh', NULL, 'Data da última carga ETL'),
('banco_nome', 'imp', 'Nome do banco de dados');


-- =====================================================
-- PARTE 6: CRIAR TABELA DE AUDITORIA
-- =====================================================

CREATE TABLE IF NOT EXISTS log_auditoria (
    auditoria_id BIGINT NOT NULL AUTO_INCREMENT,
    tabela_nome VARCHAR(100) NOT NULL COMMENT 'Tabela afetada',
    operacao_tipo ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL COMMENT 'Tipo de operação',
    registro_id VARCHAR(255) NULL COMMENT 'ID do registro',
    dados_antes JSON NULL COMMENT 'Valores antes',
    dados_depois JSON NULL COMMENT 'Valores depois',
    usuario_nome VARCHAR(100) NULL COMMENT 'Usuário',
    ip_origem VARCHAR(45) NULL COMMENT 'IP de origem',
    operacao_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Data/hora',
    PRIMARY KEY (auditoria_id),
    INDEX idx_tabela (tabela_nome),
    INDEX idx_operacao_dh (operacao_dh)
) ENGINE=InnoDB COMMENT='Log de auditoria';


-- =====================================================
-- PARTE 7: CRIAR ESTRUTURA DE REGIÕES POR ÓRGÃO
-- (Modelo Snowflake parcial + SCD Tipo 2)
-- =====================================================

-- dim_orgao — Órgãos que definem regionalizações
CREATE TABLE IF NOT EXISTS dim_orgao (
    orgao_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
        COMMENT 'PK - Surrogate key',
    orgao_nome VARCHAR(200) NOT NULL
        COMMENT 'Nome completo do órgão',
    orgao_sigla VARCHAR(20) NULL
        COMMENT 'Sigla do órgão',
    orgao_nivel ENUM('estadual', 'secretaria', 'autarquia', 'federal', 'municipal') NOT NULL DEFAULT 'secretaria'
        COMMENT 'Nível institucional',
    ativo_ind BOOLEAN NOT NULL DEFAULT TRUE
        COMMENT 'Indica se o órgão está ativo',
    carga_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Data/hora da carga',
    atualizacao_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        COMMENT 'Última atualização',
    PRIMARY KEY (orgao_id),
    UNIQUE KEY uk_orgao_nome (orgao_nome),
    INDEX idx_orgao_sigla (orgao_sigla)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Dimensão Órgão - Órgãos que definem regionalizações de trabalho';

-- dim_regiao — Regiões de trabalho (todas as regionalizações)
CREATE TABLE IF NOT EXISTS dim_regiao (
    regiao_id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
        COMMENT 'PK - Surrogate key',
    orgao_id SMALLINT UNSIGNED NOT NULL
        COMMENT 'FK - Órgão dono desta regionalização',
    regiao_pai_id SMALLINT UNSIGNED NULL
        COMMENT 'FK - Região pai (auto-referência para hierarquia multi-nível)',
    regiao_nome VARCHAR(200) NOT NULL
        COMMENT 'Nome da região',
    regiao_sigla VARCHAR(20) NULL
        COMMENT 'Sigla da região',
    regiao_nivel TINYINT UNSIGNED NOT NULL DEFAULT 1
        COMMENT 'Nível hierárquico (1=macro, 2=micro, 3=local, etc.)',
    regiao_tipo VARCHAR(50) NULL
        COMMENT 'Tipo descritivo (Região de Planejamento, Macrorregião, RISP, etc.)',
    regiao_cod_externo VARCHAR(20) NULL
        COMMENT 'Código em sistema externo (IBGE, SUS, etc.)',
    ativa_ind BOOLEAN NOT NULL DEFAULT TRUE
        COMMENT 'Indica se a região está ativa',
    carga_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Data/hora da carga',
    atualizacao_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        COMMENT 'Última atualização',
    PRIMARY KEY (regiao_id),
    INDEX idx_regiao_orgao (orgao_id),
    INDEX idx_regiao_pai (regiao_pai_id),
    INDEX idx_regiao_nivel (regiao_nivel),
    INDEX idx_regiao_tipo (regiao_tipo),
    CONSTRAINT fk_regiao_orgao
        FOREIGN KEY (orgao_id) REFERENCES dim_orgao (orgao_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_regiao_pai
        FOREIGN KEY (regiao_pai_id) REFERENCES dim_regiao (regiao_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Dimensão Região - Regiões de trabalho de todos os órgãos, com hierarquia multi-nível';

-- bridge_localidade_regiao — Vínculo com temporalidade (SCD Tipo 2)
CREATE TABLE IF NOT EXISTS bridge_localidade_regiao (
    vinculo_id INT UNSIGNED NOT NULL AUTO_INCREMENT
        COMMENT 'PK - Surrogate key',
    localidade_id SMALLINT UNSIGNED NOT NULL
        COMMENT 'FK - Localidade (município, distrito, etc.)',
    regiao_id SMALLINT UNSIGNED NOT NULL
        COMMENT 'FK - Região de trabalho',
    vigencia_inicio_dt DATE NOT NULL
        COMMENT 'Data de início da vigência deste vínculo',
    vigencia_fim_dt DATE NULL
        COMMENT 'Data de fim da vigência (NULL = vigente/atual)',
    vigente_ind BOOLEAN GENERATED ALWAYS AS (vigencia_fim_dt IS NULL) STORED
        COMMENT 'Flag de conveniência: TRUE se vigente, FALSE se encerrado',
    motivo_alteracao_txt VARCHAR(500) NULL
        COMMENT 'Motivo da mudança de região',
    norma_legal_txt VARCHAR(200) NULL
        COMMENT 'Decreto, Lei ou Portaria que definiu a mudança',
    carga_dh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Data/hora da carga do registro',
    PRIMARY KEY (vinculo_id),
    INDEX idx_bridge_localidade (localidade_id),
    INDEX idx_bridge_regiao (regiao_id),
    INDEX idx_bridge_vigente (vigente_ind),
    INDEX idx_bridge_vigencia (vigencia_inicio_dt, vigencia_fim_dt),
    UNIQUE KEY uk_bridge_vigencia (localidade_id, regiao_id, vigencia_inicio_dt),
    CONSTRAINT fk_bridge_localidade
        FOREIGN KEY (localidade_id) REFERENCES dim_localidade (localidade_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bridge_regiao
        FOREIGN KEY (regiao_id) REFERENCES dim_regiao (regiao_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Bridge Table - Vínculo localidade<->região com temporalidade (SCD Tipo 2)';


-- =====================================================
-- PARTE 7.1: PROCEDURE PARA MOVER MUNICÍPIO DE REGIÃO
-- =====================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_mover_localidade_regiao$$

CREATE PROCEDURE sp_mover_localidade_regiao(
    IN p_localidade_id SMALLINT UNSIGNED,
    IN p_nova_regiao_id SMALLINT UNSIGNED,
    IN p_data_mudanca DATE,
    IN p_motivo VARCHAR(500),
    IN p_norma_legal VARCHAR(200)
)
BEGIN
    DECLARE v_orgao_id SMALLINT UNSIGNED;
    DECLARE v_nivel TINYINT UNSIGNED;
    DECLARE v_vinculo_anterior INT UNSIGNED;
    
    -- Obter órgão e nível da nova região
    SELECT orgao_id, regiao_nivel 
    INTO v_orgao_id, v_nivel
    FROM dim_regiao 
    WHERE regiao_id = p_nova_regiao_id;
    
    -- Encontrar vínculo vigente anterior (mesmo órgão e nível)
    SELECT b.vinculo_id
    INTO v_vinculo_anterior
    FROM bridge_localidade_regiao b
    JOIN dim_regiao r ON b.regiao_id = r.regiao_id
    WHERE b.localidade_id = p_localidade_id
      AND r.orgao_id = v_orgao_id
      AND r.regiao_nivel = v_nivel
      AND b.vigente_ind = TRUE
    LIMIT 1;
    
    -- Encerrar vínculo anterior (se existir)
    IF v_vinculo_anterior IS NOT NULL THEN
        UPDATE bridge_localidade_regiao
        SET vigencia_fim_dt = DATE_SUB(p_data_mudanca, INTERVAL 1 DAY)
        WHERE vinculo_id = v_vinculo_anterior;
    END IF;
    
    -- Criar novo vínculo
    INSERT INTO bridge_localidade_regiao 
        (localidade_id, regiao_id, vigencia_inicio_dt, motivo_alteracao_txt, norma_legal_txt)
    VALUES 
        (p_localidade_id, p_nova_regiao_id, p_data_mudanca, p_motivo, p_norma_legal);
    
    SELECT 
        CONCAT('Localidade ', p_localidade_id, 
               ' movida para região ', p_nova_regiao_id,
               ' a partir de ', p_data_mudanca) AS resultado;
               
END$$

DELIMITER ;


-- =====================================================
-- PARTE 7.2: VIEWS DE CONVENIÊNCIA
-- =====================================================

-- View: Localidades com suas regiões vigentes
CREATE OR REPLACE VIEW vw_localidade_regioes_vigentes AS
SELECT 
    l.localidade_id,
    l.localidade_nome,
    l.localidade_cod_ibge,
    o.orgao_id,
    o.orgao_nome,
    o.orgao_sigla,
    r.regiao_id,
    r.regiao_nome,
    r.regiao_nivel,
    r.regiao_tipo,
    b.vigencia_inicio_dt
FROM dim_localidade l
JOIN bridge_localidade_regiao b ON l.localidade_id = b.localidade_id
JOIN dim_regiao r ON b.regiao_id = r.regiao_id
JOIN dim_orgao o ON r.orgao_id = o.orgao_id
WHERE b.vigente_ind = TRUE;

-- View: Localidades com regiões históricas (para consulta por data)
CREATE OR REPLACE VIEW vw_localidade_regioes_historico AS
SELECT 
    l.localidade_id,
    l.localidade_nome,
    l.localidade_cod_ibge,
    o.orgao_id,
    o.orgao_nome,
    o.orgao_sigla,
    r.regiao_id,
    r.regiao_nome,
    r.regiao_nivel,
    r.regiao_tipo,
    b.vigencia_inicio_dt,
    b.vigencia_fim_dt,
    b.vigente_ind,
    b.motivo_alteracao_txt
FROM dim_localidade l
JOIN bridge_localidade_regiao b ON l.localidade_id = b.localidade_id
JOIN dim_regiao r ON b.regiao_id = r.regiao_id
JOIN dim_orgao o ON r.orgao_id = o.orgao_id;


-- =====================================================
-- REABILITAR VERIFICAÇÕES
-- =====================================================

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- VERIFICAÇÃO
-- =====================================================

-- Listar todas as tabelas com novo padrão
SELECT 
    TABLE_NAME,
    CASE 
        WHEN TABLE_NAME LIKE 'dim_%' THEN 'Dimensão'
        WHEN TABLE_NAME LIKE 'fact_%' THEN 'Fato'
        WHEN TABLE_NAME LIKE 'rel_%' THEN 'Relacionamento'
        WHEN TABLE_NAME LIKE 'bridge_%' THEN 'Bridge (SCD)'
        WHEN TABLE_NAME LIKE 'aux_%' THEN 'Auxiliar'
        WHEN TABLE_NAME LIKE 'cfg_%' THEN 'Configuração'
        WHEN TABLE_NAME LIKE 'log_%' THEN 'Log'
        WHEN TABLE_NAME LIKE 'vw_%' THEN 'View'
        ELSE 'Outro'
    END as TIPO,
    TABLE_ROWS as REGISTROS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'imp'
ORDER BY 
    CASE 
        WHEN TABLE_NAME LIKE 'dim_%' THEN 1
        WHEN TABLE_NAME LIKE 'fact_%' THEN 2
        WHEN TABLE_NAME LIKE 'rel_%' THEN 3
        WHEN TABLE_NAME LIKE 'bridge_%' THEN 4
        WHEN TABLE_NAME LIKE 'aux_%' THEN 5
        WHEN TABLE_NAME LIKE 'cfg_%' THEN 6
        WHEN TABLE_NAME LIKE 'log_%' THEN 7
        WHEN TABLE_NAME LIKE 'vw_%' THEN 8
        ELSE 9
    END,
    TABLE_NAME;

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================

/*
INSTRUÇÕES:

1. BACKUP antes de executar:
   mysqldump -u root -p imp > backup_imp_antes_nomenclatura.sql

2. EXECUTAR este script:
   mysql -u root -p imp < script_padronizacao_nomenclatura.sql

3. VERIFICAR se as tabelas foram renomeadas corretamente.

4. DEPOIS executar o script de PKs e FKs (atualizado para nova nomenclatura).
*/
