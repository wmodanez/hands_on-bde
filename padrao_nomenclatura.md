# Padrão de Nomenclatura do Banco de Dados

## Data Warehouse - Banco 'imp'

**Versão:** 1.0  
**Data:** 24/02/2026  
**Objetivo:** Padronizar nomes de tabelas e colunas para facilitar manutenção e compreensão

---

## 📋 Sumário

1. [Problemas Identificados](#problemas-identificados)
2. [Convenções Adotadas](#convenções-adotadas)
3. [Nomenclatura de Tabelas](#nomenclatura-de-tabelas)
4. [Nomenclatura de Colunas](#nomenclatura-de-colunas)
5. [Mapeamento Completo](#mapeamento-completo)
6. [Exemplos de Uso](#exemplos-de-uso)

---

## ❌ Problemas Identificados

### Inconsistências Atuais

| Problema | Exemplos |
|----------|----------|
| **Prefixos inconsistentes** | `cod_asp` vs `nota_cod` vs `Cod_loc` |
| **Case misto** | `Cod_loc`, `PtoX`, `loc_cod` |
| **Abreviações variadas** | `fnt` (fonte), `asp` (aspecto), `con` (consulta), `var` (variável) |
| **Nomes não descritivos** | `d_1980`, `d_1981` (colunas de dados) |
| **Prefixo de tabela redundante** | `tb_` em todas as tabelas |
| **Campos sem padrão** | `base`, `ano`, `nro_munic` sem prefixo |

### Mapeamento de Inconsistências por Tabela

```
tb_aspecto:     cod_asp, nome_asp          (prefixo: cod_, nome_)
tb_nota:        nota_cod, nota_nome        (prefixo: nota_)
tb_fonte:       fnt_cod, fnt_sigla         (prefixo: fnt_)
tb_localidade:  loc_cod, loc_nome          (prefixo: loc_)
tb_variavel:    var_cod, var_nome          (prefixo: var_)
tb_unidade:     unid_cod, unid_nome        (prefixo: unid_)
tb_consulta:    con_cod, con_nome          (prefixo: con_)
tb_base_cart:   cod_base, nome_base, ano   (MISTO!)
tb_base_cart_ptos: Cod_loc, base, PtoX     (MISTO COM CASE!)
tb_rel_ter:     ter_cod, ter_tipo          (prefixo: ter_)
```

---

## ✅ Convenções Adotadas

### Regras Gerais

1. **Idioma:** Português para nomes de domínio, inglês para termos técnicos
2. **Case:** `snake_case` (letras minúsculas, palavras separadas por underscore)
3. **Tamanho:** Máximo 30 caracteres
4. **Caracteres:** Apenas letras, números e underscore

### Prefixos de Tabelas

| Prefixo | Uso | Exemplo |
|---------|-----|---------|
| `dim_` | Tabelas de Dimensão (DW) | `dim_localidade` |
| `fact_` | Tabelas de Fato (DW) | `fact_dados` |
| `rel_` | Tabelas de Relacionamento N:N | `rel_variavel_fonte` |
| `log_` | Tabelas de Log/Auditoria | `log_busca` |
| `cfg_` | Tabelas de Configuração | `cfg_consulta` |
| `aux_` | Tabelas Auxiliares | `aux_localidade_pai` |

### Sufixos de Colunas

| Sufixo | Uso | Exemplo |
|--------|-----|---------|
| `_id` | Chave Primária (surrogate key) | `localidade_id` |
| `_cod` | Código Natural/Business Key | `localidade_cod` |
| `_nome` | Nome/Descrição curta | `localidade_nome` |
| `_desc` | Descrição longa | `variavel_desc` |
| `_dt` | Data (sem hora) | `registro_dt` |
| `_dh` | Data/Hora (timestamp) | `criacao_dh` |
| `_qtd` | Quantidade | `municipio_qtd` |
| `_vlr` | Valor monetário/numérico | `indicador_vlr` |
| `_ind` | Indicador booleano (S/N, 0/1) | `ativo_ind` |
| `_txt` | Texto longo | `historico_txt` |
| `_ref` | Referência (FK) | `localidade_ref` |

### Padrão para Chaves

| Tipo | Formato | Exemplo |
|------|---------|---------|
| **Primary Key (surrogate)** | `{tabela}_id` | `localidade_id` |
| **Primary Key (natural)** | `{tabela}_cod` | `localidade_cod` |
| **Foreign Key** | `{tabela_ref}_id` ou `{tabela_ref}_cod` | `localidade_id` |
| **Composite PK** | `{tabela1}_cod, {tabela2}_cod` | `localidade_cod, variavel_cod` |

---

## 📦 Nomenclatura de Tabelas

### De-Para: Tabelas

| Nome Atual | Nome Proposto | Tipo | Descrição |
|------------|---------------|------|-----------|
| `tb_aspecto` | `dim_aspecto` | Dimensão | Aspectos/categorias das variáveis |
| `tb_nota` | `dim_nota` | Dimensão | Notas/observações das variáveis |
| `tb_fonte` | `dim_fonte` | Dimensão | Fontes de dados |
| `tb_unidade` | `dim_unidade` | Dimensão | Unidades de medida |
| `tb_localidade` | `dim_localidade` | Dimensão | Localidades geográficas |
| `tb_variavel` | `dim_variavel` | Dimensão | Variáveis/indicadores |
| `tb_base_cart` | `dim_base_cartografica` | Dimensão | Bases cartográficas |
| `tb_rel_ter` | `dim_territorio` | Dimensão | Territórios |
| `tb_dados` | `fact_indicador` | Fato | Dados dos indicadores |
| `tb_rel_var_fnt` | `rel_variavel_fonte` | Relação | Variável ↔ Fonte |
| `tb_rel_var_nota` | `rel_variavel_nota` | Relação | Variável ↔ Nota |
| `tb_rel_ter_var` | `rel_territorio_variavel` | Relação | Território ↔ Variável |
| `tb_base_cart_ptos` | `rel_base_ponto` | Relação | Base cartográfica ↔ Pontos |
| `tb_loc_pai` | `aux_localidade_hierarquia` | Auxiliar | Hierarquia de localidades |
| `tb_localidade_historico` | `aux_localidade_historico` | Auxiliar | Histórico de localidades |
| `tb_localidade_regiao_planejamento_saude` | `aux_localidade_regiao_saude` | Auxiliar | Regiões de planejamento saúde |
| `tb_consulta` | `cfg_consulta` | Config | Consultas salvas |
| `tb_log_busca` | `log_busca` | Log | Log de buscas |
| `tb_erro_mvto` | `log_erro_movimento` | Log | Log de erros de movimento |
| `tb_dados_mensal` | `fact_indicador_mensal` | Fato | Dados mensais (vazia) |
| `tb_infmun` | `aux_info_municipio` | Auxiliar | Info de municípios (vazia) |
| `tb_var_calculado` | `cfg_variavel_calculada` | Config | Variáveis calculadas (vazia) |
| `tb_var_produto` | `cfg_variavel_produto` | Config | Variáveis produto (vazia) |
| `dim_tempo` | `dim_tempo` | Dimensão | Dimensão tempo (NOVA) |

---

## 📝 Nomenclatura de Colunas

### Padrão Geral

```
{entidade}_{atributo}[_{sufixo}]
```

**Exemplos:**
- `localidade_cod` → código da localidade
- `variavel_nome` → nome da variável
- `indicador_vlr` → valor do indicador
- `registro_dh` → data/hora do registro

### De-Para: Colunas por Tabela

#### dim_aspecto (tb_aspecto)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `cod_asp` | `aspecto_id` | PK - Código do aspecto |
| `nome_asp` | `aspecto_nome` | Nome do aspecto |

#### dim_nota (tb_nota)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `nota_cod` | `nota_id` | PK - Código da nota |
| `nota_nome` | `nota_txt` | Texto da nota |

#### dim_fonte (tb_fonte)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `fnt_cod` | `fonte_id` | PK - Código da fonte |
| `fnt_sigla` | `fonte_sigla` | Sigla da fonte |
| `fnt_nome` | `fonte_nome` | Nome completo da fonte |

#### dim_unidade (tb_unidade)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `unid_cod` | `unidade_id` | PK - Código da unidade |
| `unid_nome` | `unidade_nome` | Nome da unidade |

#### dim_localidade (tb_localidade)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `loc_cod` | `localidade_id` | PK - Código da localidade |
| `loc_pai` | `localidade_pai_id` | FK - Localidade pai |
| `loc_nome` | `localidade_nome` | Nome da localidade |
| `loc_nivel` | `localidade_nivel` | Nível hierárquico |
| `loc_ordem` | `localidade_ordem` | Ordem de exibição |
| `loc_cep_cod_adm` | `localidade_cep_adm` | Código CEP administrativo |
| `loc_cod_ibge` | `localidade_cod_ibge` | Código IBGE |
| `loc_reg_plan` | `regiao_planejamento_id` | FK - Região planejamento |
| `loc_id_sig` | `sig_id` | ID no SIG |
| `loc_reg_plan_macro_saude` | `regiao_macro_saude_id` | FK - Macro região saúde |
| `loc_reg_plan_micro_saude` | `regiao_micro_saude_id` | FK - Micro região saúde |

#### dim_variavel (tb_variavel)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `var_cod` | `variavel_id` | PK - Código da variável |
| `var_cod_old` | `variavel_cod_legado` | Código no sistema antigo |
| `var_ordem` | `variavel_ordem` | Ordem de exibição |
| `unid_cod` | `unidade_id` | FK - Unidade de medida |
| `var_nome` | `variavel_nome` | Nome da variável |
| `var_periodo` | `variavel_periodo` | Período de abrangência |
| `var_ultano` | `variavel_ultimo_ano` | Último ano com dados |
| `var_def` | `variavel_definicao_txt` | Definição da variável |
| `var_historico` | `variavel_historico_txt` | Histórico |
| `var_mapa_possivel` | `mapa_disponivel_ind` | Indicador: mapa disponível |
| `var_nome_grafico` | `grafico_nome` | Nome para gráficos |
| `var_nome_grafico2` | `grafico_nome_alt` | Nome alternativo gráficos |
| `var_grafico` | `grafico_disponivel_ind` | Indicador: gráfico disponível |
| `var_grafico_ordem` | `grafico_ordem` | Ordem no gráfico |
| `var_mascara` | `valor_mascara` | Máscara de formatação |
| `var_agregacao` | `agregacao_tipo` | Tipo de agregação |
| `var_funcao` | `funcao_id` | FK - Função |
| `var_variavel` | `variavel_pai_id` | FK - Variável pai |
| `var_campo` | `campo_id` | FK - Campo |
| `var_asp` | `aspecto_id` | FK - Aspecto |
| `var_sig` | `sig_codigo` | Código no SIG |
| `var_geo` | `geo_disponivel_ind` | Indicador: georeferenciado |
| `var_estatistica_geo` | `estatistica_geo_ind` | Indicador: estatística geo |

#### fact_indicador (tb_dados) - ⚠️ REQUER NORMALIZAÇÃO

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `loc_cod` | `localidade_id` | PK/FK - Localidade |
| `var_cod` | `variavel_id` | PK/FK - Variável |
| `d_1980` a `d_2030` | **Normalizar** | Valores por ano (formatos mistos!) |

**⚠️ DESCOBERTA CRÍTICA NA ANÁLISE:**
As colunas `d_1980` a `d_2030` contêm:
- 49.35% inteiros: `3, 4, 12, 17`
- 45.88% hífen como NULL: `'-'`
- 2.69% decimais com vírgula: `0,56, 0,52`
- 1.89% decimais com ponto: `1.496, 1.163`
- 0.09% texto especial: `[1]`
- 0.07% formato BR completo: `40.000,00`, `1.234.567,89`
- 0.01% formato US com milhares: `1,234.56`
- 0.01% marcadores de texto: `'x'`
- Valores com espaços: `' 385.623.865,48 '`

**Estrutura Normalizada Proposta (fact_indicador):**

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| `indicador_id` | BIGINT AUTO_INCREMENT | PK - Surrogate key |
| `localidade_id` | SMALLINT UNSIGNED | FK - Localidade |
| `variavel_id` | SMALLINT UNSIGNED | FK - Variável |
| `tempo_id` | INT | FK - Dimensão tempo |
| `indicador_txt` | VARCHAR(100) NULL | Valor original preservado |
| `indicador_vlr` | DECIMAL(20,6) NULL | Valor convertido (NULL se não numérico) |
| `indicador_tipo` | ENUM | 'numero', 'texto', 'nulo_hifen', 'vazio', 'texto_especial' |
| `conversao_ok` | BOOLEAN (GENERATED) | Indica se conversão foi bem-sucedida |
| `carga_dh` | TIMESTAMP | Data/hora da carga |

**Regras de Conversão (ver funcao_conversao_dados.sql):**
- `'-'` → NULL (45% dos dados)
- `'1.234.567,89'` → `1234567.89` (formato BR com milhares)
- `'0,56'` → `0.56` (formato BR decimal)
- `'1,234.56'` → `1234.56` (formato US)
- `' 385.623.865,48 '` → `385623865.48` (trim + conversão)
- `'[1]'`, `'x'` → NULL com tipo='texto_especial'

#### dim_base_cartografica (tb_base_cart)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `cod_base` | `base_cartografica_id` | PK - Código da base |
| `nome_base` | `base_cartografica_nome` | Nome da base |
| `ano` | `base_ano` | Ano de referência |
| `nro_munic` | `municipio_qtd` | Quantidade de municípios |

#### rel_base_ponto (tb_base_cart_ptos)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `Cod_loc` | `localidade_id` | PK/FK - Localidade |
| `base` | `base_cartografica_id` | PK/FK - Base cartográfica |
| `PtoX` | `ponto_x` | Coordenada X |
| `PtoY` | `ponto_y` | Coordenada Y |

#### cfg_consulta (tb_consulta)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `con_cod` | `consulta_id` | PK - Código da consulta |
| `con_nome` | `consulta_nome` | Nome da consulta |
| `con_usu` | `usuario_id` | FK - Usuário |
| `con_vars` | `variaveis_json` | JSON de variáveis |
| `con_locs` | `localidades_json` | JSON de localidades |
| `con_anos` | `anos_json` | JSON de anos |
| `con_ordem` | `ordem_json` | JSON de ordenação |

#### dim_territorio (tb_rel_ter)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `ter_cod` | `territorio_id` | PK - Código do território |
| `ter_tipo` | `territorio_tipo` | Tipo do território |

#### rel_territorio_variavel (tb_rel_ter_var)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `ter_cod` | `territorio_id` | PK/FK - Território |
| `var_cod` | `variavel_id` | PK/FK - Variável |
| `var_tipo` | `relacao_tipo` | Tipo da relação |

#### rel_variavel_fonte (tb_rel_var_fnt)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `var_cod` | `variavel_id` | PK/FK - Variável |
| `fnt_cod` | `fonte_id` | PK/FK - Fonte |

#### rel_variavel_nota (tb_rel_var_nota)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `var_cod` | `variavel_id` | PK/FK - Variável |
| `nota_cod` | `nota_id` | PK/FK - Nota |

#### aux_localidade_hierarquia (tb_loc_pai)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `loc_cod` | `localidade_id` | PK/FK - Localidade |
| `loc_pai` | `localidade_pai_id` | FK - Localidade pai |
| `loc_reg` | `regiao_id` | FK - Região |

#### aux_localidade_historico (tb_localidade_historico)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `loc_cod` | `localidade_id` | PK/FK - Localidade |
| `loc_historico` | `historico_txt` | Texto do histórico |

#### log_busca (tb_log_busca)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `log_data` | `busca_dh` | Data/hora da busca |
| `log_busca` | `busca_termo` | Termo buscado |

#### log_erro_movimento (tb_erro_mvto)

| Coluna Atual | Coluna Proposta | Descrição |
|--------------|-----------------|-----------|
| `seq_mvto` | `movimento_seq` | Sequência do movimento |
| `seq_cpo` | `campo_seq` | Sequência do campo |
| `msg_erro` | `erro_msg` | Mensagem de erro |

---

## 🔄 Mapeamento Completo

### Tabela de Referência Rápida

```
TABELAS:
tb_aspecto                → dim_aspecto
tb_nota                   → dim_nota
tb_fonte                  → dim_fonte
tb_unidade                → dim_unidade
tb_localidade             → dim_localidade
tb_variavel               → dim_variavel
tb_base_cart              → dim_base_cartografica
tb_rel_ter                → dim_territorio
tb_dados                  → fact_indicador
tb_rel_var_fnt            → rel_variavel_fonte
tb_rel_var_nota           → rel_variavel_nota
tb_rel_ter_var            → rel_territorio_variavel
tb_base_cart_ptos         → rel_base_ponto
tb_loc_pai                → aux_localidade_hierarquia
tb_localidade_historico   → aux_localidade_historico
tb_localidade_regiao_...  → aux_localidade_regiao_saude
tb_consulta               → cfg_consulta
tb_log_busca              → log_busca
tb_erro_mvto              → log_erro_movimento

SUFIXOS DE COLUNA:
_cod, cod_*  → _id (quando PK/FK)
_nome, nome_ → _nome (padronizado)
_sigla       → _sigla (mantido)
_def         → _definicao_txt
_historico   → _historico_txt
_possivel    → _disponivel_ind
d_YYYY       → normalizar para tempo_id + indicador_vlr
```

---

## 📖 Exemplos de Uso

### Consulta com Nomenclatura Antiga

```sql
SELECT 
    l.loc_nome,
    v.var_nome,
    d.d_2020
FROM tb_dados d
JOIN tb_localidade l ON d.loc_cod = l.loc_cod
JOIN tb_variavel v ON d.var_cod = v.var_cod
WHERE l.loc_nivel = 3;
```

### Consulta com Nomenclatura Nova

```sql
SELECT 
    l.localidade_nome,
    v.variavel_nome,
    f.indicador_vlr
FROM fact_indicador f
JOIN dim_localidade l ON f.localidade_id = l.localidade_id
JOIN dim_variavel v ON f.variavel_id = v.variavel_id
JOIN dim_tempo t ON f.tempo_id = t.tempo_id
WHERE l.localidade_nivel = 3
  AND t.ano = 2020;
```

### Benefícios da Nova Nomenclatura

1. **Autoexplicativa:** Os nomes indicam claramente o conteúdo
2. **Consistente:** Mesmo padrão em todas as tabelas
3. **Escalável:** Fácil adicionar novas tabelas seguindo o padrão
4. **Compatível com DW:** Prefixos `dim_`, `fact_`, `rel_` facilitam identificação

---

## 📋 Checklist de Implementação

- [ ] Backup completo do banco
- [ ] Executar script de renomeação de tabelas
- [ ] Executar script de renomeação de colunas
- [ ] Atualizar views e procedures
- [ ] Atualizar aplicações que acessam o banco
- [ ] Testar integridade referencial
- [ ] Documentar alterações

---

**Documento gerado em:** 24/02/2026
