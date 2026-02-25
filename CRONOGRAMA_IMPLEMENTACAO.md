# 📅 Cronograma de Implementação - Data Warehouse

**Projeto:** Refatoração e Migração do Banco de Dados 'imp' para Data Warehouse  
**Data de Início:** 24/02/2026  
**Estimativa Total:** 3-4 semanas  
**Responsável:** [A definir]

---

## 🎯 Visão Geral

Este cronograma organiza a implementação em **5 fases principais**, cada uma com atividades específicas, prioridades e critérios de validação.

```cron
FASE 1: Preparação e Backup          (2-3 dias)   🔴 CRÍTICO
FASE 2: Limpeza de Dados              (3-5 dias)   🔴 CRÍTICO
FASE 3: Padronização de Nomenclatura  (1-2 dias)   🟡 IMPORTANTE
FASE 4: Migração e Normalização       (5-7 dias)   🔴 CRÍTICO
FASE 5: Implementação de Integridade  (3-5 dias)   🟡 IMPORTANTE
FASE 6: Validação e Documentação      (2-3 dias)   🟢 DESEJÁVEL
```

**Total:** 16-25 dias úteis (3-5 semanas)

---

## 🔴 FASE 1: Preparação e Backup (PRIORIDADE MÁXIMA)

**Objetivo:** Garantir segurança dos dados antes de qualquer modificação  
**Duração:** 2-3 dias  
**Pode Pular?** ❌ NÃO - É OBRIGATÓRIO

### Atividades

| # | Atividade | Tempo | Status | Responsável |
| --- | ----------- | ------- | -------- | ------------- |
| 1.1 | Criar backup completo do banco 'imp' | 30min | ⬜ | DBA |
| 1.2 | Validar integridade do backup | 15min | ⬜ | DBA |
| 1.3 | Armazenar backup em local seguro (externo) | 15min | ⬜ | DBA |
| 1.4 | Documentar versão e estrutura atual | 1h | ⬜ | Analista |
| 1.5 | Configurar ambiente de desenvolvimento/teste | 2h | ⬜ | DevOps |
| 1.6 | Criar banco de testes com dados reais | 1h | ⬜ | DBA |
| 1.7 | Validar scripts Python (conexão, permissões) | 30min | ⬜ | Dev |

### Comandos de Backup

```bash
# Backup completo
mysqldump -u root -p imp > backup_imp_pre_migracao_20260224.sql

# Backup compactado
mysqldump -u root -p imp | gzip > backup_imp_pre_migracao_20260224.sql.gz

# Validar backup
mysql -u root -p imp_test < backup_imp_pre_migracao_20260224.sql
```

### Critérios de Conclusão

- ✅ Backup validado e restaurável
- ✅ Ambiente de testes funcional
- ✅ Documentação de estado atual completa
- ✅ Scripts Python executando sem erros

### Riscos e Mitigações

| Risco | Impacto | Probabilidade | Mitigação |
| ------- | --------- | ----------- | ----------- |
| Backup corrompido | 🔴 CRÍTICO | Baixa | Validar com restore em ambiente teste |
| Falta de espaço em disco | 🟡 ALTO | Média | Verificar espaço antes (mín. 500MB) |
| Perda de backup | 🔴 CRÍTICO | Baixa | Copiar para 2+ locais diferentes |

---

## 🔴 FASE 2: Limpeza de Dados (PRIORIDADE MÁXIMA)

**Objetivo:** Resolver problemas de qualidade de dados antes da migração  
**Duração:** 3-5 dias  
**Pode Pular?** ❌ NÃO - Impacta criação de PKs/FKs

### Atividades da Fase 2

