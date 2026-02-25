-- =====================================================
-- SCRIPT DE MIGRAÇÃO: REGIÕES DE TRABALHO POR ÓRGÃO
-- =====================================================
-- Data: 25/02/2026
-- Versão: 1.0
-- Banco de dados: imp
-- 
-- Objetivo: Popular as tabelas dim_orgao, dim_regiao e
--           bridge_localidade_regiao com dados reais
--           extraídos de dim_localidade e 
--           aux_localidade_regiao_saude.
--
-- Pré-requisitos:
--   1. script_padronizacao_nomenclatura.sql executado
--      (tabelas já renomeadas e estruturas criadas)
--   2. Tabelas dim_orgao, dim_regiao e 
--      bridge_localidade_regiao já existem (vazias)
--   3. dim_localidade possui as colunas:
--      - regiao_planejamento_id
--      - regiao_macro_saude_id
--      - regiao_micro_saude_id
--   4. aux_localidade_regiao_saude existe com dados
--
-- Ordem de execução:
--   ETAPA 1: Popular dim_orgao
--   ETAPA 2: Popular dim_regiao (planejamento)
--   ETAPA 3: Popular dim_regiao (saúde macro + micro)
--   ETAPA 4: Popular bridge_localidade_regiao
--   ETAPA 5: Validação
--   ETAPA 6: Limpeza (opcional)
-- =====================================================

SET @data_inicio = NOW();
SELECT CONCAT('🚀 Início da migração: ', @data_inicio) AS status;

-- =====================================================
-- VERIFICAÇÃO PRÉ-MIGRAÇÃO
-- =====================================================

-- Verificar que as tabelas de destino existem
SELECT 'Verificando tabelas de destino...' AS etapa;

SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME IN ('dim_orgao', 'dim_regiao', 'bridge_localidade_regiao')
ORDER BY TABLE_NAME;
-- Esperado: 3 tabelas com 0 registros

-- Verificar que as tabelas de origem possuem dados
SELECT 'Verificando tabelas de origem...' AS etapa;

SELECT 
    'dim_localidade' AS tabela,
    COUNT(*) AS total,
    COUNT(regiao_planejamento_id) AS com_regiao_plan,
    COUNT(regiao_macro_saude_id) AS com_macro_saude,
    COUNT(regiao_micro_saude_id) AS com_micro_saude
FROM dim_localidade;

SELECT 
    'aux_localidade_regiao_saude' AS tabela,
    COUNT(*) AS total,
    COUNT(DISTINCT regiao_macro_saude_id) AS macros_distintas,
    COUNT(DISTINCT regiao_micro_saude_id) AS micros_distintas
FROM aux_localidade_regiao_saude;


-- =====================================================
-- ETAPA 1: POPULAR dim_orgao
-- =====================================================

SELECT '📋 ETAPA 1: Inserindo órgãos...' AS etapa;

INSERT INTO dim_orgao (orgao_nome, orgao_sigla, orgao_nivel) VALUES
    ('Estado de Goiás', 'GO', 'estadual'),
    ('Secretaria de Estado da Saúde', 'SES-GO', 'secretaria');

-- Verificar
SELECT orgao_id, orgao_nome, orgao_sigla, orgao_nivel 
FROM dim_orgao 
ORDER BY orgao_id;

-- Guardar IDs para uso nas próximas etapas
SET @orgao_go_id = (SELECT orgao_id FROM dim_orgao WHERE orgao_sigla = 'GO');
SET @orgao_ses_id = (SELECT orgao_id FROM dim_orgao WHERE orgao_sigla = 'SES-GO');

SELECT CONCAT('   Estado de Goiás → orgao_id = ', @orgao_go_id) AS info
UNION ALL
SELECT CONCAT('   SES-GO → orgao_id = ', @orgao_ses_id);


-- =====================================================
-- ETAPA 2: POPULAR dim_regiao — Regiões de Planejamento
-- =====================================================

SELECT '📋 ETAPA 2: Inserindo regiões de planejamento...' AS etapa;

