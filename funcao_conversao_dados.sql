-- =====================================================================
-- FUNÇÃO DE CONVERSÃO DE DADOS PARA MIGRAÇÃO
-- Banco: imp
-- Data: 24/02/2026
-- 
-- OBJETIVO: Converter valores das colunas d_YYYY para formato numérico
-- padronizado, tratando todos os formatos encontrados na análise
-- =====================================================================

DELIMITER $$

DROP FUNCTION IF EXISTS fn_converter_valor_numerico$$

CREATE FUNCTION fn_converter_valor_numerico(valor_original VARCHAR(100))
RETURNS DECIMAL(20,6)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE valor_limpo VARCHAR(100);
    DECLARE valor_final DECIMAL(20,6);
    
    -- Inicializar
    SET valor_limpo = valor_original;
    
    -- 1. Tratar valores nulos ou vazios
    IF valor_limpo IS NULL OR TRIM(valor_limpo) = '' THEN
        RETURN NULL;
    END IF;
    
    -- 2. Remover espaços extras
    SET valor_limpo = TRIM(valor_limpo);
    
    -- 3. Tratar hífen como NULL (45% dos dados usam '-' para indicar ausência)
    IF valor_limpo = '-' THEN
        RETURN NULL;
    END IF;
    
    -- 4. Tratar caracteres especiais não numéricos
    -- Remover colchetes e conteúdo: '[1]' → ''
    IF valor_limpo LIKE '%[%' THEN
        SET valor_limpo = REGEXP_REPLACE(valor_limpo, '\\[[^]]*\\]', '');
        SET valor_limpo = TRIM(valor_limpo);
        IF valor_limpo = '' THEN
            RETURN NULL;
        END IF;
    END IF;
    
    -- 5. Tratar 'x' ou outros marcadores textuais como NULL
    IF valor_limpo REGEXP '[a-zA-Z]' THEN
        RETURN NULL;
    END IF;
    
    -- 6. Detectar e converter formato brasileiro com milhares
    -- Formato: 1.234.567,89 → 1234567.89
    IF valor_limpo REGEXP '^-?[0-9]{1,3}(\\.[0-9]{3})+,[0-9]+$' THEN
        -- Remover pontos de milhares
        SET valor_limpo = REPLACE(valor_limpo, '.', '');
        -- Trocar vírgula por ponto
        SET valor_limpo = REPLACE(valor_limpo, ',', '.');
    
    -- 7. Detectar formato brasileiro decimal simples
    -- Formato: 0,56 → 0.56
    ELSEIF valor_limpo REGEXP '^-?[0-9]+,[0-9]+$' THEN
        SET valor_limpo = REPLACE(valor_limpo, ',', '.');
    
    -- 8. Detectar formato americano com milhares
    -- Formato: 1,234,567.89 → 1234567.89
    ELSEIF valor_limpo REGEXP '^-?[0-9]{1,3}(,[0-9]{3})+\\.[0-9]+$' THEN
        SET valor_limpo = REPLACE(valor_limpo, ',', '');
    
    -- 9. Detectar inteiro com pontos de milhares (formato BR)
    -- Formato: 1.234.567 → 1234567
    ELSEIF valor_limpo REGEXP '^-?[0-9]{1,3}(\\.[0-9]{3})+$' THEN
        SET valor_limpo = REPLACE(valor_limpo, '.', '');
    
    -- 10. Detectar inteiro com vírgulas de milhares (formato US)
    -- Formato: 1,234,567 → 1234567
    ELSEIF valor_limpo REGEXP '^-?[0-9]{1,3}(,[0-9]{3})+$' THEN
        SET valor_limpo = REPLACE(valor_limpo, ',', '');
    END IF;
    
    -- 11. Tentar converter para decimal
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Em caso de erro, retornar NULL
            SET valor_final = NULL;
        END;
        
        SET valor_final = CAST(valor_limpo AS DECIMAL(20,6));
    END;
    
    RETURN valor_final;
END$$

DELIMITER ;

-- =====================================================================
-- FUNÇÃO AUXILIAR: Classificar tipo de dado
-- =====================================================================

DELIMITER $$

DROP FUNCTION IF EXISTS fn_classificar_tipo_dado$$