| # | Atividade | Tempo | Status | Responsável |
| --- | ----------- | ------- | -------- | ------------- |
| 2.1 | Executar análise completa com `validar_refatoracao.py` | 15min | ⬜ | Analista |
| 2.2 | Revisar relatório de problemas identificados | 1h | ⬜ | Analista/Negócio |
| 2.3 | **Resolver duplicatas em tb_base_cart.cod_base** | 4h | ⬜ | DBA |
| 2.4 | **Resolver duplicatas em tb_loc_pai.loc_cod** | 4h | ⬜ | DBA |
| 2.5 | **Resolver registros órfãos em tb_dados.loc_cod** (42 registros) | 2h | ⬜ | Analista/Negócio |
| 2.6 | **Resolver registros órfãos em tb_dados.var_cod** (249 registros) | 3h | ⬜ | Analista/Negócio |
| 2.7 | **Resolver registros órfãos em tb_rel_var_fnt.var_cod** (67 registros) | 2h | ⬜ | Analista/Negócio |
| 2.8 | Resolver demais registros órfãos | 2h | ⬜ | Analista/Negócio |
| 2.9 | Validar correções executadas | 1h | ⬜ | DBA |
| 2.10 | Documentar decisões de negócio tomadas | 2h | ⬜ | Analista |

### Problemas Identificados (do validar_refatoracao.py)

#### 2.3 - Duplicatas em tb_base_cart

```sql
-- Identificar duplicatas
SELECT cod_base, COUNT(*) as qtd
FROM tb_base_cart
GROUP BY cod_base
HAVING COUNT(*) > 1;

-- Estratégias de resolução:
-- Opção 1: Manter registro mais recente (maior ano)
-- Opção 2: Criar novo campo surrogate key
-- Opção 3: Consultar usuário de negócio
```

**Decisão Necessária:** [ ] Qual registro manter em cada duplicata?

#### 2.4 - Duplicatas em tb_loc_pai

```sql
-- Identificar duplicatas
SELECT loc_cod, COUNT(*) as qtd
FROM tb_loc_pai
GROUP BY loc_cod
HAVING COUNT(*) > 1;

-- Estratégia: Verificar se loc_pai e loc_reg são diferentes
-- Se forem iguais, remover duplicata
-- Se diferentes, consultar negócio
```

**Decisão Necessária:** [ ] Critério para desempate

#### 2.5 a 2.8 - Registros Órfãos

```sql
-- tb_dados com loc_cod órfão (42 registros)
SELECT DISTINCT d.loc_cod
FROM tb_dados d
LEFT JOIN tb_localidade l ON d.loc_cod = l.loc_cod
WHERE l.loc_cod IS NULL;

-- Opções:
-- [ ] Criar localidade "Desconhecida"
-- [ ] Remover registros órfãos
-- [ ] Corrigir manualmente
```

**Decisão Necessária:** [ ] Estratégia para órfãos (criar/remover/corrigir)

### Critérios de Conclusão da Fase 2

- ✅ Zero duplicatas em chaves primárias
- ✅ Zero registros órfãos OU estratégia definida
- ✅ Todas as decisões documentadas
- ✅ Script de validação executado com sucesso

### Estimativa de Tempo por Problema

| Problema | Registros | Tempo Estimado | Complexidade |
| ---------- | ----------- | ----------- | ----------- |
| Duplicatas tb_base_cart | 5 grupos | 4h | 🟡 Média |
| Duplicatas tb_loc_pai | 5 grupos | 4h | 🟡 Média |
| Órfãos tb_dados.loc_cod | 42 | 2h | 🟢 Baixa |
| Órfãos tb_dados.var_cod | 249 | 3h | 🟡 Média |
| Órfãos tb_rel_var_fnt | 67 | 2h | 🟢 Baixa |

---

## 🟡 FASE 3: Padronização de Nomenclatura (IMPORTANTE)

**Objetivo:** Aplicar convenções de nomenclatura consistentes  
**Duração:** 1-2 dias  
**Pode Pular?** ⚠️ SIM, mas não recomendado - Facilita manutenção futura

### Atividades da Fase 3

