# Relatório de Análise de Dados - tb_dados

**Data:** 24/02/2026  
**Banco:** imp  
**Tabela Analisada:** tb_dados  
**Total de Registros:** 263.270  

---

## 📊 Sumário Executivo

A análise revelou que **a tabela tb_dados possui dados em FORMATOS MISTOS**, tornando impossível a conversão direta para tipos numéricos sem perda de dados. É necessário um processo de normalização com preservação dos valores originais.

### ⚠️ Problemas Críticos Identificados

| Problema | Impacto | Solução |
| ---------- | --------- | --------- |
| **45.88% são hífens** (`'-'`) | Representam dados ausentes | Converter para NULL |
| **Formatos mistos de decimais** | Vírgula (2.69%) e ponto (1.89%) | Função de conversão inteligente |
| **Valores com espaços** | Ex: `' 385.623.865,48 '` | TRIM antes de converter |
| **Separadores de milhares variados** | Ponto BR e vírgula US | Detectar padrão e remover |
| **Caracteres especiais** | `[1]`, `x` | Preservar como texto |

---

## 📈 Distribuição de Tipos de Dados

### Tipos Encontrados nas Colunas d_1980 a d_2030

| Tipo | Quantidade | Percentual | Exemplos |
| ------ | ------------ | ------------ | ---------- |
| **INTEIRO** | 1.496.819 | 49.35% | `3`, `4`, `12`, `17`, `10` |
| **OUTRO** (hífen) | 1.391.453 | 45.88% | `'-'` |
| **DECIMAL_VIRGULA** | 81.652 | 2.69% | `0,56`, `0,52`, `0,51`, `0,54` |
| **DECIMAL_PONTO** | 57.283 | 1.89% | `1.496`, `1.163`, `1.254`, `1.053` |
| **TEXTO_ESPECIAL** | 2.848 | 0.09% | `[1]` |
| **DECIMAL_BR_COMPLETO** | 2.251 | 0.07% | `40.000,00`, `1.234.567,89` |
| **INTEIRO_MILHARES** | 286 | 0.01% | `1.067.267`, `1.040.656` |
| **TEXTO_COM_LETRAS** | 193 | 0.01% | `'x'` |
| **TOTAL** | **3.032.785** | **100%** | - |

---

## 🔍 Análise Detalhada por Período

### Valores Mais Longos (Maior Complexidade)

| Ano | Maior Valor | Tamanho | Formato |
| ----- | ------------- | --------- | --------- |
| 1980 | `1.586.199` | 9 chars | Inteiro com pontos de milhares |
| 1990 | `2.244.631` | 9 chars | Inteiro com pontos de milhares |
| 2000 | `136.858.165,62` | 14 chars | Decimal BR com milhares |
| 2010 | `4.366.177.623,63` | 16 chars | Decimal BR com milhares |
| **2020** | **` 385.623.865,48 `** | **16 chars** | **ESPAÇOS + Decimal BR** ⚠️ |
| 2030 | `7.938.596` | 9 chars | Inteiro com pontos de milhares |

### Padrões de Formatação por Ano (Amostra)

#### Ano 2000

- Com vírgula: **6.816 registros** - Ex: `1,87`, `-0,23`, `-0,08`
- Com ponto: **24.552 registros** - Ex: `331.672`, `97.781`, `40.181`
- Com espaço: **6.183 registros** - Ex: `- `, ` -   `, ` 25 `
- Com hífen: **45.109 registros** - Ex: `-`, `-0,23`, `-0,08`

#### Ano 2010

- Com vírgula: **19.805 registros** - Ex: `2,32`, `-0,28`, `-1,16`
- Com ponto: **34.656 registros** - Ex: `317.441`, `90.488`, `36.672`
- Com espaço: **12.833 registros** - Ex: ` 3.641 `, ` 1.233 `, ` 1.050 `
- Com hífen: **74.523 registros** - Ex: `-`, ` -   `, `-0,28`

---

## 💡 Padrões de Dados Identificados

### 1. Dados Ausentes (45.88%)

```rel
Formato: '-'
Interpretação: NULL/Sem dados
Tratamento: Converter para NULL
```

### 2. Inteiros Simples (49.35%)

```rel
Exemplos: 3, 4, 12, 17, 10, 543
Tratamento: CAST direto para DECIMAL
```

### 3. Decimais Formato Brasileiro (2.69%)

```rel
Padrão: 0,56 | 12,34 | 1234,56
Tratamento: REPLACE(',', '.') → DECIMAL
```

### 4. Decimais Formato Americano (1.89%)

```rel
Padrão: 0.56 | 12.34 | 1234.56
Tratamento: CAST direto para DECIMAL
```

### 5. Formato Brasileiro Completo (0.07%)