-- 2.1 Regiões de Planejamento do Estado (nível 1)
-- Extraídas dos valores distintos em dim_localidade.regiao_planejamento_id
INSERT INTO dim_regiao (orgao_id, regiao_nome, regiao_nivel, regiao_tipo, regiao_cod_externo)
SELECT DISTINCT
    @orgao_go_id,
    CONCAT('Região de Planejamento ', CAST(regiao_planejamento_id AS CHAR)),
    1,
    'Região de Planejamento',
    CAST(regiao_planejamento_id AS CHAR)
FROM dim_localidade
WHERE regiao_planejamento_id IS NOT NULL
ORDER BY regiao_planejamento_id;

-- Verificar
SELECT regiao_id, regiao_nome, regiao_cod_externo
FROM dim_regiao
WHERE orgao_id = @orgao_go_id
ORDER BY regiao_id;

SELECT CONCAT('   Regiões de planejamento inseridas: ', COUNT(*)) AS info
FROM dim_regiao WHERE orgao_id = @orgao_go_id;


-- =====================================================
-- ETAPA 3: POPULAR dim_regiao — Regiões de Saúde
-- =====================================================

SELECT '📋 ETAPA 3: Inserindo regiões de saúde...' AS etapa;

-- 3.1 Macrorregiões de Saúde (nível 1)
INSERT INTO dim_regiao (orgao_id, regiao_nome, regiao_nivel, regiao_tipo, regiao_cod_externo)
SELECT DISTINCT
    @orgao_ses_id,
    ars.regiao_macro_saude_nome,
    1,
    'Macrorregião de Saúde',
    CAST(ars.regiao_macro_saude_id AS CHAR)
FROM aux_localidade_regiao_saude ars
WHERE ars.regiao_macro_saude_nome IS NOT NULL
  AND TRIM(ars.regiao_macro_saude_nome) != ''
ORDER BY ars.regiao_macro_saude_id;

SELECT CONCAT('   Macrorregiões de saúde inseridas: ', COUNT(*)) AS info
FROM dim_regiao 
WHERE orgao_id = @orgao_ses_id AND regiao_tipo = 'Macrorregião de Saúde';

-- 3.2 Microrregiões de Saúde (nível 2, com pai = macrorregião)
INSERT INTO dim_regiao (orgao_id, regiao_pai_id, regiao_nome, regiao_nivel, regiao_tipo, regiao_cod_externo)
SELECT DISTINCT
    @orgao_ses_id,
    r_macro.regiao_id,
    ars.regiao_micro_saude_nome,
    2,
    'Microrregião de Saúde',
    CAST(ars.regiao_micro_saude_id AS CHAR)
FROM aux_localidade_regiao_saude ars
JOIN dim_regiao r_macro 
    ON r_macro.regiao_cod_externo = CAST(ars.regiao_macro_saude_id AS CHAR)
    AND r_macro.regiao_tipo = 'Macrorregião de Saúde'
    AND r_macro.orgao_id = @orgao_ses_id
WHERE ars.regiao_micro_saude_nome IS NOT NULL
  AND TRIM(ars.regiao_micro_saude_nome) != ''
ORDER BY ars.regiao_micro_saude_id;

SELECT CONCAT('   Microrregiões de saúde inseridas: ', COUNT(*)) AS info
FROM dim_regiao 
WHERE orgao_id = @orgao_ses_id AND regiao_tipo = 'Microrregião de Saúde';

-- 3.3 Validar hierarquia Macro → Micro
SELECT 
    r.regiao_tipo,
    r.regiao_nome,
    r.regiao_cod_externo AS cod_externo,
    rp.regiao_nome AS regiao_pai_nome
FROM dim_regiao r
LEFT JOIN dim_regiao rp ON r.regiao_pai_id = rp.regiao_id
WHERE r.orgao_id = @orgao_ses_id
ORDER BY r.regiao_nivel, r.regiao_nome;


-- =====================================================
-- ETAPA 4: POPULAR bridge_localidade_regiao
-- =====================================================

SELECT '📋 ETAPA 4: Inserindo vínculos na bridge...' AS etapa;