| # | Atividade | Tempo | Status | Responsável |
| --- | ----------- | ------- | -------- | ------------- |
| 3.1 | Revisar documento `padrao_nomenclatura.md` | 1h | ⬜ | Equipe |
| 3.2 | Aprovar padrões com stakeholders | 2h | ⬜ | Gerente/Arquiteto |
| 3.3 | Testar script em ambiente de desenvolvimento | 1h | ⬜ | DBA |
| 3.4 | Executar `script_padronizacao_nomenclatura.sql` | 30min | ⬜ | DBA |
| 3.5 | Validar renomeações executadas | 1h | ⬜ | DBA |
| 3.6 | Atualizar aplicações/views que usam nomes antigos | 4h | ⬜ | Dev |
| 3.7 | Atualizar documentação técnica | 2h | ⬜ | Analista |

### Impacto da Nomenclatura

**ANTES:**

```sql
SELECT loc_nome, var_nome, d.d_2020
FROM tb_dados d
JOIN tb_localidade l ON d.loc_cod = l.loc_cod
JOIN tb_variavel v ON d.var_cod = v.var_cod;
```

**DEPOIS:**

```sql
SELECT localidade_nome, variavel_nome, f.indicador_vlr
FROM fact_indicador f
JOIN dim_localidade l ON f.localidade_id = l.localidade_id
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE t.ano = 2020;
```

### Critérios de Conclusão da Fase 3

- ✅ Todas as 23 tabelas renomeadas
- ✅ Todas as colunas padronizadas (snake_case)
- ✅ Prefixos corretos (dim_, fact_, rel_, etc.)
- ✅ Scripts de validação adaptados à nova nomenclatura
- ✅ Aplicações atualizadas (se houver)

### ⚠️ Opção: Pular para Fase 4

Se o tempo for crítico, é possível:

1. Manter nomenclatura antiga nas tabelas existentes
2. Usar nomenclatura nova **apenas** nas tabelas criadas (fact_indicador, dim_tempo)
3. Fazer a padronização completa em uma fase posterior

**Recomendação:** ✅ Fazer agora - Evita confusão futura

---

## 🔴 FASE 4: Migração e Normalização (PRIORIDADE MÁXIMA)

**Objetivo:** Normalizar tb_dados com conversão de formatos mistos  
**Duração:** 5-7 dias  
**Pode Pular?** ❌ NÃO - É o core da refatoração

### Atividades da Fase 4

| # | Atividade | Tempo | Status | Responsável |
| --- | ----------- | ------- | -------- | ------------- |
| 4.1 | Executar `analisar_dados_migracao.py` completo | 30min | ⬜ | Analista |
| 4.2 | Revisar `RELATORIO_ANALISE_DADOS.md` gerado | 2h | ⬜ | Equipe |
| 4.3 | Validar lógica de conversão com stakeholders | 2h | ⬜ | Analista/Negócio |
| 4.4 | **Criar funções de conversão** (`funcao_conversao_dados.sql`) | 1h | ⬜ | DBA |
| 4.5 | Testar funções com casos de borda | 2h | ⬜ | DBA/QA |
| 4.6 | **Criar dim_tempo** | 15min | ⬜ | DBA |
| 4.7 | **Criar fact_indicador** | 15min | ⬜ | DBA |
| 4.8 | Testar migração com amostra (1.000 registros) | 1h | ⬜ | DBA |
| 4.9 | Validar resultados da amostra | 2h | ⬜ | Analista/QA |
| 4.10 | **Executar migração completa** `sp_migrar_dados_para_fato()` | 3-6h | ⬜ | DBA |
| 4.11 | Validar migração completa (contagens, tipos) | 3h | ⬜ | Analista/QA |
| 4.12 | Analisar registros com `conversao_ok = FALSE` | 2h | ⬜ | Analista/Negócio |
| 4.13 | Corrigir problemas identificados (se houver) | 2-4h | ⬜ | DBA |
| 4.14 | Criar índices adicionais para performance | 1h | ⬜ | DBA |
| 4.15 | Testar queries de consulta (performance) | 2h | ⬜ | Dev/QA |

