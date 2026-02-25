# 🛠️ Hands-On: Migração do Banco de Dados para Data Warehouse

**Projeto:** Refatoração do Banco 'imp' para Data Warehouse  
**Data:** 25/02/2026  
**Servidor:** `10.209.59.96` (MySQL 8.4)  
**Ferramenta de acesso:** DBeaver / phpMyAdmin (`http://10.209.59.96:8080`)

---

## 📋 Índice

1. [Sobre este Hands-On](#1-sobre-este-hands-on)
2. [Configuração do Ambiente](#2-configuração-do-ambiente)
3. [Exercício 1 — Diagnóstico do Banco Original](#3-exercício-1--diagnóstico-do-banco-original)
4. [Exercício 2 — Limpeza de Dados](#4-exercício-2--limpeza-de-dados)
5. [Exercício 3 — Padronização de Nomenclatura](#5-exercício-3--padronização-de-nomenclatura)
6. [Exercício 4 — Análise dos Dados da Tabela Fato](#6-exercício-4--análise-dos-dados-da-tabela-fato)
7. [Exercício 5 — Migração e Normalização](#7-exercício-5--migração-e-normalização)
8. [Exercício 6 — Chaves Primárias e Estrangeiras](#8-exercício-6--chaves-primárias-e-estrangeiras)
9. [Exercício 7 — Validação Final e Consultas](#9-exercício-7--validação-final-e-consultas)
10. [Referência Rápida](#10-referência-rápida)

---

## 1. Sobre este Hands-On

### Objetivo

Cada participante irá executar, no seu banco individual, o processo completo de transformação de um banco relacional convencional em um **Data Warehouse** com modelo estrela (Star Schema), passando por:

- Diagnóstico de problemas
- Limpeza de dados
- Padronização de nomenclatura
- Normalização de tabela fato
- Criação de integridade referencial

### Estrutura dos Bancos

O banco original `imp` contém os dados de referência. Cada colaborador possui um banco próprio para trabalhar sem impactar os demais:

| Colaborador | Banco de Trabalho | Usuário | Senha |
| ------------- | ------------------- | --------- | ------- |
| Bruna | `bruna` | `bruna` | *b123456* |
| Lorenna | `lorenna` | `lorenna` | *l123456* |
| Rejane | `rejane` | `rejane` | *r123456* |
| Santino | `santino` | `santino` | *s123456* |
| *(adicionar conforme necessário)* | | | |

> ⚠️ **IMPORTANTE:** Preencha a tabela acima com os nomes reais e credenciais antes de distribuir.

### Pré-Requisitos

- Acesso de rede ao servidor `10.209.59.96` (porta 3306)
- Python 3.10+ instalado na estação de trabalho
- DBeaver ou outro client MySQL instalado
- Git (opcional, para clonar o repositório)

### Tempo Estimado

| Exercício | Duração | Nível |
|-----------|---------|-------|
| Configuração do Ambiente | 30 min | 🟢 Básico |
| Exercício 1 — Diagnóstico | 45 min | 🟢 Básico |
| Exercício 2 — Limpeza de Dados | 1h 30min | 🟡 Intermediário |
| Exercício 3 — Nomenclatura | 1h | 🟡 Intermediário |
| Exercício 4 — Análise de Dados | 1h | 🟡 Intermediário |
| Exercício 5 — Migração | 1h 30min | 🔴 Avançado |
| Exercício 6 — PKs e FKs | 1h | 🟡 Intermediário |
| Exercício 7 — Validação Final | 45 min | 🟢 Básico |
| **Total** | **~8h** | |

---

## 2. Configuração do Ambiente

### 2.1 — Configuração do DBeaver

1. Abra o DBeaver
2. Clique em **Nova Conexão** → **MySQL**
3. Preencha:

   | Campo | Valor |
   |-------|-------|
   | **Host** | `10.209.59.96` |
   | **Porta** | `3306` |
   | **Database** | `imp_colabX` *(seu banco)* |
   | **Usuário** | `colabX` *(seu usuário)* |
   | **Senha** | *(sua senha)* |

4. Na aba **Driver Properties**, configure:

   | Propriedade | Valor |
   |-------------|-------|
   | `useSSL` | `false` |
   | `allowPublicKeyRetrieval` | `true` |

5. Clique em **Testar Conexão** → deve retornar "Conectado"
6. Clique em **Concluir**

> 💡 **phpMyAdmin** também está disponível em `http://10.209.59.96:8080`

### 2.2 — Configuração do Python

Abra o terminal na pasta do projeto e execute:

```bash
# Clonar o repositório (ou copiar a pasta do projeto)
cd D:\AmbienteDeTrabalho\python\bde

# Criar ambiente virtual
python -m venv venv

# Ativar ambiente virtual
# Windows PowerShell:
.\venv\Scripts\Activate.ps1
# Windows CMD:
.\venv\Scripts\activate.bat
# Linux/Mac:
source venv/bin/activate

# Instalar dependência
pip install mysql-connector-python
```

### 2.3 — Configurar Conexão nos Scripts Python

Crie ou edite o arquivo `conexao_mysql.py` com **seus dados de acesso**:

```python
import mysql.connector
from mysql.connector import Error

# =========================================
# ⚠️ ALTERE PARA SEUS DADOS DE ACESSO
# =========================================
CONFIG = {
    'host': '10.209.59.96',
    'user': 'colabX',            # ← seu usuário
    'password': 'sua_senha',     # ← sua senha
    'database': 'imp_colabX'     # ← seu banco
}

def conectar():
    """Conecta ao banco de dados MySQL"""
    try:
        conexao = mysql.connector.connect(**CONFIG)
        if conexao.is_connected():
            info = conexao.get_server_info()
            cursor = conexao.cursor()
            cursor.execute("SELECT DATABASE();")
            banco = cursor.fetchone()[0]
            print(f"✅ Conectado ao MySQL {info} | Banco: {banco}")
            cursor.close()
            return conexao
    except Error as e:
        print(f"❌ Erro ao conectar: {e}")
        return None

def executar_query(conexao, query, retornar=True):
    """Executa uma query e retorna os resultados"""
    try:
        cursor = conexao.cursor()
        cursor.execute(query)
        if retornar:
            colunas = [desc[0] for desc in cursor.description]
            resultados = cursor.fetchall()
            cursor.close()
            return colunas, resultados
        else:
            conexao.commit()
            afetados = cursor.rowcount
            cursor.close()
            return afetados
    except Error as e:
        print(f"❌ Erro: {e}")
        return None

def fechar(conexao):
    """Fecha a conexão"""
    if conexao and conexao.is_connected():
        conexao.close()
        print("✅ Conexão encerrada")

# Teste rápido
if __name__ == "__main__":
    conn = conectar()
    if conn:
        colunas, tabelas = executar_query(conn, "SHOW TABLES;")
        print(f"\n📦 Tabelas encontradas: {len(tabelas)}")
        for t in tabelas:
            print(f"   • {t[0]}")
        fechar(conn)
```

### 2.4 — Testar a Conexão

```bash
python conexao_mysql.py
```

**Resultado esperado:**
```
✅ Conectado ao MySQL 8.4.x | Banco: imp_colabX
📦 Tabelas encontradas: 23
   • tb_aspecto
   • tb_base_cart
   • ...
✅ Conexão encerrada
```

### ✅ Checkpoint — Ambiente Pronto

Antes de prosseguir, confirme:

- [ ] DBeaver conecta ao banco sem erros
- [ ] Python com `mysql-connector-python` instalado
- [ ] Script `conexao_mysql.py` retorna as 23 tabelas
- [ ] Você consegue visualizar os dados via phpMyAdmin ou DBeaver

---

## 3. Exercício 1 — Diagnóstico do Banco Original

**Objetivo:** Entender o estado atual do banco e identificar problemas

### 3.1 — Mapear a Estrutura

Execute as queries abaixo no DBeaver ou via Python. **Anote os resultados.**

```sql
-- 1. Quantas tabelas existem?
SELECT COUNT(*) AS total_tabelas
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE();

-- 2. Quantos registros em cada tabela?
SELECT 
    TABLE_NAME AS tabela,
    TABLE_ROWS AS registros,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS tamanho_mb
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_ROWS DESC;

-- 3. Quantas PKs existem?
SELECT COUNT(*) AS total_pks
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND CONSTRAINT_TYPE = 'PRIMARY KEY';

-- 4. Quantas FKs existem?
SELECT COUNT(*) AS total_fks
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND CONSTRAINT_TYPE = 'FOREIGN KEY';
```

### 3.2 — Identificar Problemas de Nomenclatura

```sql
-- 5. Listar todas as colunas de todas as tabelas
SELECT 
    TABLE_NAME AS tabela,
    COLUMN_NAME AS coluna,
    DATA_TYPE AS tipo,
    CHARACTER_MAXIMUM_LENGTH AS tamanho
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_NAME, ORDINAL_POSITION;
```

📝 **Anote no seu caderno:**
- Quais padrões de prefixo você encontra? (`cod_`, `nome_`, `loc_`, `var_`, `fnt_`, etc.)
- Quais colunas fogem do padrão? (case misto, sem prefixo, abreviações diferentes)
- Quantas tabelas não têm PK? Quantas não têm FK?

### 3.3 — Identificar Duplicatas

```sql
-- 6. Duplicatas em tb_base_cart
SELECT cod_base, COUNT(*) AS qtd
FROM tb_base_cart
GROUP BY cod_base
HAVING COUNT(*) > 1;

-- 7. Duplicatas em tb_loc_pai
SELECT loc_cod, COUNT(*) AS qtd
FROM tb_loc_pai
GROUP BY loc_cod
HAVING COUNT(*) > 1;
```

### 3.4 — Identificar Registros Órfãos

```sql
-- 8. Localidades em tb_dados que não existem em tb_localidade
SELECT DISTINCT d.loc_cod
FROM tb_dados d
LEFT JOIN tb_localidade l ON d.loc_cod = l.loc_cod
WHERE l.loc_cod IS NULL;

-- 9. Variáveis em tb_dados que não existem em tb_variavel
SELECT DISTINCT d.var_cod
FROM tb_dados d
LEFT JOIN tb_variavel v ON d.var_cod = v.var_cod
WHERE v.var_cod IS NULL;

-- 10. Variáveis em tb_rel_var_fnt que não existem em tb_variavel
SELECT DISTINCT r.var_cod
FROM tb_rel_var_fnt r
LEFT JOIN tb_variavel v ON r.var_cod = v.var_cod
WHERE v.var_cod IS NULL;
```

### 📝 Entregável do Exercício 1

Preencha a tabela abaixo com seus achados:

| Item | Valor Encontrado |
|------|-----------------|
| Total de tabelas | |
| Total de registros (todas as tabelas) | |
| Total de PKs | |
| Total de FKs | |
| Tabelas com duplicatas em PK potencial | |
| Total de registros órfãos em tb_dados (loc_cod) | |
| Total de registros órfãos em tb_dados (var_cod) | |
| Principais padrões de nomenclatura identificados | |

---

## 4. Exercício 2 — Limpeza de Dados

**Objetivo:** Resolver duplicatas e registros órfãos para possibilitar PKs e FKs

### 4.1 — Analisar Duplicatas em tb_base_cart

```sql
-- Ver os registros duplicados em detalhe
SELECT *
FROM tb_base_cart
WHERE cod_base IN (
    SELECT cod_base
    FROM tb_base_cart
    GROUP BY cod_base
    HAVING COUNT(*) > 1
)
ORDER BY cod_base;
```

📝 **Pergunta:** Os registros duplicados são idênticos ou possuem dados diferentes?

### 4.2 — Resolver Duplicatas em tb_base_cart

Escolha **uma** das estratégias abaixo:

**Estratégia A — Remover duplicatas idênticas (manter 1):**
```sql
-- Criar tabela temporária com registros únicos
CREATE TABLE tb_base_cart_temp AS
SELECT DISTINCT *
FROM tb_base_cart;

-- Substituir a tabela original
DROP TABLE tb_base_cart;
RENAME TABLE tb_base_cart_temp TO tb_base_cart;
```

**Estratégia B — Manter o registro com maior ano:**
```sql
-- Criar tabela com o maior ano por cod_base
CREATE TABLE tb_base_cart_temp AS
SELECT b.*
FROM tb_base_cart b
INNER JOIN (
    SELECT cod_base, MAX(ano) AS max_ano
    FROM tb_base_cart
    GROUP BY cod_base
) m ON b.cod_base = m.cod_base AND b.ano = m.max_ano;

DROP TABLE tb_base_cart;
RENAME TABLE tb_base_cart_temp TO tb_base_cart;
```

### 4.3 — Resolver Duplicatas em tb_loc_pai

```sql
-- Analisar duplicatas em detalhe
SELECT *
FROM tb_loc_pai
WHERE loc_cod IN (
    SELECT loc_cod
    FROM tb_loc_pai
    GROUP BY loc_cod
    HAVING COUNT(*) > 1
)
ORDER BY loc_cod;

-- Resolver (adaptar conforme análise)
CREATE TABLE tb_loc_pai_temp AS
SELECT DISTINCT *
FROM tb_loc_pai;

DROP TABLE tb_loc_pai;
RENAME TABLE tb_loc_pai_temp TO tb_loc_pai;
```

### 4.4 — Resolver Registros Órfãos

Escolha **uma** das estratégias para cada caso:

**Opção 1 — Criar registro genérico (recomendado):**
```sql
-- Criar localidade "Desconhecida" para referência
INSERT INTO tb_localidade (loc_cod, loc_nome, loc_nivel)
SELECT DISTINCT d.loc_cod, CONCAT('Localidade Desconhecida (', d.loc_cod, ')'), 0
FROM tb_dados d
LEFT JOIN tb_localidade l ON d.loc_cod = l.loc_cod
WHERE l.loc_cod IS NULL;

-- Criar variável "Desconhecida" para referência
INSERT INTO tb_variavel (var_cod, var_nome)
SELECT DISTINCT d.var_cod, CONCAT('Variável Desconhecida (', d.var_cod, ')')
FROM tb_dados d
LEFT JOIN tb_variavel v ON d.var_cod = v.var_cod
WHERE v.var_cod IS NULL;
```

**Opção 2 — Remover registros órfãos:**
```sql
-- ⚠️ CUIDADO: Perda de dados!
DELETE d FROM tb_dados d
LEFT JOIN tb_localidade l ON d.loc_cod = l.loc_cod
WHERE l.loc_cod IS NULL;
```

### 4.5 — Validar Limpeza

```sql
-- Reexecutar as queries do Exercício 1 (itens 6 a 10)
-- TODAS devem retornar 0 registros

-- Verificação rápida
SELECT 'tb_base_cart duplicatas' AS verificacao,
       COUNT(*) - COUNT(DISTINCT cod_base) AS problemas
FROM tb_base_cart
UNION ALL
SELECT 'tb_loc_pai duplicatas',
       COUNT(*) - COUNT(DISTINCT loc_cod)
FROM tb_loc_pai
UNION ALL
SELECT 'tb_dados loc_cod órfãos',
       COUNT(DISTINCT d.loc_cod)
FROM tb_dados d LEFT JOIN tb_localidade l ON d.loc_cod = l.loc_cod
WHERE l.loc_cod IS NULL
UNION ALL
SELECT 'tb_dados var_cod órfãos',
       COUNT(DISTINCT d.var_cod)
FROM tb_dados d LEFT JOIN tb_variavel v ON d.var_cod = v.var_cod
WHERE v.var_cod IS NULL;
```

**Resultado esperado:** Todos os valores na coluna `problemas` devem ser `0`.

### ✅ Checkpoint — Dados Limpos

- [ ] Zero duplicatas em tb_base_cart
- [ ] Zero duplicatas em tb_loc_pai
- [ ] Zero registros órfãos em tb_dados (loc_cod e var_cod)
- [ ] Zero registros órfãos em tb_rel_var_fnt

---

## 5. Exercício 3 — Padronização de Nomenclatura

**Objetivo:** Renomear tabelas e colunas seguindo o padrão definido

> 📖 Consulte o documento `padrao_nomenclatura.md` para a referência completa do de-para.

### 5.1 — Entender o Padrão

| Prefixo | Tipo | Exemplo |
|---------|------|---------|
| `dim_` | Dimensão | `dim_localidade` |
| `fact_` | Fato | `fact_indicador` |
| `rel_` | Relacionamento N:N | `rel_variavel_fonte` |
| `aux_` | Auxiliar | `aux_localidade_hierarquia` |
| `cfg_` | Configuração | `cfg_consulta` |
| `log_` | Log/Auditoria | `log_busca` |

| Sufixo | Uso | Exemplo |
|--------|-----|---------|
| `_id` | Chave primária / FK | `localidade_id` |
| `_nome` | Nome descritivo | `localidade_nome` |
| `_txt` | Texto longo | `nota_txt` |
| `_vlr` | Valor numérico | `indicador_vlr` |
| `_dh` | Data/hora | `busca_dh` |
| `_ind` | Indicador (boolean) | `mapa_disponivel_ind` |

### 5.2 — Renomear Colunas (executar por tabela)

> ⚠️ Execute uma tabela por vez e valide antes de prosseguir.

**Começar pelas dimensões simples:**

```sql
-- dim_aspecto
ALTER TABLE tb_aspecto 
    CHANGE COLUMN cod_asp aspecto_id TINYINT UNSIGNED NOT NULL,
    CHANGE COLUMN nome_asp aspecto_nome VARCHAR(100);

-- dim_nota
ALTER TABLE tb_nota 
    CHANGE COLUMN nota_cod nota_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN nota_nome nota_txt TEXT;

-- dim_fonte
ALTER TABLE tb_fonte 
    CHANGE COLUMN fnt_cod fonte_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN fnt_sigla fonte_sigla VARCHAR(30),
    CHANGE COLUMN fnt_nome fonte_nome VARCHAR(250);

-- dim_unidade
ALTER TABLE tb_unidade 
    CHANGE COLUMN unid_cod unidade_id TINYINT UNSIGNED NOT NULL,
    CHANGE COLUMN unid_nome unidade_nome VARCHAR(100);

-- dim_territorio
ALTER TABLE tb_rel_ter
    CHANGE COLUMN ter_cod territorio_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN ter_tipo territorio_tipo VARCHAR(50);
```

**Depois as dimensões com mais colunas:**

```sql
-- dim_localidade
ALTER TABLE tb_localidade 
    CHANGE COLUMN loc_cod localidade_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN loc_pai localidade_pai_id SMALLINT UNSIGNED,
    CHANGE COLUMN loc_nome localidade_nome VARCHAR(250),
    CHANGE COLUMN loc_nivel localidade_nivel TINYINT UNSIGNED,
    CHANGE COLUMN loc_ordem localidade_ordem SMALLINT UNSIGNED,
    CHANGE COLUMN loc_cod_ibge localidade_cod_ibge INT UNSIGNED;

-- dim_variavel (colunas principais)
ALTER TABLE tb_variavel 
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN unid_cod unidade_id TINYINT UNSIGNED,
    CHANGE COLUMN var_nome variavel_nome VARCHAR(500),
    CHANGE COLUMN var_asp aspecto_id TINYINT UNSIGNED;

-- dim_base_cartografica
ALTER TABLE tb_base_cart 
    CHANGE COLUMN cod_base base_cartografica_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN nome_base base_cartografica_nome VARCHAR(200),
    CHANGE COLUMN ano base_ano SMALLINT UNSIGNED,
    CHANGE COLUMN nro_munic municipio_qtd SMALLINT UNSIGNED;
```

**Tabelas de relacionamento:**

```sql
-- rel_variavel_fonte
ALTER TABLE tb_rel_var_fnt 
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN fnt_cod fonte_id SMALLINT UNSIGNED NOT NULL;

-- rel_variavel_nota
ALTER TABLE tb_rel_var_nota 
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN nota_cod nota_id SMALLINT UNSIGNED NOT NULL;

-- rel_territorio_variavel
ALTER TABLE tb_rel_ter_var 
    CHANGE COLUMN ter_cod territorio_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN var_cod variavel_id SMALLINT UNSIGNED NOT NULL;

-- rel_base_ponto
ALTER TABLE tb_base_cart_ptos 
    CHANGE COLUMN Cod_loc localidade_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN base base_cartografica_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN PtoX ponto_x DECIMAL(15,6),
    CHANGE COLUMN PtoY ponto_y DECIMAL(15,6);

-- aux_localidade_hierarquia
ALTER TABLE tb_loc_pai 
    CHANGE COLUMN loc_cod localidade_id SMALLINT UNSIGNED NOT NULL,
    CHANGE COLUMN loc_pai localidade_pai_id SMALLINT UNSIGNED,
    CHANGE COLUMN loc_reg regiao_id SMALLINT UNSIGNED;
```

**Tabelas de log:**

```sql
-- log_busca
ALTER TABLE tb_log_busca 
    CHANGE COLUMN log_data busca_dh DATETIME,
    CHANGE COLUMN log_busca busca_termo VARCHAR(500);

-- log_erro_movimento
ALTER TABLE tb_erro_mvto 
    CHANGE COLUMN seq_mvto movimento_seq INT UNSIGNED,
    CHANGE COLUMN seq_cpo campo_seq INT UNSIGNED,
    CHANGE COLUMN msg_erro erro_msg TEXT;
```

### 5.3 — Renomear Tabelas

> ⚠️ Execute **somente após** todas as colunas terem sido renomeadas com sucesso.

```sql
RENAME TABLE
    tb_aspecto TO dim_aspecto,
    tb_nota TO dim_nota,
    tb_fonte TO dim_fonte,
    tb_unidade TO dim_unidade,
    tb_localidade TO dim_localidade,
    tb_variavel TO dim_variavel,
    tb_base_cart TO dim_base_cartografica,
    tb_rel_ter TO dim_territorio,
    tb_dados TO fact_indicador,
    tb_dados_mensal TO fact_indicador_mensal,
    tb_rel_var_fnt TO rel_variavel_fonte,
    tb_rel_var_nota TO rel_variavel_nota,
    tb_rel_ter_var TO rel_territorio_variavel,
    tb_base_cart_ptos TO rel_base_ponto,
    tb_loc_pai TO aux_localidade_hierarquia,
    tb_localidade_historico TO aux_localidade_historico,
    tb_localidade_regiao_planejamento_saude TO aux_localidade_regiao_saude,
    tb_consulta TO cfg_consulta,
    tb_infmun TO aux_info_municipio,
    tb_var_calculado TO cfg_variavel_calculada,
    tb_var_produto TO cfg_variavel_produto,
    tb_log_busca TO log_busca,
    tb_erro_mvto TO log_erro_movimento;
```

### 5.4 — Validar Nomenclatura

```sql
-- Verificar que não resta nenhuma tabela com prefixo tb_
SELECT TABLE_NAME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME LIKE 'tb_%';
-- Esperado: 0 registros

-- Listar tabelas agrupadas por tipo
SELECT 
    CASE 
        WHEN TABLE_NAME LIKE 'dim_%' THEN 'Dimensão'
        WHEN TABLE_NAME LIKE 'fact_%' THEN 'Fato'
        WHEN TABLE_NAME LIKE 'rel_%' THEN 'Relacionamento'
        WHEN TABLE_NAME LIKE 'aux_%' THEN 'Auxiliar'
        WHEN TABLE_NAME LIKE 'cfg_%' THEN 'Configuração'
        WHEN TABLE_NAME LIKE 'log_%' THEN 'Log'
        ELSE '⚠️ SEM PREFIXO'
    END AS tipo,
    TABLE_NAME AS tabela
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY tipo, TABLE_NAME;
```

### ✅ Checkpoint — Nomenclatura Padronizada

- [ ] Zero tabelas com prefixo `tb_`
- [ ] Todas as colunas em `snake_case`
- [ ] Prefixos corretos por tipo de tabela
- [ ] Query de validação retorna 0 tabelas sem prefixo

---

## 6. Exercício 4 — Análise dos Dados da Tabela Fato

**Objetivo:** Analisar os formatos de dados nas colunas `d_1980` a `d_2030` antes de normalizar

> ⚠️ Este exercício é **crítico**. Uma migração sem análise prévia resulta em **perda de dados**.

### 6.1 — Descobrir os Formatos

```sql
-- Contar tipos de valores em d_2020 (ano com mais dados)
SELECT 
    CASE
        WHEN d_2020 IS NULL OR TRIM(d_2020) = '' THEN 'VAZIO'
        WHEN TRIM(d_2020) = '-' THEN 'HIFEN (NULL)'
        WHEN TRIM(d_2020) REGEXP '^-?[0-9]+$' THEN 'INTEIRO'
        WHEN TRIM(d_2020) REGEXP '^-?[0-9]+,[0-9]+$' THEN 'DECIMAL_VIRGULA'
        WHEN TRIM(d_2020) REGEXP '^-?[0-9]+\\.[0-9]+$' THEN 'DECIMAL_PONTO'
        WHEN TRIM(d_2020) REGEXP '^-?[0-9]{1,3}(\\.[0-9]{3})+,[0-9]+$' THEN 'FORMATO_BR_COMPLETO'
        WHEN TRIM(d_2020) REGEXP '^-?[0-9]{1,3}(\\.[0-9]{3})+$' THEN 'INTEIRO_COM_MILHARES'
        WHEN TRIM(d_2020) REGEXP '[a-zA-Z]' THEN 'TEXTO'
        ELSE 'OUTRO'
    END AS tipo_dado,
    COUNT(*) AS quantidade,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_indicador), 2) AS percentual
FROM fact_indicador
GROUP BY tipo_dado
ORDER BY quantidade DESC;
```

### 6.2 — Ver Exemplos de Cada Tipo

```sql
-- Exemplos de valores com vírgula (formato BR)
SELECT DISTINCT d_2020
FROM fact_indicador
WHERE d_2020 REGEXP '^-?[0-9]+,[0-9]+$'
LIMIT 10;

-- Exemplos de valores com ponto e vírgula (BR completo)
SELECT DISTINCT d_2020
FROM fact_indicador
WHERE d_2020 REGEXP '^-?[0-9]{1,3}(\\.[0-9]{3})+,[0-9]+$'
LIMIT 10;

-- Exemplos de texto/caracteres especiais
SELECT DISTINCT d_2020
FROM fact_indicador
WHERE d_2020 REGEXP '[a-zA-Z]' OR d_2020 LIKE '%[%'
LIMIT 10;

-- Exemplos de valores com espaços
SELECT CONCAT("'", d_2020, "'") AS valor_com_aspas, LENGTH(d_2020) AS tamanho
FROM fact_indicador
WHERE d_2020 LIKE ' %' OR d_2020 LIKE '% '
LIMIT 10;
```

### 6.3 — Usando o Script Python

Execute o script de análise automática:

```bash
python analisar_dados_migracao.py
```

> 💡 Lembre-se de ajustar a configuração de conexão no script antes de executar.

### 📝 Entregável do Exercício 4

| Tipo de Dado | Quantidade | % | Exemplo |
|--------------|-----------|---|---------|
| INTEIRO | | | |
| HIFEN (NULL) | | | |
| DECIMAL_VIRGULA | | | |
| DECIMAL_PONTO | | | |
| FORMATO_BR_COMPLETO | | | |
| INTEIRO_COM_MILHARES | | | |
| TEXTO | | | |
| OUTRO | | | |

📝 **Pergunta para reflexão:** Por que **não** podemos simplesmente fazer `ALTER TABLE ... MODIFY COLUMN d_2020 DECIMAL(20,6)`?

---

## 7. Exercício 5 — Migração e Normalização

**Objetivo:** Criar a estrutura normalizada e migrar os dados com conversão de formatos

### 7.1 — Criar Dimensão Tempo

```sql
-- Criar tabela dim_tempo
CREATE TABLE dim_tempo (
    tempo_id INT AUTO_INCREMENT PRIMARY KEY,
    ano SMALLINT NOT NULL,
    decada SMALLINT GENERATED ALWAYS AS (FLOOR(ano / 10) * 10) STORED,
    seculo SMALLINT GENERATED ALWAYS AS (FLOOR((ano - 1) / 100) + 1) STORED,
    UNIQUE KEY uk_ano (ano)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Popular com anos de 1980 a 2030
INSERT INTO dim_tempo (ano)
WITH RECURSIVE anos AS (
    SELECT 1980 AS ano
    UNION ALL
    SELECT ano + 1 FROM anos WHERE ano < 2030
)
SELECT ano FROM anos;

-- Validar
SELECT * FROM dim_tempo ORDER BY ano;
-- Esperado: 51 registros (1980 a 2030)
```

### 7.2 — Criar a Função de Conversão

```sql
DELIMITER $$

DROP FUNCTION IF EXISTS fn_converter_valor_numerico$$

CREATE FUNCTION fn_converter_valor_numerico(valor_original VARCHAR(100))
RETURNS DECIMAL(20,6)
DETERMINISTIC
BEGIN
    DECLARE valor_limpo VARCHAR(100);
    DECLARE valor_final DECIMAL(20,6);

    SET valor_limpo = TRIM(valor_original);

    -- Nulo ou vazio → NULL
    IF valor_limpo IS NULL OR valor_limpo = '' THEN
        RETURN NULL;
    END IF;

    -- Hífen → NULL
    IF valor_limpo = '-' THEN
        RETURN NULL;
    END IF;

    -- Colchetes e texto → NULL
    IF valor_limpo LIKE '%[%' OR valor_limpo REGEXP '[a-zA-Z]' THEN
        RETURN NULL;
    END IF;

    -- Formato BR completo: 1.234.567,89
    IF valor_limpo REGEXP '^-?[0-9]{1,3}(\\.[0-9]{3})+,[0-9]+$' THEN
        SET valor_limpo = REPLACE(valor_limpo, '.', '');
        SET valor_limpo = REPLACE(valor_limpo, ',', '.');
    -- Formato BR decimal: 0,56
    ELSEIF valor_limpo REGEXP '^-?[0-9]+,[0-9]+$' THEN
        SET valor_limpo = REPLACE(valor_limpo, ',', '.');
    -- Inteiro com ponto de milhares: 1.234.567
    ELSEIF valor_limpo REGEXP '^-?[0-9]{1,3}(\\.[0-9]{3})+$' THEN
        SET valor_limpo = REPLACE(valor_limpo, '.', '');
    END IF;

    -- Tentar converter
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            SET valor_final = NULL;
        SET valor_final = CAST(valor_limpo AS DECIMAL(20,6));
    END;

    RETURN valor_final;
END$$

DELIMITER ;
```

### 7.3 — Testar a Função

```sql
-- Teste de todos os formatos encontrados
SELECT 
    valor_teste,
    fn_converter_valor_numerico(valor_teste) AS convertido
FROM (
    SELECT '12345' AS valor_teste
    UNION ALL SELECT '-'
    UNION ALL SELECT '0,56'
    UNION ALL SELECT '1.234.567,89'
    UNION ALL SELECT ' 385.623.865,48 '
    UNION ALL SELECT '1.067.267'
    UNION ALL SELECT '-0,23'
    UNION ALL SELECT '[1]'
    UNION ALL SELECT 'x'
    UNION ALL SELECT ''
    UNION ALL SELECT NULL
) testes;
```

**Resultado esperado:**

| valor_teste | convertido |
|-------------|-----------|
| 12345 | 12345.000000 |
| - | NULL |
| 0,56 | 0.560000 |
| 1.234.567,89 | 1234567.890000 |
| &nbsp;385.623.865,48&nbsp; | 385623865.480000 |
| 1.067.267 | 1067267.000000 |
| -0,23 | -0.230000 |
| [1] | NULL |
| x | NULL |
| *(vazio)* | NULL |
| NULL | NULL |

> ⚠️ **Se algum resultado não bater**, revise a função antes de prosseguir!

### 7.4 — Criar Tabela Fato

```sql
CREATE TABLE fact_indicador (
    indicador_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    -- Chaves estrangeiras
    localidade_id SMALLINT UNSIGNED NOT NULL,
    variavel_id SMALLINT UNSIGNED NOT NULL,
    tempo_id INT NOT NULL,

    -- Valores
    indicador_txt VARCHAR(100) NULL
        COMMENT 'Valor original preservado',
    indicador_vlr DECIMAL(20,6) NULL
        COMMENT 'Valor convertido para número',
    indicador_tipo ENUM('numero','texto','nulo_hifen','vazio','texto_especial') NOT NULL
        COMMENT 'Classificação do dado original',

    -- Controle
    carga_dh TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Índices
    UNIQUE KEY uk_indicador (localidade_id, variavel_id, tempo_id),
    KEY idx_tempo (tempo_id),
    KEY idx_tipo (indicador_tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

> 💡 **Observe:** A tabela original `fact_indicador` (ex-`tb_dados`) será renomeada para `fact_indicador_original` ao final, e esta nova tabela assumirá o nome `fact_indicador`.

### 7.5 — Migrar os Dados (1 ano para teste)

```sql
-- Migrar apenas d_2020 como teste
INSERT INTO fact_indicador 
    (localidade_id, variavel_id, tempo_id, indicador_txt, indicador_vlr, indicador_tipo)
SELECT 
    f.localidade_id,
    f.variavel_id,
    t.tempo_id,
    f.d_2020 AS indicador_txt,
    fn_converter_valor_numerico(f.d_2020) AS indicador_vlr,
    CASE
        WHEN TRIM(f.d_2020) IS NULL OR TRIM(f.d_2020) = '' THEN 'vazio'
        WHEN TRIM(f.d_2020) = '-' THEN 'nulo_hifen'
        WHEN TRIM(f.d_2020) REGEXP '[a-zA-Z]' THEN 'texto'
        WHEN TRIM(f.d_2020) LIKE '%[%' THEN 'texto_especial'
        ELSE 'numero'
    END AS indicador_tipo
FROM fact_indicador_original f
JOIN dim_tempo t ON t.ano = 2020
WHERE f.d_2020 IS NOT NULL;

-- Validar
SELECT 
    indicador_tipo,
    COUNT(*) AS qtd,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_indicador), 2) AS pct
FROM fact_indicador
GROUP BY indicador_tipo
ORDER BY qtd DESC;
```

### 7.6 — Migrar Todos os Anos

> ⚠️ Esta etapa pode demorar **10-30 minutos** dependendo do hardware.

```sql
-- Limpar a tabela de teste
TRUNCATE TABLE fact_indicador;

-- Executar migração completa via procedure
-- (ver arquivo funcao_conversao_dados.sql)
CALL sp_migrar_dados_para_fato();
```

Ou manualmente, repetindo o INSERT da seção 7.5 para cada ano:

```sql
-- Gerar os INSERTs para todos os anos
-- Pode usar um loop ou executar individualmente
-- Exemplo para d_2019:
INSERT INTO fact_indicador 
    (localidade_id, variavel_id, tempo_id, indicador_txt, indicador_vlr, indicador_tipo)
SELECT 
    f.localidade_id, f.variavel_id, t.tempo_id,
    f.d_2019, fn_converter_valor_numerico(f.d_2019),
    CASE
        WHEN TRIM(f.d_2019) IS NULL OR TRIM(f.d_2019) = '' THEN 'vazio'
        WHEN TRIM(f.d_2019) = '-' THEN 'nulo_hifen'
        WHEN TRIM(f.d_2019) REGEXP '[a-zA-Z]' THEN 'texto'
        WHEN TRIM(f.d_2019) LIKE '%[%' THEN 'texto_especial'
        ELSE 'numero'
    END
FROM fact_indicador_original f
JOIN dim_tempo t ON t.ano = 2019
WHERE f.d_2019 IS NOT NULL;
-- Repetir para cada ano de 1980 a 2030...
```

### 7.7 — Validar Migração Completa

```sql
-- 1. Total de registros migrados
SELECT COUNT(*) AS total FROM fact_indicador;
-- Esperado: ~3.032.785

-- 2. Distribuição de tipos
SELECT 
    indicador_tipo,
    COUNT(*) AS qtd,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM fact_indicador), 2) AS pct
FROM fact_indicador
GROUP BY indicador_tipo
ORDER BY qtd DESC;

-- 3. Verificar se há números que não converteram
SELECT COUNT(*) AS numeros_sem_conversao
FROM fact_indicador
WHERE indicador_tipo = 'numero' AND indicador_vlr IS NULL;
-- Esperado: 0

-- 4. Renomear tabela original como backup
RENAME TABLE fact_indicador_original TO fact_indicador_backup_colunar;
```

### ✅ Checkpoint — Migração Concluída

- [ ] dim_tempo criada com 51 registros
- [ ] Função de conversão testada com todos os formatos
- [ ] fact_indicador populada com dados de todos os anos
- [ ] Distribuição de tipos compatível com a análise
- [ ] Zero números sem conversão
- [ ] Tabela original preservada como backup

---

## 8. Exercício 6 — Chaves Primárias e Estrangeiras

**Objetivo:** Implementar integridade referencial no Data Warehouse

### 8.1 — Criar Chaves Primárias

```sql
-- Dimensões simples
ALTER TABLE dim_aspecto ADD PRIMARY KEY (aspecto_id);
ALTER TABLE dim_nota ADD PRIMARY KEY (nota_id);
ALTER TABLE dim_fonte ADD PRIMARY KEY (fonte_id);
ALTER TABLE dim_unidade ADD PRIMARY KEY (unidade_id);
ALTER TABLE dim_territorio ADD PRIMARY KEY (territorio_id);

-- Dimensões compostas
ALTER TABLE dim_localidade ADD PRIMARY KEY (localidade_id);
ALTER TABLE dim_variavel ADD PRIMARY KEY (variavel_id);
ALTER TABLE dim_base_cartografica ADD PRIMARY KEY (base_cartografica_id);

-- Relacionamentos (PKs compostas)
ALTER TABLE rel_variavel_fonte ADD PRIMARY KEY (variavel_id, fonte_id);
ALTER TABLE rel_variavel_nota ADD PRIMARY KEY (variavel_id, nota_id);
ALTER TABLE rel_territorio_variavel ADD PRIMARY KEY (territorio_id, variavel_id);
ALTER TABLE rel_base_ponto ADD PRIMARY KEY (localidade_id, base_cartografica_id);

-- Auxiliares
ALTER TABLE aux_localidade_hierarquia ADD PRIMARY KEY (localidade_id);
```

### 8.2 — Validar PKs

```sql
SELECT 
    TABLE_NAME AS tabela,
    CONSTRAINT_NAME AS pk
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
  AND CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY TABLE_NAME;
-- Esperado: Mínimo 13 PKs
```

### 8.3 — Criar Chaves Estrangeiras

```sql
-- dim_variavel → dim_unidade
ALTER TABLE dim_variavel
    ADD CONSTRAINT fk_variavel_unidade
    FOREIGN KEY (unidade_id) REFERENCES dim_unidade(unidade_id);

-- dim_variavel → dim_aspecto
ALTER TABLE dim_variavel
    ADD CONSTRAINT fk_variavel_aspecto
    FOREIGN KEY (aspecto_id) REFERENCES dim_aspecto(aspecto_id);

-- fact_indicador → dim_localidade
ALTER TABLE fact_indicador
    ADD CONSTRAINT fk_fact_localidade
    FOREIGN KEY (localidade_id) REFERENCES dim_localidade(localidade_id);

-- fact_indicador → dim_variavel
ALTER TABLE fact_indicador
    ADD CONSTRAINT fk_fact_variavel
    FOREIGN KEY (variavel_id) REFERENCES dim_variavel(variavel_id);

-- fact_indicador → dim_tempo
ALTER TABLE fact_indicador
    ADD CONSTRAINT fk_fact_tempo
    FOREIGN KEY (tempo_id) REFERENCES dim_tempo(tempo_id);

-- rel_variavel_fonte → dim_variavel / dim_fonte
ALTER TABLE rel_variavel_fonte
    ADD CONSTRAINT fk_rel_vf_variavel
    FOREIGN KEY (variavel_id) REFERENCES dim_variavel(variavel_id),
    ADD CONSTRAINT fk_rel_vf_fonte
    FOREIGN KEY (fonte_id) REFERENCES dim_fonte(fonte_id);

-- rel_variavel_nota → dim_variavel / dim_nota
ALTER TABLE rel_variavel_nota
    ADD CONSTRAINT fk_rel_vn_variavel
    FOREIGN KEY (variavel_id) REFERENCES dim_variavel(variavel_id),
    ADD CONSTRAINT fk_rel_vn_nota
    FOREIGN KEY (nota_id) REFERENCES dim_nota(nota_id);

-- rel_territorio_variavel → dim_territorio / dim_variavel
ALTER TABLE rel_territorio_variavel
    ADD CONSTRAINT fk_rel_tv_territorio
    FOREIGN KEY (territorio_id) REFERENCES dim_territorio(territorio_id),
    ADD CONSTRAINT fk_rel_tv_variavel
    FOREIGN KEY (variavel_id) REFERENCES dim_variavel(variavel_id);

-- rel_base_ponto → dim_localidade / dim_base_cartografica
ALTER TABLE rel_base_ponto
    ADD CONSTRAINT fk_rel_bp_localidade
    FOREIGN KEY (localidade_id) REFERENCES dim_localidade(localidade_id),
    ADD CONSTRAINT fk_rel_bp_base
    FOREIGN KEY (base_cartografica_id) REFERENCES dim_base_cartografica(base_cartografica_id);
```

### 8.4 — Validar FKs

```sql
SELECT 
    TABLE_NAME AS tabela,
    CONSTRAINT_NAME AS fk,
    REFERENCED_TABLE_NAME AS referencia
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = DATABASE()
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
-- Esperado: Mínimo 11 FKs

-- Testar integridade: inserir registro órfão (deve falhar)
INSERT INTO fact_indicador (localidade_id, variavel_id, tempo_id, indicador_tipo)
VALUES (99999, 1, 1, 'numero');
-- Esperado: ERROR 1452 - Cannot add or update a child row
```

### ✅ Checkpoint — Integridade Implementada

- [ ] Mínimo 13 PKs criadas
- [ ] Mínimo 11 FKs criadas
- [ ] Teste de integridade falha corretamente ao inserir órfão
- [ ] Nenhum erro ao criar PKs/FKs (se houver, resolver dados antes)

---

## 9. Exercício 7 — Validação Final e Consultas

**Objetivo:** Validar o Data Warehouse completo e testar consultas típicas

### 9.1 — Validação Completa

```sql
-- Resumo do Data Warehouse
SELECT 
    CASE 
        WHEN TABLE_NAME LIKE 'dim_%' THEN '📐 Dimensão'
        WHEN TABLE_NAME LIKE 'fact_%' THEN '📊 Fato'
        WHEN TABLE_NAME LIKE 'rel_%' THEN '🔗 Relacionamento'
        WHEN TABLE_NAME LIKE 'aux_%' THEN '📎 Auxiliar'
        WHEN TABLE_NAME LIKE 'cfg_%' THEN '⚙️ Configuração'
        WHEN TABLE_NAME LIKE 'log_%' THEN '📝 Log'
    END AS tipo,
    TABLE_NAME AS tabela,
    TABLE_ROWS AS registros
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME NOT LIKE '%backup%'
ORDER BY tipo, TABLE_NAME;

-- Contar constraints
SELECT 
    CONSTRAINT_TYPE AS tipo,
    COUNT(*) AS quantidade
FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE()
GROUP BY CONSTRAINT_TYPE;
```

### 9.2 — Consultas Típicas de Data Warehouse

**Consulta 1 — Indicadores de uma localidade em um ano:**
```sql
SELECT 
    l.localidade_nome,
    v.variavel_nome,
    u.unidade_nome,
    f.indicador_vlr,
    t.ano
FROM fact_indicador f
JOIN dim_localidade l ON f.localidade_id = l.localidade_id
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
JOIN dim_unidade u ON v.unidade_id = u.unidade_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE l.localidade_nome LIKE '%Rio de Janeiro%'
  AND t.ano = 2020
  AND f.indicador_tipo = 'numero'
ORDER BY v.variavel_nome
LIMIT 20;
```

**Consulta 2 — Evolução de um indicador ao longo dos anos:**
```sql
SELECT 
    t.ano,
    f.indicador_vlr
FROM fact_indicador f
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
WHERE v.variavel_nome LIKE '%população%'
  AND f.localidade_id = 33  -- Ajustar conforme localidade
  AND f.indicador_tipo = 'numero'
ORDER BY t.ano;
```

**Consulta 3 — Ranking de localidades por indicador:**
```sql
SELECT 
    l.localidade_nome,
    f.indicador_vlr
FROM fact_indicador f
JOIN dim_localidade l ON f.localidade_id = l.localidade_id
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE v.variavel_id = 100  -- Ajustar conforme variável
  AND t.ano = 2020
  AND f.indicador_tipo = 'numero'
ORDER BY f.indicador_vlr DESC
LIMIT 10;
```

**Consulta 4 — Fontes de uma variável:**
```sql
SELECT 
    v.variavel_nome,
    fo.fonte_sigla,
    fo.fonte_nome
FROM rel_variavel_fonte rf
JOIN dim_variavel v ON rf.variavel_id = v.variavel_id
JOIN dim_fonte fo ON rf.fonte_id = fo.fonte_id
WHERE v.variavel_id = 100;
```

### 9.3 — Comparação Antes x Depois

```sql
-- ANTES (estrutura antiga — consulta para referência)
-- SELECT l.loc_nome, v.var_nome, d.d_2020
-- FROM tb_dados d
-- JOIN tb_localidade l ON d.loc_cod = l.loc_cod
-- JOIN tb_variavel v ON d.var_cod = v.var_cod
-- WHERE l.loc_nivel = 3;

-- DEPOIS (estrutura nova)
SELECT 
    l.localidade_nome,
    v.variavel_nome,
    f.indicador_vlr
FROM fact_indicador f
JOIN dim_localidade l ON f.localidade_id = l.localidade_id
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE l.localidade_nivel = 3
  AND t.ano = 2020
  AND f.indicador_tipo = 'numero';
```

### 📝 Entregável Final

| Critério | Status |
|----------|--------|
| Banco sem tabelas com prefixo `tb_` | ⬜ |
| Todas as colunas em `snake_case` | ⬜ |
| Zero duplicatas em chaves primárias | ⬜ |
| Zero registros órfãos | ⬜ |
| dim_tempo com 51 registros | ⬜ |
| fact_indicador com ~3M registros | ⬜ |
| Mínimo 13 PKs criadas | ⬜ |
| Mínimo 11 FKs criadas | ⬜ |
| Consultas de teste executam < 2s | ⬜ |
| Tabela original preservada como backup | ⬜ |

---

## 10. Referência Rápida

### Arquivos do Projeto

| Arquivo | Descrição |
|---------|-----------|
| `conexao_mysql.py` | Script de conexão ao banco |
| `validar_refatoracao.py` | Validação automática da estrutura |
| `analisar_dados_migracao.py` | Análise de tipos de dados nas colunas d_YYYY |
| `funcao_conversao_dados.sql` | Funções SQL + procedure de migração |
| `script_padronizacao_nomenclatura.sql` | Script completo de renomeação |
| `padrao_nomenclatura.md` | Documentação do padrão de nomenclatura |
| `RELATORIO_ANALISE_DADOS.md` | Relatório detalhado da análise de dados |
| `CRONOGRAMA_IMPLEMENTACAO.md` | Cronograma completo do projeto |

### Modelo Estrela (Star Schema)

```
                    ┌──────────────────┐
                    │   dim_aspecto    │
                    │   aspecto_id PK  │
                    │   aspecto_nome   │
                    └────────┬─────────┘
                             │
┌──────────────────┐    ┌────┴──────────────┐    ┌──────────────────┐
│   dim_unidade    │    │   dim_variavel    │    │   dim_fonte      │
│   unidade_id PK  ├────┤   variavel_id PK  ├────┤   fonte_id PK    │
│   unidade_nome   │    │   variavel_nome   │    │   fonte_nome     │
└──────────────────┘    │   unidade_id FK   │    └──────────────────┘
                        │   aspecto_id FK   │
                        └────────┬──────────┘
                                 │
┌──────────────────┐    ┌────────┴──────────┐    ┌──────────────────┐
│  dim_localidade  │    │  fact_indicador   │    │    dim_tempo     │
│  localidade_id PK├────┤  indicador_id PK  ├────┤  tempo_id PK    │
│  localidade_nome │    │  localidade_id FK │    │  ano             │
│  localidade_nivel│    │  variavel_id FK   │    │  decada          │
└──────────────────┘    │  tempo_id FK      │    └──────────────────┘
                        │  indicador_vlr    │
                        │  indicador_txt    │
                        │  indicador_tipo   │
                        └───────────────────┘
```

### Comandos Úteis

```sql
-- Ver estrutura de uma tabela
DESCRIBE dim_localidade;

-- Ver constraints de uma tabela
SELECT * FROM information_schema.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'fact_indicador';

-- Contar registros rapidamente
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = DATABASE()
ORDER BY TABLE_ROWS DESC;

-- Ver índices
SHOW INDEX FROM fact_indicador;
```

### Contato para Dúvidas

Em caso de problemas durante o hands-on:

1. Verifique se a conexão com o servidor `10.209.59.96` está ativa
2. Confirme que está usando o banco correto (`SELECT DATABASE();`)
3. Consulte os documentos de referência na pasta do projeto
4. Chame o instrutor

---

**Bom trabalho! 🚀**