-- Data de referência para carga inicial
-- (estimada — ajustar conforme dados reais)
SET @data_carga_inicial = '2000-01-01';

-- 4.1 Vínculos de Região de Planejamento (Estado)
INSERT INTO bridge_localidade_regiao 
    (localidade_id, regiao_id, vigencia_inicio_dt, motivo_alteracao_txt)
SELECT 
    l.localidade_id,
    r.regiao_id,
    @data_carga_inicial,
    'Carga inicial - migração do modelo anterior (dim_localidade.regiao_planejamento_id)'
FROM dim_localidade l
JOIN dim_regiao r 
    ON r.regiao_cod_externo = CAST(l.regiao_planejamento_id AS CHAR)
    AND r.regiao_tipo = 'Região de Planejamento'
    AND r.orgao_id = @orgao_go_id
WHERE l.regiao_planejamento_id IS NOT NULL;

SELECT CONCAT('   Vínculos planejamento inseridos: ', ROW_COUNT()) AS info;

-- 4.2 Vínculos de Macrorregião de Saúde
INSERT INTO bridge_localidade_regiao 
    (localidade_id, regiao_id, vigencia_inicio_dt, motivo_alteracao_txt)
SELECT 
    l.localidade_id,
    r.regiao_id,
    @data_carga_inicial,
    'Carga inicial - migração do modelo anterior (aux_localidade_regiao_saude.regiao_macro_saude_id)'
FROM dim_localidade l
JOIN aux_localidade_regiao_saude ars 
    ON l.localidade_cod_ibge = ars.localidade_cod_ibge
JOIN dim_regiao r 
    ON r.regiao_cod_externo = CAST(ars.regiao_macro_saude_id AS CHAR)
    AND r.regiao_tipo = 'Macrorregião de Saúde'
    AND r.orgao_id = @orgao_ses_id
WHERE ars.regiao_macro_saude_id IS NOT NULL;

SELECT CONCAT('   Vínculos macrorregião saúde inseridos: ', ROW_COUNT()) AS info;

-- 4.3 Vínculos de Microrregião de Saúde
INSERT INTO bridge_localidade_regiao 
    (localidade_id, regiao_id, vigencia_inicio_dt, motivo_alteracao_txt)
SELECT 
    l.localidade_id,
    r.regiao_id,
    @data_carga_inicial,
    'Carga inicial - migração do modelo anterior (aux_localidade_regiao_saude.regiao_micro_saude_id)'
FROM dim_localidade l
JOIN aux_localidade_regiao_saude ars 
    ON l.localidade_cod_ibge = ars.localidade_cod_ibge
JOIN dim_regiao r 
    ON r.regiao_cod_externo = CAST(ars.regiao_micro_saude_id AS CHAR)
    AND r.regiao_tipo = 'Microrregião de Saúde'
    AND r.orgao_id = @orgao_ses_id
WHERE ars.regiao_micro_saude_id IS NOT NULL;

SELECT CONCAT('   Vínculos microrregião saúde inseridos: ', ROW_COUNT()) AS info;


-- =====================================================
-- ETAPA 5: VALIDAÇÃO
-- =====================================================

SELECT '📋 ETAPA 5: Validação...' AS etapa;

-- 5.1 Resumo geral
SELECT '--- Resumo dim_orgao ---' AS secao;
SELECT orgao_id, orgao_nome, orgao_sigla FROM dim_orgao ORDER BY orgao_id;

SELECT '--- Resumo dim_regiao ---' AS secao;
SELECT 
    o.orgao_sigla,
    r.regiao_tipo,
    COUNT(*) AS qtd_regioes
FROM dim_regiao r
JOIN dim_orgao o ON r.orgao_id = o.orgao_id
GROUP BY o.orgao_sigla, r.regiao_tipo
ORDER BY o.orgao_sigla, r.regiao_tipo;

SELECT '--- Resumo bridge_localidade_regiao ---' AS secao;
SELECT 
    o.orgao_sigla,
    r.regiao_tipo,
    COUNT(*) AS vinculos,
    SUM(b.vigente_ind) AS vigentes,
    SUM(CASE WHEN b.vigente_ind = FALSE THEN 1 ELSE 0 END) AS encerrados