### Etapas Detalhadas

#### 4.4 - Criar Funções de Conversão

```sql
-- Executar em ambiente de testes primeiro
SOURCE funcao_conversao_dados.sql;

-- Testar funções
SELECT fn_converter_valor_numerico('1.234.567,89');  -- 1234567.89
SELECT fn_converter_valor_numerico('-');              -- NULL
SELECT fn_converter_valor_numerico('0,56');           -- 0.56
```

**Validação:** ✅ Todas as funções criadas sem erros

#### 4.8 - Teste com Amostra

```sql
-- Migrar apenas ano 2020, 1000 registros
INSERT INTO fact_indicador (...)
SELECT ...
FROM tb_dados d
JOIN dim_tempo t ON t.ano = 2020
WHERE d.d_2020 IS NOT NULL
LIMIT 1000;

-- Verificar resultados
SELECT 
    indicador_tipo, 
    COUNT(*) as qtd,
    ROUND(COUNT(*) * 100.0 / 1000, 2) as pct
FROM fact_indicador
GROUP BY indicador_tipo;
```

**Critério de Sucesso:**

- ✅ Taxa de conversão > 99%
- ✅ Tipos distribuídos conforme análise prévia
- ✅ Zero erros no log

#### 4.10 - Migração Completa

```sql
-- ⚠️ ATENÇÃO: Pode demorar 10-30 minutos
CALL sp_migrar_dados_para_fato();

-- Monitorar progresso (em outro terminal)
SELECT COUNT(*) FROM fact_indicador;
```

**Estimativa de Tempo:**

- Hardware normal: 20-30 minutos
- SSD + 8GB RAM: 10-15 minutos
- Hardware antigo: 30-60 minutos

### Validações Obrigatórias Pós-Migração

```sql
-- 1. Contagem total
SELECT COUNT(*) FROM fact_indicador;
-- Esperado: ~3.032.785 (conforme análise)

-- 2. Distribuição de tipos
SELECT 
    indicador_tipo,
    COUNT(*) as qtd,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_indicador), 2) as pct
FROM fact_indicador
GROUP BY indicador_tipo;
-- Esperado: numero ~49%, nulo_hifen ~46%, outros <5%

-- 3. Taxa de conversão
SELECT 
    SUM(CASE WHEN conversao_ok = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as taxa_sucesso
FROM fact_indicador;
-- Esperado: > 99%

-- 4. Verificar NULLs não esperados
SELECT COUNT(*) 
FROM fact_indicador
WHERE indicador_txt IS NOT NULL 
  AND indicador_vlr IS NULL 
  AND indicador_tipo = 'numero';
-- Esperado: 0 (se número, deve ter convertido)
```

### Critérios de Conclusão

- ✅ 100% dos dados migrados
- ✅ Taxa de conversão > 99%
- ✅ Todas as validações passaram
- ✅ Performance de consulta aceitável (<2s para queries típicas)
- ✅ tb_dados original preservada como backup

### Rollback Plan

Se a migração falhar:

```sql
-- Reverter
DROP TABLE IF EXISTS fact_indicador;
DROP TABLE IF EXISTS dim_tempo;
-- Manter tb_dados intacta
```

---

## 🟡 FASE 5: Implementação de Integridade Referencial (IMPORTANTE)

**Objetivo:** Criar chaves primárias e estrangeiras  
**Duração:** 3-5 dias  
**Pode Pular?** ⚠️ SIM, mas compromete integridade

### Atividades da Fase 5

