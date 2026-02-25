-- =====================================================
-- SCRIPT DE PADRONIZAÇÃO DE NOMENCLATURA
-- =====================================================
-- Data: 24/02/2026
-- Banco de dados: imp
-- Objetivo: Renomear tabelas e colunas conforme padrão definido
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
    mes TINYINT NULL COMMENT 'Mês (1-12)',
    trimestre TINYINT NULL COMMENT 'Trimestre (1-4)',
    semestre TINYINT NULL COMMENT 'Semestre (1-2)',
    decada VARCHAR(10) NOT NULL COMMENT 'Década',
    seculo TINYINT NOT NULL COMMENT 'Século',
    ano_bissexto_ind BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'É ano bissexto?',
    descricao VARCHAR(50) NOT NULL COMMENT 'Descrição',
    PRIMARY KEY (tempo_id),
    UNIQUE KEY uk_ano (ano),
    INDEX idx_decada (decada)
) ENGINE=InnoDB COMMENT='Dimensão Tempo';

-- Popular dim_tempo se estiver vazia
INSERT IGNORE INTO dim_tempo (ano, decada, seculo, ano_bissexto_ind, descricao)
WITH RECURSIVE anos AS (
    SELECT 1980 as ano
    UNION ALL
    SELECT ano + 1 FROM anos WHERE ano < 2030
)
SELECT 
    ano,
    CONCAT(FLOOR(ano/10)*10, 's') as decada,
    CASE WHEN ano < 2000 THEN 20 ELSE 21 END as seculo,
    (ano % 4 = 0 AND (ano % 100 != 0 OR ano % 400 = 0)) as ano_bissexto_ind,
    CONCAT('Ano ', ano) as descricao
FROM anos;


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
('schema_versao', '2.0', 'Versão do schema'),
('nomenclatura_versao', '1.0', 'Versão do padrão de nomenclatura'),
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
        WHEN TABLE_NAME LIKE 'aux_%' THEN 'Auxiliar'
        WHEN TABLE_NAME LIKE 'cfg_%' THEN 'Configuração'
        WHEN TABLE_NAME LIKE 'log_%' THEN 'Log'
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
        WHEN TABLE_NAME LIKE 'aux_%' THEN 4
        WHEN TABLE_NAME LIKE 'cfg_%' THEN 5
        WHEN TABLE_NAME LIKE 'log_%' THEN 6
        ELSE 7
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