FROM bridge_localidade_regiao b
JOIN dim_regiao r ON b.regiao_id = r.regiao_id
JOIN dim_orgao o ON r.orgao_id = o.orgao_id
GROUP BY o.orgao_sigla, r.regiao_tipo
ORDER BY o.orgao_sigla, r.regiao_tipo;

-- 5.2 Verificar localidades SEM vínculo de região de planejamento
SELECT '--- Localidades SEM região de planejamento ---' AS secao;
SELECT 
    l.localidade_id,
    l.localidade_nome,
    l.localidade_nivel,
    l.regiao_planejamento_id AS reg_plan_original
FROM dim_localidade l
LEFT JOIN bridge_localidade_regiao b ON l.localidade_id = b.localidade_id
LEFT JOIN dim_regiao r ON b.regiao_id = r.regiao_id AND r.regiao_tipo = 'Região de Planejamento'
WHERE r.regiao_id IS NULL
  AND l.regiao_planejamento_id IS NOT NULL
ORDER BY l.localidade_id;
-- Esperado: 0 registros (todos os que tinham regiao_planejamento_id devem ter vínculo)

-- 5.3 Verificar integridade: localidades na bridge que não existem em dim_localidade
SELECT '--- Integridade: vínculos órfãos ---' AS secao;
SELECT b.vinculo_id, b.localidade_id, b.regiao_id
FROM bridge_localidade_regiao b
LEFT JOIN dim_localidade l ON b.localidade_id = l.localidade_id
WHERE l.localidade_id IS NULL;
-- Esperado: 0 registros

-- 5.4 Verificar hierarquia de regiões de saúde
SELECT '--- Hierarquia de Saúde (Macro → Micro) ---' AS secao;
SELECT 
    macro.regiao_nome AS macrorregiao,
    COUNT(micro.regiao_id) AS qtd_microrregioes,
    GROUP_CONCAT(micro.regiao_nome ORDER BY micro.regiao_nome SEPARATOR ', ') AS microrregioes
FROM dim_regiao macro
LEFT JOIN dim_regiao micro ON micro.regiao_pai_id = macro.regiao_id
WHERE macro.regiao_tipo = 'Macrorregião de Saúde'
GROUP BY macro.regiao_id, macro.regiao_nome
ORDER BY macro.regiao_nome;

-- 5.5 Teste de consulta: Regiões vigentes de uma localidade
SELECT '--- Teste: regiões de um município (via view) ---' AS secao;
SELECT 
    l.localidade_nome,
    o.orgao_sigla,
    r.regiao_tipo,
    r.regiao_nome,
    b.vigencia_inicio_dt,
    CASE WHEN b.vigente_ind THEN '✅ Vigente' ELSE '⏹️ Encerrado' END AS status
FROM bridge_localidade_regiao b
JOIN dim_localidade l ON b.localidade_id = l.localidade_id
JOIN dim_regiao r ON b.regiao_id = r.regiao_id
JOIN dim_orgao o ON r.orgao_id = o.orgao_id
WHERE l.localidade_nivel = 3  -- municípios
ORDER BY l.localidade_nome
LIMIT 20;

-- 5.6 Contagem comparativa: dados originais vs migrados
SELECT '--- Comparação: origem vs destino ---' AS secao;
SELECT 
    'Regiões de Planejamento' AS tipo,
    (SELECT COUNT(*) FROM dim_localidade WHERE regiao_planejamento_id IS NOT NULL) AS origem,
    (SELECT COUNT(*) FROM bridge_localidade_regiao b 
     JOIN dim_regiao r ON b.regiao_id = r.regiao_id 
     WHERE r.regiao_tipo = 'Região de Planejamento') AS destino
UNION ALL
SELECT 
    'Macrorregião de Saúde',
    (SELECT COUNT(*) FROM aux_localidade_regiao_saude WHERE regiao_macro_saude_id IS NOT NULL),
    (SELECT COUNT(*) FROM bridge_localidade_regiao b 
     JOIN dim_regiao r ON b.regiao_id = r.regiao_id 
     WHERE r.regiao_tipo = 'Macrorregião de Saúde')