| # | Atividade | Tempo | Status | Responsável |
| --- | ----------- | ------- | -------- | ------------- |
| 5.1 | Atualizar `validar_refatoracao.py` para nova estrutura | 2h | ⬜ | Dev |
| 5.2 | Gerar script de PKs para todas as dimensões | 1h | ⬜ | DBA |
| 5.3 | Executar criação de PKs (dim_aspecto, dim_nota, etc.) | 30min | ⬜ | DBA |
| 5.4 | Validar PKs criadas | 30min | ⬜ | DBA |
| 5.5 | Gerar script de FKs | 2h | ⬜ | DBA |
| 5.6 | Testar FKs em ambiente de desenvolvimento | 1h | ⬜ | DBA |
| 5.7 | **Executar criação de FKs em produção** | 1h | ⬜ | DBA |
| 5.8 | Validar integridade referencial | 1h | ⬜ | DBA |
| 5.9 | Criar índices para FKs (performance) | 1h | ⬜ | DBA |
| 5.10 | Testar impacto de performance | 2h | ⬜ | DBA/Dev |
| 5.11 | Documentar modelo de dados (diagrama ER) | 4h | ⬜ | Arquiteto |

### Ordem de Criação

#### 5.3 - Primary Keys (ordem alfabética)

```sql
-- 1. Dimensões simples (sem FKs)
ALTER TABLE dim_aspecto ADD PRIMARY KEY (aspecto_id);
ALTER TABLE dim_nota ADD PRIMARY KEY (nota_id);
ALTER TABLE dim_fonte ADD PRIMARY KEY (fonte_id);
ALTER TABLE dim_unidade ADD PRIMARY KEY (unidade_id);
ALTER TABLE dim_territorio ADD PRIMARY KEY (territorio_id);
ALTER TABLE dim_tempo ADD PRIMARY KEY (tempo_id);

-- 2. Dimensões com FKs
ALTER TABLE dim_localidade ADD PRIMARY KEY (localidade_id);
ALTER TABLE dim_variavel ADD PRIMARY KEY (variavel_id);
ALTER TABLE dim_base_cartografica ADD PRIMARY KEY (base_cartografica_id);

-- 3. Tabelas fato
ALTER TABLE fact_indicador ADD PRIMARY KEY (indicador_id);

-- 4. Tabelas de relacionamento (PKs compostas)
ALTER TABLE rel_variavel_fonte 
    ADD PRIMARY KEY (variavel_id, fonte_id);
    
ALTER TABLE rel_variavel_nota 
    ADD PRIMARY KEY (variavel_id, nota_id);
    
ALTER TABLE rel_territorio_variavel 
    ADD PRIMARY KEY (territorio_id, variavel_id);
    
ALTER TABLE rel_base_ponto 
    ADD PRIMARY KEY (localidade_id, base_cartografica_id);
```

#### 5.7 - Foreign Keys (respeitar dependências)

```sql
-- Dimensões
ALTER TABLE dim_localidade
    ADD CONSTRAINT fk_loc_pai 
    FOREIGN KEY (localidade_pai_id) REFERENCES dim_localidade(localidade_id);

ALTER TABLE dim_variavel
    ADD CONSTRAINT fk_var_unidade 
    FOREIGN KEY (unidade_id) REFERENCES dim_unidade(unidade_id),
    ADD CONSTRAINT fk_var_aspecto 
    FOREIGN KEY (aspecto_id) REFERENCES dim_aspecto(aspecto_id);

-- Fato
ALTER TABLE fact_indicador
    ADD CONSTRAINT fk_fact_localidade 
    FOREIGN KEY (localidade_id) REFERENCES dim_localidade(localidade_id),
    ADD CONSTRAINT fk_fact_variavel 
    FOREIGN KEY (variavel_id) REFERENCES dim_variavel(variavel_id),
    ADD CONSTRAINT fk_fact_tempo 
    FOREIGN KEY (tempo_id) REFERENCES dim_tempo(tempo_id);

-- Relacionamentos
ALTER TABLE rel_variavel_fonte
    ADD CONSTRAINT fk_rel_vf_variavel 
    FOREIGN KEY (variavel_id) REFERENCES dim_variavel(variavel_id),
    ADD CONSTRAINT fk_rel_vf_fonte 
    FOREIGN KEY (fonte_id) REFERENCES dim_fonte(fonte_id);

-- ... demais FKs
```