CREATE FUNCTION fn_classificar_tipo_dado(valor_original VARCHAR(100))
RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
    DECLARE valor_limpo VARCHAR(100);
    
    SET valor_limpo = TRIM(valor_original);
    
    IF valor_limpo IS NULL OR valor_limpo = '' THEN
        RETURN 'vazio';
    ELSEIF valor_limpo = '-' THEN
        RETURN 'nulo_hifen';
    ELSEIF valor_limpo REGEXP '[a-zA-Z]' THEN
        RETURN 'texto';
    ELSEIF valor_limpo REGEXP '\\[' THEN
        RETURN 'texto_especial';
    ELSEIF valor_limpo REGEXP '^-?[0-9]+$' THEN
        RETURN 'numero';
    ELSEIF valor_limpo REGEXP '^-?[0-9]+[,.]?[0-9]*$' THEN
        RETURN 'numero';
    ELSE
        RETURN 'numero';
    END IF;
END$$

DELIMITER ;

-- =====================================================================
-- TESTES DA FUNÇÃO
-- =====================================================================

/*
-- Testar conversões
SELECT 
    '1.234.567,89' AS original,
    fn_converter_valor_numerico('1.234.567,89') AS convertido,
    fn_classificar_tipo_dado('1.234.567,89') AS tipo;

SELECT 
    '0,56' AS original,
    fn_converter_valor_numerico('0,56') AS convertido,
    fn_classificar_tipo_dado('0,56') AS tipo;

SELECT 
    '-' AS original,
    fn_converter_valor_numerico('-') AS convertido,
    fn_classificar_tipo_dado('-') AS tipo;

SELECT 
    ' 385.623.865,48 ' AS original,
    fn_converter_valor_numerico(' 385.623.865,48 ') AS convertido,
    fn_classificar_tipo_dado(' 385.623.865,48 ') AS tipo;

SELECT 
    'x' AS original,
    fn_converter_valor_numerico('x') AS convertido,
    fn_classificar_tipo_dado('x') AS tipo;

SELECT 
    '[1]' AS original,
    fn_converter_valor_numerico('[1]') AS convertido,
    fn_classificar_tipo_dado('[1]') AS tipo;

SELECT 
    '1,234.56' AS original,
    fn_converter_valor_numerico('1,234.56') AS convertido,
    fn_classificar_tipo_dado('1,234.56') AS tipo;

SELECT 
    '12345' AS original,
    fn_converter_valor_numerico('12345') AS convertido,
    fn_classificar_tipo_dado('12345') AS tipo;
*/

-- =====================================================================
-- ESTRUTURA DA TABELA FATO
-- =====================================================================

DROP TABLE IF EXISTS fact_indicador;