```rel
Padrão: 1.234.567,89
Etapas: 
  1. REPLACE('.', '')  → 1234567,89
  2. REPLACE(',', '.') → 1234567.89
  3. CAST para DECIMAL
```

### 6. Formato Americano com Milhares (<0.01%)

```rel
Padrão: 1,234,567.89
Etapas:
  1. REPLACE(',', '')  → 1234567.89
  2. CAST para DECIMAL
```

### 7. Inteiros com Separadores de Milhares (0.01%)

```rel
Padrão BR: 1.067.267
Etapas: REPLACE('.', '') → 1067267

Padrão US: 1,234,567
Etapas: REPLACE(',', '') → 1234567
```

### 8. Valores com Espaços

```rel
Padrão: ' 385.623.865,48 '
Etapas:
  1. TRIM() → '385.623.865,48'
  2. Aplicar conversão BR completo
```

### 9. Caracteres Especiais (0.09%)

```rel
Padrão: '[1]', 'x'
Interpretação: Notas de rodapé, marcadores
Tratamento: Preservar como texto, NULL no campo numérico
```

### 10. Valores Negativos

```rel
Padrão: -0,23 | -0,28 | -1,16
Tratamento: Aplicar conversão mantendo sinal
```

---

## 🎯 Recomendações de Implementação

### 1️⃣ Estratégia de Migração

**NÃO FAZER:**

```sql
-- ❌ Conversão direta resultará em perda de dados
ALTER TABLE tb_dados 
  MODIFY COLUMN d_2020 DECIMAL(20,6);
-- Resultado: Valores com vírgula, espaços e texto serão zerados!
```

**FAZER:**

```sql
-- ✅ Criar nova estrutura normalizada
CREATE TABLE fact_indicador (
    indicador_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    localidade_id SMALLINT UNSIGNED NOT NULL,
    variavel_id SMALLINT UNSIGNED NOT NULL,
    tempo_id INT NOT NULL,
    indicador_txt VARCHAR(100) NULL,        -- Preserva original
    indicador_vlr DECIMAL(20,6) NULL,       -- Valor convertido
    indicador_tipo ENUM('numero', 'texto', 'nulo_hifen', 'vazio', 'texto_especial'),
    conversao_ok BOOLEAN GENERATED ALWAYS AS (...),
    carga_dh TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2️⃣ Função de Conversão

**Criada em:** `funcao_conversao_dados.sql`

**Recursos:**

- ✅ Detecta automaticamente 10 formatos diferentes
- ✅ Preserva valor original em campo de texto
- ✅ Classifica tipo de dado
- ✅ Registra sucesso/falha de conversão
- ✅ Trata valores negativos corretamente

**Uso:**

```sql
SELECT fn_converter_valor_numerico('1.234.567,89');  -- Retorna: 1234567.89
SELECT fn_converter_valor_numerico('-');              -- Retorna: NULL
SELECT fn_converter_valor_numerico('0,56');           -- Retorna: 0.56
SELECT fn_converter_valor_numerico('[1]');            -- Retorna: NULL
```

### 3️⃣ Processo de Migração

```sql
-- 1. Criar estruturas (dim_tempo + fact_indicador)
SOURCE funcao_conversao_dados.sql;

-- 2. Executar migração
CALL sp_migrar_dados_para_fato();
-- ⚠️ Pode demorar vários minutos (263.270 registros × 51 anos)

-- 3. Verificar resultados
SELECT 
    indicador_tipo,
    COUNT(*) as qtd,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_indicador), 2) as pct
FROM fact_indicador
GROUP BY indicador_tipo;

-- 4. Revisar problemas
SELECT 
    localidade_id, variavel_id, tempo_id,
    indicador_txt, indicador_vlr, indicador_tipo