### Validação de Integridade

```sql
-- Verificar todas as PKs
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    CONSTRAINT_TYPE
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'imp' 
  AND CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY TABLE_NAME;
-- Esperado: Mínimo 15 PKs

-- Verificar todas as FKs
SELECT 
    TABLE_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'imp' 
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
-- Esperado: Mínimo 10 FKs

-- Testar integridade
-- Tentar inserir registro órfão (deve falhar)
INSERT INTO fact_indicador (localidade_id, variavel_id, tempo_id, ...)
VALUES (99999, 1, 1, ...);
-- Esperado: ERROR 1452 (23000): Cannot add or update a child row
```

### Critérios de Conclusão da Fase 5

- ✅ Todas as tabelas principais têm PK
- ✅ Todas as FKs criadas conforme modelo
- ✅ Zero registros órfãos bloqueando FKs
- ✅ Performance de consultas não degradou significativamente
- ✅ Diagrama ER atualizado

### Rollback Plan da Fase 5

```sql
-- Remover FKs (ordem inversa da criação)
ALTER TABLE fact_indicador DROP FOREIGN KEY fk_fact_tempo;
-- ... demais FKs

-- Remover PKs (se necessário - CUIDADO!)
-- Não recomendado, apenas em caso extremo
```

---

## 🟢 FASE 6: Validação Final e Documentação (DESEJÁVEL)

**Objetivo:** Garantir qualidade e criar documentação completa  
**Duração:** 2-3 dias  
**Pode Pular?** ⚠️ SIM, mas compromete governança

### Atividades da Fase 6

| # | Atividade | Tempo | Status | Responsável |
| --- | ----------- | ------- | -------- | ------------- |
| 6.1 | Executar suite completa de testes | 2h | ⬜ | QA |
| 6.2 | Validar performance de queries críticas | 2h | ⬜ | Dev/DBA |
| 6.3 | Executar `validar_refatoracao.py` final | 15min | ⬜ | Analista |
| 6.4 | Documentar modelo de dados final | 3h | ⬜ | Arquiteto |
| 6.5 | Criar guia de consultas (query cookbook) | 4h | ⬜ | Dev |
| 6.6 | Documentar dicionário de dados | 4h | ⬜ | Analista |
| 6.7 | Atualizar README do projeto | 1h | ⬜ | Dev |
| 6.8 | Criar apresentação para stakeholders | 2h | ⬜ | Gerente |
| 6.9 | Realizar treinamento da equipe | 3h | ⬜ | Arquiteto |
| 6.10 | Documentar procedimentos de manutenção | 2h | ⬜ | DBA |

### Testes de Validação

#### Performance Benchmarks

```sql
-- Query 1: Consulta simples por ano
EXPLAIN
SELECT l.localidade_nome, v.variavel_nome, f.indicador_vlr
FROM fact_indicador f
JOIN dim_localidade l ON f.localidade_id = l.localidade_id
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE t.ano = 2020 AND l.localidade_nivel = 3;
-- Meta: < 1 segundo

-- Query 2: Agregação por região e ano
SELECT 
    l.localidade_nome,
    t.ano,
    AVG(f.indicador_vlr) as media,
    COUNT(*) as total
FROM fact_indicador f
JOIN dim_localidade l ON f.localidade_id = l.localidade_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE t.ano BETWEEN 2010 AND 2020
  AND f.indicador_tipo = 'numero'
GROUP BY l.localidade_nome, t.ano
ORDER BY l.localidade_nome, t.ano;
-- Meta: < 3 segundos

-- Query 3: Análise temporal
SELECT 
    v.variavel_nome,
    t.ano,
    SUM(f.indicador_vlr) as total_anual
FROM fact_indicador f
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE v.variavel_id = 100
  AND t.ano >= 2000
GROUP BY v.variavel_nome, t.ano
ORDER BY t.ano;
-- Meta: < 500 ms
```