UNION ALL
SELECT 
    'Microrregião de Saúde',
    (SELECT COUNT(*) FROM aux_localidade_regiao_saude WHERE regiao_micro_saude_id IS NOT NULL),
    (SELECT COUNT(*) FROM bridge_localidade_regiao b 
     JOIN dim_regiao r ON b.regiao_id = r.regiao_id 
     WHERE r.regiao_tipo = 'Microrregião de Saúde');


-- =====================================================
-- ETAPA 6: LIMPEZA (OPCIONAL)
-- =====================================================
-- ⚠️ EXECUTAR SOMENTE após validar que todos os vínculos
--    foram migrados corretamente na ETAPA 5.
--
-- Descomente as linhas abaixo quando estiver seguro:

-- SELECT '📋 ETAPA 6: Limpeza das colunas antigas...' AS etapa;

-- ALTER TABLE dim_localidade
--     DROP COLUMN regiao_planejamento_id,
--     DROP COLUMN regiao_macro_saude_id,
--     DROP COLUMN regiao_micro_saude_id;

-- SELECT '✅ Colunas de região removidas de dim_localidade' AS resultado;


-- =====================================================
-- ATUALIZAR METADADOS
-- =====================================================

INSERT INTO cfg_metadados (chave, valor, descricao)
VALUES ('migracao_regioes_dh', NOW(), 'Data/hora da migração dos dados de regiões para o novo modelo')
ON DUPLICATE KEY UPDATE valor = NOW(), descricao = 'Data/hora da migração dos dados de regiões para o novo modelo';

INSERT INTO cfg_metadados (chave, valor, descricao)
VALUES ('migracao_regioes_versao', '1.0', 'Versão do script de migração de regiões')
ON DUPLICATE KEY UPDATE valor = '1.0';


-- =====================================================
-- RESUMO FINAL
-- =====================================================

SET @data_fim = NOW();

SELECT '=====================================' AS linha
UNION ALL SELECT '  MIGRAÇÃO CONCLUÍDA'
UNION ALL SELECT '=====================================';

SELECT
    (SELECT COUNT(*) FROM dim_orgao) AS orgaos,
    (SELECT COUNT(*) FROM dim_regiao) AS regioes,
    (SELECT COUNT(*) FROM bridge_localidade_regiao) AS vinculos,
    (SELECT COUNT(*) FROM bridge_localidade_regiao WHERE vigente_ind = TRUE) AS vigentes,
    TIMEDIFF(@data_fim, @data_inicio) AS duracao;

SELECT CONCAT('🏁 Migração finalizada em ', TIMEDIFF(@data_fim, @data_inicio)) AS status;


-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
/*
INSTRUÇÕES DE USO:

1. BACKUP antes de executar:
   mysqldump -u root -p imp > backup_imp_antes_migracao_regioes.sql

2. VERIFICAR pré-requisitos:
   - script_padronizacao_nomenclatura.sql já foi executado?
   - Tabelas dim_orgao, dim_regiao, bridge_localidade_regiao existem?
   - dim_localidade ainda possui colunas regiao_planejamento_id, regiao_macro_saude_id, regiao_micro_saude_id?

3. EXECUTAR este script:
   mysql -u root -p imp < migrar_dados_regioes.sql

4. VALIDAR os resultados da ETAPA 5.

5. OPCIONAL: Se tudo estiver correto, descomentar e executar a ETAPA 6 
   para remover as colunas de região fixa da dim_localidade.

6. Para adicionar NOVOS ÓRGÃOS depois (ex.: SSP, Educação):
   - INSERT INTO dim_orgao (orgao_nome, orgao_sigla, orgao_nivel) VALUES (...);
   - INSERT INTO dim_regiao (...) — regiões do novo órgão
   - INSERT INTO bridge_localidade_regiao (...) — vínculos dos municípios
   Nenhuma alteração de DDL é necessária!
*/