FROM fact_indicador
WHERE conversao_ok = FALSE
LIMIT 100;
```

### 4️⃣ Validação Pós-Migração

**Verificações Obrigatórias:**

1. **Contagem Total**

   ```sql
   -- Total original (colunas com dados)
   SELECT SUM(cnt) FROM (
       SELECT COUNT(*) as cnt FROM tb_dados WHERE d_2020 IS NOT NULL
       UNION ALL
       SELECT COUNT(*) FROM tb_dados WHERE d_2021 IS NOT NULL
       -- ... para todos os anos
   ) totais;
   
   -- Total migrado
   SELECT COUNT(*) FROM fact_indicador;
   ```

2. **Taxa de Conversão**
   ```sql
   SELECT 
       SUM(CASE WHEN conversao_ok = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as taxa_sucesso
   FROM fact_indicador;
   -- Esperado: > 99% (apenas 'texto_especial' deve falhar)
   ```

3. **Amostragem Manual**
   ```sql
   SELECT 
       d.loc_cod, d.var_cod, d.d_2020 AS original,
       f.indicador_txt AS migrado_txt,
       f.indicador_vlr AS migrado_vlr,
       f.indicador_tipo
   FROM tb_dados d
   JOIN dim_tempo t ON t.ano = 2020
   LEFT JOIN fact_indicador f 
       ON f.localidade_id = d.loc_cod 
       AND f.variavel_id = d.var_cod 
       AND f.tempo_id = t.tempo_id
   WHERE d.d_2020 IS NOT NULL
   LIMIT 100;
   ```

---

## 📋 Checklist de Migração

### Antes da Migração
- [ ] **BACKUP COMPLETO DO BANCO**
  ```bash
  mysqldump -u root -p imp > backup_imp_pre_migracao_$(date +%Y%m%d).sql
  ```
- [ ] Executar `analisar_dados_migracao.py` para confirmar padrões
- [ ] Revisar arquivo `dados_problematicos.txt` gerado
- [ ] Testar funções de conversão com dados reais

### Durante a Migração
- [ ] Criar `funcao_conversao_dados.sql` (funções + tabelas)
- [ ] Testar conversão com amostra pequena
  ```sql
  -- Migrar apenas 1 ano para teste
  INSERT INTO fact_indicador (...)
  SELECT ... FROM tb_dados WHERE d_2020 IS NOT NULL LIMIT 1000;
  ```
- [ ] Executar `sp_migrar_dados_para_fato()` completo
- [ ] Monitorar tempo e recursos

### Após a Migração
- [ ] Executar todas as validações (seção 4️⃣ acima)
- [ ] Comparar totais com dados originais
- [ ] Revisar registros com `conversao_ok = FALSE`
- [ ] Atualizar `validar_refatoracao.py` para nova estrutura
- [ ] Documentar quaisquer exceções encontradas
- [ ] **Manter tb_dados original** como backup (renomear para tb_dados_original)

---

## 📊 Métricas Esperadas

| Métrica | Valor Esperado | Como Validar |
|---------|----------------|--------------|
| **Total de registros migrados** | ~3.032.785 | COUNT(*) em fact_indicador |
| **Registros tipo 'numero'** | ~49% | COUNT WHERE indicador_tipo = 'numero' |
| **Registros tipo 'nulo_hifen'** | ~46% | COUNT WHERE indicador_tipo = 'nulo_hifen' |
| **Registros tipo 'texto'** | <1% | COUNT WHERE indicador_tipo IN ('texto', 'texto_especial') |
| **Taxa de conversão bem-sucedida** | >99% | COUNT WHERE conversao_ok = TRUE |
| **Valores NULL em indicador_vlr** | ~46% | COUNT WHERE indicador_vlr IS NULL |

---

## 🚨 Alertas e Cuidados

### ⚠️ Tempo de Processamento
- **Estimativa:** 10-30 minutos dependendo do hardware
- **Registros:** 263.270 × 51 anos = ~13.4 milhões de operações
- **Recomendação:** Executar em horário de baixo uso

### ⚠️ Espaço em Disco
- **tb_dados original:** ~40 MB
- **fact_indicador:** ~60-80 MB (colunas adicionais)
- **Recomendação:** Mínimo 200 MB livres para margem de segurança

### ⚠️ Dados Não Convertíveis
- **Marcadores de texto:** `'x'`, `[1]` serão NULL em indicador_vlr
- **Impacto:** <1% dos dados
- **Ação:** Revisar se precisam tratamento especial

### ⚠️ Valores Negativos
- **Formato:** `-0,23`, `-1,16`
- **Tratamento:** Preservados corretamente
- **Validação:** Conferir se há valores negativos inesperados

---

## 📁 Arquivos Gerados

| Arquivo | Descrição | Status |
|---------|-----------|--------|
| `analisar_dados_migracao.py` | Script Python de análise | ✅ Criado |
| `dados_problematicos.txt` | Registros com caracteres especiais | 🔄 Gerado durante execução |
| `funcao_conversao_dados.sql` | Funções + procedure de migração | ✅ Criado |
| `padrao_nomenclatura.md` | Atualizado com estrutura fato | ✅ Atualizado |

---

## 🎓 Lições Aprendidas

1. **Nunca assumir tipos de dados** - Sempre analisar antes de migrar
2. **Preservar dados originais** - Campo `indicador_txt` é essencial
3. **Classificar dados** - Campo `indicador_tipo` facilita debugging
4. **Testar com amostra** - Validar lógica antes de processar tudo
5. **Documentar exceções** - Caracteres especiais têm significado de negócio

---

**Próximo Passo:** Executar `funcao_conversao_dados.sql` e validar migração completa.