#### Relatório Final

```python
# Executar validar_refatoracao.py
python validar_refatoracao.py

# Selecionar opção 1: Validar estrutura completa
# Esperar: 0 problemas
```

### Documentação a Criar

1. **Diagrama ER** (MySQL Workbench / dbdiagram.io)
   - Todas as dimensões
   - Tabela fato
   - Relacionamentos N:N
   - Cardinalidades

2. **Dicionário de Dados** (Excel/Markdown)

   | Tabela | Coluna | Tipo | Descrição | FK | Exemplo |
   | -------- | -------- | -------- | -------- | -------- | -------- |
   | dim_localidade | localidade_id | SMALLINT | PK - Código único | - | 33 |
   | dim_localidade | localidade_nome | VARCHAR(250) | Nome da localidade | - | Rio de Janeiro |

3. **Query Cookbook** (Markdown)
   - Top 10 queries mais utilizadas
   - Exemplos comentados
   - Filtros comuns

4. **Guia de Manutenção**
   - Como adicionar nova variável
   - Como inserir dados mensais
   - Como criar novos cálculos

### Critérios de Conclusão da Fase 6

- ✅ Todos os testes de performance passaram
- ✅ Validação final sem problemas
- ✅ Documentação completa e revisada
- ✅ Equipe treinada
- ✅ Aprovação dos stakeholders

---

## 📊 Resumo de Prioridades

### 🔴 CRÍTICO - NÃO PODE PULAR

| Fase | Atividade Principal | Risco se Pular |
|------|---------------------|----------------|
| **FASE 1** | Backup e preparação | ❌ Perda de dados irreversível |
| **FASE 2** | Limpeza de dados | ❌ PKs/FKs não podem ser criadas |
| **FASE 4** | Migração e normalização | ❌ Dados em formato inconsistente |

**Total Crítico:** 10-15 dias

### 🟡 IMPORTANTE - RECOMENDADO

| Fase | Atividade Principal | Impacto se Pular |
| ------ | --------------------- | ------------------ |
| **FASE 3** | Padronização nomenclatura | ⚠️ Manutenção futura difícil |
| **FASE 5** | PKs e FKs | ⚠️ Sem integridade referencial |

**Total Importante:** 4-7 dias

### 🟢 DESEJÁVEL - PODE POSTERGAR

| Fase | Atividade Principal | Impacto se Pular |
|------|---------------------|------------------|
| **FASE 6** | Documentação completa | ⚠️ Falta de governança |

**Total Desejável:** 2-3 dias

---

## 🚀 Planos de Implementação

### PLANO A: Implementação Completa (Recomendado)

**Duração:** 3-4 semanas  
**Inclui:** Todas as fases (1-6)  
**Resultado:** DW totalmente refatorado, documentado e validado

```cron
Semana 1: FASES 1 + 2 (Backup + Limpeza)
Semana 2: FASES 3 + 4.1-4.9 (Nomenclatura + Preparação Migração)
Semana 3: FASES 4.10-4.15 + 5.1-5.7 (Migração + PKs/FKs)
Semana 4: FASES 5.8-5.11 + 6 (Validação + Documentação)
```

### PLANO B: Implementação Rápida (Mínimo Viável)

**Duração:** 2-3 semanas  
**Inclui:** FASES 1, 2, 4, 5 (pula nomenclatura e docs completas)  
**Resultado:** DW funcional, mas sem padronização

```
Semana 1: FASES 1 + 2 (Backup + Limpeza)
Semana 2: FASE 4 (Migração completa)
Semana 3: FASE 5 (PKs/FKs + validação básica)
```

**⚠️ Fazer FASE 3 e 6 posteriormente!**

### PLANO C: Implementação Incremental (Baixo Risco)

**Duração:** 4-6 semanas  
**Inclui:** Todas as fases + período de observação entre cada  
**Resultado:** DW robusto com validação extensiva