CREATE TABLE fact_indicador (
    indicador_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- Chaves estrangeiras
    localidade_id SMALLINT UNSIGNED NOT NULL,
    variavel_id SMALLINT UNSIGNED NOT NULL,
    tempo_id INT NOT NULL,
    
    -- Valores
    indicador_txt VARCHAR(100) NULL 
        COMMENT 'Valor original preservado da coluna d_YYYY',
    indicador_vlr DECIMAL(20,6) NULL 
        COMMENT 'Valor convertido para número (NULL se não numérico)',
    indicador_tipo ENUM('numero', 'texto', 'nulo_hifen', 'vazio', 'texto_especial') NOT NULL
        COMMENT 'Classificação do tipo de dado original',
    
    -- Metadados
    conversao_ok BOOLEAN GENERATED ALWAYS AS (
        CASE 
            WHEN indicador_tipo IN ('numero', 'vazio', 'nulo_hifen') THEN TRUE
            ELSE FALSE
        END
    ) STORED
        COMMENT 'Indica se o valor foi convertido com sucesso',
    
    carga_dh TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        COMMENT 'Data/hora da carga do registro',
    
    -- Índices
    UNIQUE KEY uk_indicador (localidade_id, variavel_id, tempo_id),
    KEY idx_tempo (tempo_id),
    KEY idx_tipo (indicador_tipo),
    KEY idx_conversao (conversao_ok)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Tabela fato com indicadores e valores convertidos';

-- =====================================================================
-- DIMENSÃO TEMPO (NECESSÁRIA PARA NORMALIZAÇÃO)
-- =====================================================================

DROP TABLE IF EXISTS dim_tempo;

CREATE TABLE dim_tempo (
    tempo_id INT AUTO_INCREMENT PRIMARY KEY,
    ano SMALLINT NOT NULL,
    decada SMALLINT GENERATED ALWAYS AS (FLOOR(ano / 10) * 10) STORED,
    seculo SMALLINT GENERATED ALWAYS AS (FLOOR((ano - 1) / 100) + 1) STORED,
    
    UNIQUE KEY uk_ano (ano)
    
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Dimensão tempo para normalização das colunas d_YYYY';

-- Popular dim_tempo com anos de 1980 a 2030
INSERT INTO dim_tempo (ano)
SELECT DISTINCT ano_valor
FROM (
    SELECT 1980 + (a.n + b.n * 10) AS ano_valor
    FROM 
        (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a
    CROSS JOIN
        (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
         UNION SELECT 5) b
    WHERE 1980 + (a.n + b.n * 10) <= 2030
) anos
ORDER BY ano_valor;

-- =====================================================================
-- PROCEDURE PARA MIGRAÇÃO DOS DADOS
-- =====================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_migrar_dados_para_fato$$

CREATE PROCEDURE sp_migrar_dados_para_fato()
BEGIN
    DECLARE v_ano INT;
    DECLARE v_coluna VARCHAR(20);
    DECLARE v_sql TEXT;
    DECLARE v_total_migrado BIGINT DEFAULT 0;
    DECLARE v_total_erros BIGINT DEFAULT 0;
    DECLARE done INT DEFAULT FALSE;
    
    -- Cursor para iterar pelos anos
    DECLARE cur_anos CURSOR FOR 
        SELECT ano FROM dim_tempo ORDER BY ano;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Limpar tabela de destino
    TRUNCATE TABLE fact_indicador;
    
    OPEN cur_anos;
    
    read_loop: LOOP
        FETCH cur_anos INTO v_ano;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_coluna = CONCAT('d_', v_ano);
        
        -- Construir SQL dinâmico para migração
        SET @v_sql = CONCAT(
            'INSERT INTO fact_indicador ',
            '(localidade_id, variavel_id, tempo_id, indicador_txt, indicador_vlr, indicador_tipo) ',
            'SELECT ',
            '    d.loc_cod AS localidade_id, ',
            '    d.var_cod AS variavel_id, ',
            '    t.tempo_id, ',
            '    d.', v_coluna, ' AS indicador_txt, ',
            '    fn_converter_valor_numerico(d.', v_coluna, ') AS indicador_vlr, ',
            '    fn_classificar_tipo_dado(d.', v_coluna, ') AS indicador_tipo ',
            'FROM tb_dados d ',
            'JOIN dim_tempo t ON t.ano = ', v_ano, ' ',
            'WHERE d.', v_coluna, ' IS NOT NULL'
        );
        
        -- Executar inserção
        PREPARE stmt FROM @v_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Contar registros migrados
        SET v_total_migrado = v_total_migrado + ROW_COUNT();
        
        -- Log de progresso
        SELECT CONCAT('✓ Migrado ano ', v_ano, ' - Total acumulado: ', v_total_migrado) AS status;
        
    END LOOP;
    
    CLOSE cur_anos;
    
    -- Relatório final
    SELECT 
        'MIGRAÇÃO CONCLUÍDA' AS status,
        v_total_migrado AS total_registros_migrados,
        (SELECT COUNT(*) FROM fact_indicador WHERE indicador_tipo = 'numero') AS total_numeros,
        (SELECT COUNT(*) FROM fact_indicador WHERE indicador_tipo = 'texto') AS total_textos,
        (SELECT COUNT(*) FROM fact_indicador WHERE indicador_tipo = 'nulo_hifen') AS total_nulos_hifen,
        (SELECT COUNT(*) FROM fact_indicador WHERE conversao_ok = FALSE) AS total_problemas;
        
END$$

DELIMITER ;

-- =====================================================================
-- INSTRUÇÕES DE USO
-- =====================================================================

/*
1. EXECUTAR AS FUNÇÕES E TABELAS ACIMA

2. TESTAR AS FUNÇÕES:
   SELECT 
       '1.234,56' AS teste,
       fn_converter_valor_numerico('1.234,56') AS valor,
       fn_classificar_tipo_dado('1.234,56') AS tipo;

3. EXECUTAR A MIGRAÇÃO:
   CALL sp_migrar_dados_para_fato();
   
   ⚠️ ATENÇÃO: Este processo pode demorar vários minutos!
   
4. VERIFICAR RESULTADOS:
   SELECT 
       indicador_tipo,
       COUNT(*) as qtd,
       COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_indicador) as percentual
   FROM fact_indicador
   GROUP BY indicador_tipo;
   
5. VERIFICAR PROBLEMAS:
   SELECT *
   FROM fact_indicador
   WHERE conversao_ok = FALSE
   LIMIT 100;

6. BACKUP DA TABELA ORIGINAL (APÓS MIGRAÇÃO BEM-SUCEDIDA):
   -- Renomear tb_dados para tb_dados_original (backup)
   RENAME TABLE tb_dados TO tb_dados_original;
*/