```cron
Semana 1: FASE 1 (Backup + Preparação)
Semana 2: FASE 2 (Limpeza + Validação)
Semana 3: FASE 3 + 4.1-4.9 (Nomenclatura + Testes)
Semana 4: FASE 4.10-4.15 (Migração + Validação)
Semana 5: FASE 5 (PKs/FKs + Validação)
Semana 6: FASE 6 (Documentação + Treinamento)
```

**Recomendado para:** Ambientes críticos de produção

---

## 📋 Checklist de Conclusão do Projeto

### Técnico

- [ ] Backup validado e restaurável
- [ ] Zero problemas de qualidade de dados
- [ ] Nomenclatura padronizada (ou decisão documentada de não fazer)
- [ ] 100% dos dados migrados para fact_indicador
- [ ] Taxa de conversão > 99%
- [ ] Todas as PKs criadas
- [ ] Todas as FKs criadas
- [ ] Performance de queries aceitável
- [ ] Índices otimizados
- [ ] Script de validação executado com sucesso

### Documentação

- [ ] Modelo de dados (diagrama ER) atualizado
- [ ] Dicionário de dados criado
- [ ] Query cookbook disponível
- [ ] Procedimentos de manutenção documentados
- [ ] Decisões de negócio registradas

### Governança

- [ ] Stakeholders aprovaram modelo final
- [ ] Equipe treinada
- [ ] Procedimentos de backup automatizados
- [ ] Plano de contingência definido
- [ ] Apresentação final realizada

---

## 🎯 Indicadores de Sucesso (KPIs)

| Métrica | Meta | Como Medir |
| --------- | --------- | ---------|------------|
| **Taxa de conclusão de fases** | 100% críticas | Checklist de atividades |
| **Taxa de conversão de dados** | > 99% | SELECT COUNT(*) WHERE conversao_ok = TRUE |
| **Zero problemas de integridade** | 0 órfãos, 0 duplicatas | validar_refatoracao.py |
| **Performance de consultas** | < 2s para 90% | Benchmark queries |
| **Cobertura de documentação** | 100% tabelas | Dicionário de dados |
| **Satisfação da equipe** | > 80% | Survey pós-implementação |

---

## 📞 Contatos e Responsabilidades

| Papel | Nome | Responsabilidade | Email/Tel |
| ------- | ----------- | -----------------|------------------|-----------|
| **Patrocinador** | [Nome] | Aprovação final | - |
| **Gerente de Projeto** | [Nome] | Coordenação geral | - |
| **Arquiteto de Dados** | [Nome] | Modelo de dados, decisões técnicas | - |
| **DBA** | [Nome] | Execução scripts, performance | - |
| **Analista de Dados** | [Nome] | Validação, limpeza de dados | - |
| **Desenvolvedor** | [Nome] | Scripts Python, integração | - |
| **QA** | [Nome] | Testes e validação | - |
| **Analista de Negócio** | [Nome] | Decisões de regras de negócio | - |

---

## 📅 Próximos Passos Imediatos

### Esta Semana (Dias 1-5)

1. [ ] **DIA 1:** Revisar este cronograma com a equipe
2. [ ] **DIA 1:** Definir plano (A/B/C) e aprovar com stakeholders
3. [ ] **DIA 2:** Atribuir responsáveis para cada atividade
4. [ ] **DIA 2-3:** FASE 1 - Backup e preparação
5. [ ] **DIA 4-5:** FASE 2 - Iniciar limpeza de dados

### Próxima Semana (Dias 6-10)

1. [ ] Concluir FASE 2
2. [ ] Iniciar FASE 3 ou 4 (conforme plano escolhido)

### Checkpoint Semanal

- **Reunião:** Sexta-feira, 15h
- **Agenda:** Status, bloqueios, decisões necessárias
- **Formato:** 30min, toda a equipe

---

**Documento criado em:** 24/02/2026  
**Versão:** 1.0  
**Próxima revisão:** Após cada fase concluída
