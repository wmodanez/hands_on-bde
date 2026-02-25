"""
Script de Validação e Execução da Refatoração para Data Warehouse
Banco de dados: imp
Data: 24/02/2026
Versão: 2.0 - Com suporte à nova nomenclatura padronizada
"""

import mysql.connector
from mysql.connector import Error
from datetime import datetime
import sys
import os

# Configurações de conexão
CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '123456',
    'database': 'imp'
}

# =====================================================
# MAPEAMENTO DE NOMENCLATURA
# =====================================================

# Mapeamento: nome_antigo -> nome_novo
TABELAS_MAPEAMENTO = {
    'tb_aspecto': 'dim_aspecto',
    'tb_nota': 'dim_nota',
    'tb_fonte': 'dim_fonte',
    'tb_unidade': 'dim_unidade',
    'tb_localidade': 'dim_localidade',
    'tb_variavel': 'dim_variavel',
    'tb_base_cart': 'dim_base_cartografica',
    'tb_rel_ter': 'dim_territorio',
    'tb_dados': 'fact_indicador',
    'tb_dados_mensal': 'fact_indicador_mensal',
    'tb_rel_var_fnt': 'rel_variavel_fonte',
    'tb_rel_var_nota': 'rel_variavel_nota',
    'tb_rel_ter_var': 'rel_territorio_variavel',
    'tb_base_cart_ptos': 'rel_base_ponto',
    'tb_loc_pai': 'aux_localidade_hierarquia',
    'tb_localidade_historico': 'aux_localidade_historico',
    'tb_localidade_regiao_planejamento_saude': 'aux_localidade_regiao_saude',
    'tb_infmun': 'aux_info_municipio',
    'tb_consulta': 'cfg_consulta',
    'tb_var_calculado': 'cfg_variavel_calculada',
    'tb_var_produto': 'cfg_variavel_produto',
    'tb_log_busca': 'log_busca',
    'tb_erro_mvto': 'log_erro_movimento',
}

# Mapeamento de colunas: (tabela_nova, coluna_antiga) -> coluna_nova
COLUNAS_MAPEAMENTO = {
    # dim_aspecto
    ('dim_aspecto', 'cod_asp'): 'aspecto_id',
    ('dim_aspecto', 'nome_asp'): 'aspecto_nome',
    # dim_nota
    ('dim_nota', 'nota_cod'): 'nota_id',
    ('dim_nota', 'nota_nome'): 'nota_txt',
    # dim_fonte
    ('dim_fonte', 'fnt_cod'): 'fonte_id',
    ('dim_fonte', 'fnt_sigla'): 'fonte_sigla',
    ('dim_fonte', 'fnt_nome'): 'fonte_nome',
    # dim_unidade
    ('dim_unidade', 'unid_cod'): 'unidade_id',
    ('dim_unidade', 'unid_nome'): 'unidade_nome',
    # dim_localidade
    ('dim_localidade', 'loc_cod'): 'localidade_id',
    ('dim_localidade', 'loc_pai'): 'localidade_pai_id',
    ('dim_localidade', 'loc_nome'): 'localidade_nome',
    ('dim_localidade', 'loc_nivel'): 'localidade_nivel',
    ('dim_localidade', 'loc_cod_ibge'): 'localidade_cod_ibge',
    # dim_variavel
    ('dim_variavel', 'var_cod'): 'variavel_id',
    ('dim_variavel', 'unid_cod'): 'unidade_id',
    ('dim_variavel', 'var_nome'): 'variavel_nome',
    ('dim_variavel', 'var_asp'): 'aspecto_id',
    # dim_base_cartografica
    ('dim_base_cartografica', 'cod_base'): 'base_cartografica_id',
    ('dim_base_cartografica', 'nome_base'): 'base_cartografica_nome',
    # dim_territorio
    ('dim_territorio', 'ter_cod'): 'territorio_id',
    ('dim_territorio', 'ter_tipo'): 'territorio_tipo',
    # fact_indicador
    ('fact_indicador', 'loc_cod'): 'localidade_id',
    ('fact_indicador', 'var_cod'): 'variavel_id',
    # rel_base_ponto
    ('rel_base_ponto', 'Cod_loc'): 'localidade_id',
    ('rel_base_ponto', 'base'): 'base_cartografica_id',
    ('rel_base_ponto', 'PtoX'): 'ponto_x',
    ('rel_base_ponto', 'PtoY'): 'ponto_y',
    # rel_variavel_fonte
    ('rel_variavel_fonte', 'var_cod'): 'variavel_id',
    ('rel_variavel_fonte', 'fnt_cod'): 'fonte_id',
    # rel_variavel_nota
    ('rel_variavel_nota', 'var_cod'): 'variavel_id',
    ('rel_variavel_nota', 'nota_cod'): 'nota_id',
    # rel_territorio_variavel
    ('rel_territorio_variavel', 'ter_cod'): 'territorio_id',
    ('rel_territorio_variavel', 'var_cod'): 'variavel_id',
    # aux_localidade_hierarquia
    ('aux_localidade_hierarquia', 'loc_cod'): 'localidade_id',
    ('aux_localidade_hierarquia', 'loc_pai'): 'localidade_pai_id',
    # aux_localidade_historico
    ('aux_localidade_historico', 'loc_cod'): 'localidade_id',
    ('aux_localidade_historico', 'loc_historico'): 'historico_txt',
    # cfg_consulta
    ('cfg_consulta', 'con_cod'): 'consulta_id',
    ('cfg_consulta', 'con_nome'): 'consulta_nome',
    # log_busca
    ('log_busca', 'log_data'): 'busca_dh',
    ('log_busca', 'log_busca'): 'busca_termo',
}

# Definição de PKs por tabela (nomenclatura nova)
PKS_DEFINICAO = {
    'dim_aspecto': ['aspecto_id'],
    'dim_nota': ['nota_id'],
    'dim_fonte': ['fonte_id'],
    'dim_unidade': ['unidade_id'],
    'dim_localidade': ['localidade_id'],
    'dim_variavel': ['variavel_id'],
    'dim_base_cartografica': ['base_cartografica_id'],
    'dim_territorio': ['territorio_id'],
    'fact_indicador': ['localidade_id', 'variavel_id'],
    'rel_variavel_fonte': ['variavel_id', 'fonte_id'],
    'rel_variavel_nota': ['variavel_id', 'nota_id'],
    'rel_territorio_variavel': ['territorio_id', 'variavel_id'],
    'rel_base_ponto': ['localidade_id', 'base_cartografica_id', 'ponto_x', 'ponto_y'],
    'aux_localidade_hierarquia': ['localidade_id'],
    'aux_localidade_historico': ['localidade_id'],
    'cfg_consulta': ['consulta_id'],
}

# Definição de FKs (tabela_origem, coluna, tabela_destino, coluna_destino)
FKS_DEFINICAO = [
    ('dim_localidade', 'localidade_pai_id', 'dim_localidade', 'localidade_id'),
    ('dim_variavel', 'unidade_id', 'dim_unidade', 'unidade_id'),
    ('dim_variavel', 'aspecto_id', 'dim_aspecto', 'aspecto_id'),
    ('fact_indicador', 'localidade_id', 'dim_localidade', 'localidade_id'),
    ('fact_indicador', 'variavel_id', 'dim_variavel', 'variavel_id'),
    ('rel_variavel_fonte', 'variavel_id', 'dim_variavel', 'variavel_id'),
    ('rel_variavel_fonte', 'fonte_id', 'dim_fonte', 'fonte_id'),
    ('rel_variavel_nota', 'variavel_id', 'dim_variavel', 'variavel_id'),
    ('rel_variavel_nota', 'nota_id', 'dim_nota', 'nota_id'),
    ('rel_territorio_variavel', 'territorio_id', 'dim_territorio', 'territorio_id'),
    ('rel_territorio_variavel', 'variavel_id', 'dim_variavel', 'variavel_id'),
    ('rel_base_ponto', 'base_cartografica_id', 'dim_base_cartografica', 'base_cartografica_id'),
    ('aux_localidade_hierarquia', 'localidade_id', 'dim_localidade', 'localidade_id'),
    ('aux_localidade_historico', 'localidade_id', 'dim_localidade', 'localidade_id'),
]


def conectar():
    """Estabelece conexão com o banco de dados"""
    try:
        conexao = mysql.connector.connect(**CONFIG)
        if conexao.is_connected():
            return conexao
    except Error as e:
        print(f"❌ Erro ao conectar: {e}")
        return None


def executar_query(conexao, query, fetch=True):
    """Executa uma query e retorna os resultados"""
    try:
        cursor = conexao.cursor()
        cursor.execute(query)
        if fetch:
            resultado = cursor.fetchall()
            colunas = [desc[0] for desc in cursor.description] if cursor.description else []
            cursor.close()
            return resultado, colunas
        else:
            conexao.commit()
            cursor.close()
            return True, None
    except Error as e:
        return None, str(e)


def detectar_nomenclatura(conexao):
    """Detecta qual nomenclatura está sendo usada no banco"""
    query = """
    SELECT TABLE_NAME 
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = 'imp'
    """
    resultado, _ = executar_query(conexao, query)
    
    if not resultado:
        return 'desconhecida'
    
    tabelas = [r[0] for r in resultado]
    
    # Verificar se usa nomenclatura antiga (tb_*)
    tabelas_antigas = [t for t in tabelas if t.startswith('tb_')]
    
    # Verificar se usa nomenclatura nova (dim_*, fact_*, rel_*, etc.)
    tabelas_novas = [t for t in tabelas if t.startswith(('dim_', 'fact_', 'rel_', 'aux_', 'cfg_', 'log_'))]
    
    if len(tabelas_antigas) > len(tabelas_novas):
        return 'antiga'
    elif len(tabelas_novas) > len(tabelas_antigas):
        return 'nova'
    else:
        return 'mista'


def verificar_pks_existentes(conexao):
    """Verifica PKs já existentes no banco"""
    query = """
    SELECT 
        TABLE_NAME,
        GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION) as PK_COLUMNS
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = 'imp'
      AND CONSTRAINT_NAME = 'PRIMARY'
    GROUP BY TABLE_NAME
    ORDER BY TABLE_NAME
    """
    resultado, _ = executar_query(conexao, query)
    return resultado if resultado else []


def verificar_fks_existentes(conexao):
    """Verifica FKs já existentes no banco"""
    query = """
    SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        CONSTRAINT_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = 'imp'
      AND REFERENCED_TABLE_NAME IS NOT NULL
    ORDER BY TABLE_NAME
    """
    resultado, _ = executar_query(conexao, query)
    return resultado if resultado else []


def verificar_indices_existentes(conexao):
    """Verifica índices já existentes no banco"""
    query = """
    SELECT 
        TABLE_NAME,
        INDEX_NAME,
        GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) as INDEX_COLUMNS,
        NON_UNIQUE
    FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = 'imp'
      AND INDEX_NAME != 'PRIMARY'
    GROUP BY TABLE_NAME, INDEX_NAME, NON_UNIQUE
    ORDER BY TABLE_NAME, INDEX_NAME
    """
    resultado, _ = executar_query(conexao, query)
    return resultado if resultado else []


def verificar_valores_nulos(conexao):
    """Verifica colunas que serão PK e têm valores NULL"""
    nomenclatura = detectar_nomenclatura(conexao)
    problemas = []
    
    # Definir verificações baseado na nomenclatura
    if nomenclatura == 'nova':
        tabelas_pk = {
            'dim_nota': 'nota_id',
            'dim_aspecto': 'aspecto_id',
            'dim_base_cartografica': 'base_cartografica_id',
            'cfg_consulta': 'consulta_id',
            'dim_fonte': 'fonte_id',
            'aux_localidade_hierarquia': 'localidade_id',
            'aux_localidade_historico': 'localidade_id',
            'dim_territorio': 'territorio_id',
            'dim_unidade': 'unidade_id',
            'dim_localidade': 'localidade_id',
            'dim_variavel': 'variavel_id',
        }
    else:
        tabelas_pk = {
            'tb_nota': 'nota_cod',
            'tb_aspecto': 'cod_asp',
            'tb_base_cart': 'cod_base',
            'tb_consulta': 'con_cod',
            'tb_fonte': 'fnt_cod',
            'tb_loc_pai': 'loc_cod',
            'tb_localidade_historico': 'loc_cod',
            'tb_rel_ter': 'ter_cod',
            'tb_unidade': 'unid_cod',
            'tb_localidade': 'loc_cod',
            'tb_variavel': 'var_cod',
        }
    
    for tabela, coluna in tabelas_pk.items():
        query = f"SELECT COUNT(*) FROM `{tabela}` WHERE `{coluna}` IS NULL"
        resultado, erro = executar_query(conexao, query)
        if resultado and resultado[0][0] > 0:
            problemas.append({
                'tabela': tabela,
                'coluna': coluna,
                'nulos': resultado[0][0]
            })
    
    return problemas


def verificar_duplicatas(conexao):
    """Verifica duplicatas em colunas que serão PK"""
    nomenclatura = detectar_nomenclatura(conexao)
    problemas = []
    
    if nomenclatura == 'nova':
        verificacoes = [
            ('dim_nota', 'nota_id'),
            ('dim_aspecto', 'aspecto_id'),
            ('dim_base_cartografica', 'base_cartografica_id'),
            ('cfg_consulta', 'consulta_id'),
            ('dim_fonte', 'fonte_id'),
            ('aux_localidade_hierarquia', 'localidade_id'),
            ('aux_localidade_historico', 'localidade_id'),
            ('dim_territorio', 'territorio_id'),
            ('dim_unidade', 'unidade_id'),
            ('dim_localidade', 'localidade_id'),
            ('dim_variavel', 'variavel_id'),
            ('fact_indicador', 'localidade_id, variavel_id'),
            ('rel_territorio_variavel', 'territorio_id, variavel_id'),
            ('rel_variavel_fonte', 'variavel_id, fonte_id'),
            ('rel_variavel_nota', 'variavel_id, nota_id'),
        ]
    else:
        verificacoes = [
            ('tb_nota', 'nota_cod'),
            ('tb_aspecto', 'cod_asp'),
            ('tb_base_cart', 'cod_base'),
            ('tb_consulta', 'con_cod'),
            ('tb_fonte', 'fnt_cod'),
            ('tb_loc_pai', 'loc_cod'),
            ('tb_localidade_historico', 'loc_cod'),
            ('tb_rel_ter', 'ter_cod'),
            ('tb_unidade', 'unid_cod'),
            ('tb_localidade', 'loc_cod'),
            ('tb_variavel', 'var_cod'),
            ('tb_dados', 'loc_cod, var_cod'),
            ('tb_rel_ter_var', 'ter_cod, var_cod'),
            ('tb_rel_var_fnt', 'var_cod, fnt_cod'),
            ('tb_rel_var_nota', 'var_cod, nota_cod'),
        ]
    
    for tabela, colunas in verificacoes:
        query = f"""
        SELECT {colunas}, COUNT(*) as qtd 
        FROM `{tabela}` 
        GROUP BY {colunas} 
        HAVING COUNT(*) > 1
        LIMIT 5
        """
        resultado, erro = executar_query(conexao, query)
        if resultado and len(resultado) > 0:
            problemas.append({
                'tabela': tabela,
                'colunas': colunas,
                'duplicatas': len(resultado),
                'exemplos': resultado[:3]
            })
    
    return problemas


def verificar_integridade_referencial(conexao):
    """Verifica se os valores de FK existem nas tabelas referenciadas"""
    nomenclatura = detectar_nomenclatura(conexao)
    problemas = []
    
    if nomenclatura == 'nova':
        verificacoes = [
            ('fact_indicador', 'localidade_id', 'dim_localidade', 'localidade_id'),
            ('fact_indicador', 'variavel_id', 'dim_variavel', 'variavel_id'),
            ('dim_variavel', 'unidade_id', 'dim_unidade', 'unidade_id'),
            ('dim_variavel', 'aspecto_id', 'dim_aspecto', 'aspecto_id'),
            ('rel_variavel_fonte', 'variavel_id', 'dim_variavel', 'variavel_id'),
            ('rel_variavel_fonte', 'fonte_id', 'dim_fonte', 'fonte_id'),
            ('rel_variavel_nota', 'variavel_id', 'dim_variavel', 'variavel_id'),
            ('rel_variavel_nota', 'nota_id', 'dim_nota', 'nota_id'),
            ('aux_localidade_hierarquia', 'localidade_id', 'dim_localidade', 'localidade_id'),
            ('aux_localidade_historico', 'localidade_id', 'dim_localidade', 'localidade_id'),
            ('rel_base_ponto', 'base_cartografica_id', 'dim_base_cartografica', 'base_cartografica_id'),
        ]
    else:
        verificacoes = [
            ('tb_dados', 'loc_cod', 'tb_localidade', 'loc_cod'),
            ('tb_dados', 'var_cod', 'tb_variavel', 'var_cod'),
            ('tb_variavel', 'unid_cod', 'tb_unidade', 'unid_cod'),
            ('tb_variavel', 'var_asp', 'tb_aspecto', 'cod_asp'),
            ('tb_rel_var_fnt', 'var_cod', 'tb_variavel', 'var_cod'),
            ('tb_rel_var_fnt', 'fnt_cod', 'tb_fonte', 'fnt_cod'),
            ('tb_rel_var_nota', 'var_cod', 'tb_variavel', 'var_cod'),
            ('tb_rel_var_nota', 'nota_cod', 'tb_nota', 'nota_cod'),
            ('tb_loc_pai', 'loc_cod', 'tb_localidade', 'loc_cod'),
            ('tb_localidade_historico', 'loc_cod', 'tb_localidade', 'loc_cod'),
            ('tb_base_cart_ptos', 'base', 'tb_base_cart', 'cod_base'),
        ]
    
    for tabela_fk, coluna_fk, tabela_pk, coluna_pk in verificacoes:
        query = f"""
        SELECT COUNT(*) 
        FROM `{tabela_fk}` f 
        LEFT JOIN `{tabela_pk}` p ON f.`{coluna_fk}` = p.`{coluna_pk}`
        WHERE f.`{coluna_fk}` IS NOT NULL AND p.`{coluna_pk}` IS NULL
        """
        resultado, erro = executar_query(conexao, query)
        
        if erro and 'doesn\'t exist' in str(erro):
            continue
            
        if resultado and resultado[0][0] > 0:
            query_exemplos = f"""
            SELECT DISTINCT f.`{coluna_fk}`
            FROM `{tabela_fk}` f 
            LEFT JOIN `{tabela_pk}` p ON f.`{coluna_fk}` = p.`{coluna_pk}`
            WHERE f.`{coluna_fk}` IS NOT NULL AND p.`{coluna_pk}` IS NULL
            LIMIT 5
            """
            exemplos, _ = executar_query(conexao, query_exemplos)
            
            problemas.append({
                'tabela_fk': tabela_fk,
                'coluna_fk': coluna_fk,
                'tabela_pk': tabela_pk,
                'coluna_pk': coluna_pk,
                'orfaos': resultado[0][0],
                'exemplos': [e[0] for e in exemplos] if exemplos else []
            })
    
    return problemas


def verificar_nomenclatura(conexao):
    """Verifica o estado da nomenclatura no banco"""
    nomenclatura = detectar_nomenclatura(conexao)
    
    print(f"\n📋 VERIFICAÇÃO DE NOMENCLATURA")
    print("-" * 50)
    print(f"   Nomenclatura detectada: {nomenclatura.upper()}")
    
    query = """
    SELECT TABLE_NAME, TABLE_ROWS
    FROM information_schema.TABLES 
    WHERE TABLE_SCHEMA = 'imp'
    ORDER BY TABLE_NAME
    """
    resultado, _ = executar_query(conexao, query)
    
    if resultado:
        grupos = {
            'Antigas (tb_)': [],
            'Dimensão (dim_)': [],
            'Fato (fact_)': [],
            'Relacionamento (rel_)': [],
            'Auxiliar (aux_)': [],
            'Configuração (cfg_)': [],
            'Log (log_)': [],
            'Outras': []
        }
        
        for tabela, registros in resultado:
            if tabela.startswith('tb_'):
                grupos['Antigas (tb_)'].append((tabela, registros))
            elif tabela.startswith('dim_'):
                grupos['Dimensão (dim_)'].append((tabela, registros))
            elif tabela.startswith('fact_'):
                grupos['Fato (fact_)'].append((tabela, registros))
            elif tabela.startswith('rel_'):
                grupos['Relacionamento (rel_)'].append((tabela, registros))
            elif tabela.startswith('aux_'):
                grupos['Auxiliar (aux_)'].append((tabela, registros))
            elif tabela.startswith('cfg_'):
                grupos['Configuração (cfg_)'].append((tabela, registros))
            elif tabela.startswith('log_'):
                grupos['Log (log_)'].append((tabela, registros))
            else:
                grupos['Outras'].append((tabela, registros))
        
        for grupo, tabelas in grupos.items():
            if tabelas:
                print(f"\n   {grupo}:")
                for tabela, registros in tabelas:
                    print(f"      • {tabela} ({registros or 0} registros)")
    
    if nomenclatura == 'antiga':
        print(f"\n   ⚠️ Recomendação: Execute o script 'script_padronizacao_nomenclatura.sql'")
    elif nomenclatura == 'mista':
        print(f"\n   ⚠️ ATENÇÃO: Nomenclatura mista detectada. Verifique a migração.")
    else:
        print(f"\n   ✓ Nomenclatura padronizada está em uso.")
    
    return nomenclatura


def gerar_relatorio_validacao(conexao):
    """Gera relatório completo de validação"""
    
    print("=" * 70)
    print("RELATÓRIO DE VALIDAÇÃO PARA REFATORAÇÃO DO DATA WAREHOUSE")
    print(f"Data: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    print("=" * 70)
    
    nomenclatura = verificar_nomenclatura(conexao)
    
    print("\n📋 1. CHAVES PRIMÁRIAS EXISTENTES")
    print("-" * 50)
    pks = verificar_pks_existentes(conexao)
    if pks:
        for pk in pks:
            print(f"   ✓ {pk[0]}: ({pk[1]})")
    else:
        print("   ⚠️ Nenhuma PK encontrada")
    
    print("\n📋 2. CHAVES ESTRANGEIRAS EXISTENTES")
    print("-" * 50)
    fks = verificar_fks_existentes(conexao)
    if fks:
        for fk in fks:
            print(f"   ✓ {fk[0]}.{fk[1]} → {fk[3]}.{fk[4]}")
    else:
        print("   ⚠️ Nenhuma FK encontrada")
    
    print("\n📋 3. VALORES NULOS EM COLUNAS DE PK")
    print("-" * 50)
    nulos = verificar_valores_nulos(conexao)
    if nulos:
        for prob in nulos:
            print(f"   ❌ {prob['tabela']}.{prob['coluna']}: {prob['nulos']} valores NULL")
    else:
        print("   ✓ Nenhum valor NULL encontrado")
    
    print("\n📋 4. DUPLICATAS EM COLUNAS DE PK")
    print("-" * 50)
    duplicatas = verificar_duplicatas(conexao)
    if duplicatas:
        for prob in duplicatas:
            print(f"   ❌ {prob['tabela']} ({prob['colunas']}): {prob['duplicatas']} grupos duplicados")
            for ex in prob['exemplos'][:2]:
                print(f"      Exemplo: {ex}")
    else:
        print("   ✓ Nenhuma duplicata encontrada")
    
    print("\n📋 5. INTEGRIDADE REFERENCIAL (Registros Órfãos)")
    print("-" * 50)
    orfaos = verificar_integridade_referencial(conexao)
    if orfaos:
        for prob in orfaos:
            print(f"   ❌ {prob['tabela_fk']}.{prob['coluna_fk']} → {prob['tabela_pk']}.{prob['coluna_pk']}")
            print(f"      {prob['orfaos']} registros sem correspondência")
            if prob['exemplos']:
                print(f"      Exemplos: {prob['exemplos'][:3]}")
    else:
        print("   ✓ Todos os relacionamentos têm integridade")
    
    print("\n📋 6. ÍNDICES EXISTENTES")
    print("-" * 50)
    indices = verificar_indices_existentes(conexao)
    if indices:
        for idx in indices[:20]:
            tipo = "UNIQUE" if idx[3] == 0 else "INDEX"
            print(f"   ✓ {idx[0]}.{idx[1]} ({idx[2]}) [{tipo}]")
        if len(indices) > 20:
            print(f"   ... e mais {len(indices) - 20} índices")
    else:
        print("   ⚠️ Nenhum índice adicional encontrado")
    
    print("\n" + "=" * 70)
    print("RESUMO")
    print("=" * 70)
    
    total_problemas = len(nulos) + len(duplicatas) + len(orfaos)
    
    if nomenclatura == 'antiga':
        print("\n📌 ETAPA 1: Padronização de Nomenclatura")
        print("   Execute: script_padronizacao_nomenclatura.sql")
    
    if total_problemas == 0:
        if nomenclatura == 'nova':
            print("\n✅ BANCO PRONTO PARA CRIAÇÃO DE PKs E FKs!")
        else:
            print("\n✅ Sem problemas de dados. Padronize a nomenclatura primeiro.")
    else:
        print(f"\n⚠️ ATENÇÃO: {total_problemas} problema(s) encontrado(s)")
        print("   Corrija os problemas antes de executar a refatoração.")
        
        if nulos:
            print(f"\n   Para corrigir NULLs, execute:")
            for prob in nulos:
                print(f"   UPDATE `{prob['tabela']}` SET `{prob['coluna']}` = 0 WHERE `{prob['coluna']}` IS NULL;")
        
        if duplicatas:
            print(f"\n   Para verificar duplicatas manualmente:")
            for prob in duplicatas:
                print(f"   SELECT {prob['colunas']}, COUNT(*) FROM `{prob['tabela']}` GROUP BY {prob['colunas']} HAVING COUNT(*) > 1;")
    
    return total_problemas


def executar_script_sql(conexao, arquivo_sql):
    """Executa o script SQL"""
    try:
        with open(arquivo_sql, 'r', encoding='utf-8') as f:
            script = f.read()
        
        comandos = []
        comando_atual = ""
        
        for linha in script.split('\n'):
            linha_limpa = linha.strip()
            if linha_limpa.startswith('--'):
                continue
            comando_atual += linha + "\n"
            if linha_limpa.endswith(';'):
                comando_atual = comando_atual.strip()
                if comando_atual and not comando_atual.startswith('/*'):
                    comandos.append(comando_atual)
                comando_atual = ""
        
        total = len(comandos)
        executados = 0
        erros = 0
        
        cursor = conexao.cursor()
        
        for comando in comandos:
            comando = comando.strip()
            if not comando:
                continue
            
            while '/*' in comando and '*/' in comando:
                inicio = comando.find('/*')
                fim = comando.find('*/') + 2
                comando = comando[:inicio] + comando[fim:]
            
            comando = comando.strip()
            if not comando or comando == ';':
                continue
            
            try:
                cursor.execute(comando)
                conexao.commit()
                executados += 1
                if executados % 10 == 0:
                    print(f"   ✓ Progresso: {executados}/{total}")
            except Error as e:
                erros += 1
                erro_msg = str(e)
                if 'Duplicate' not in erro_msg and 'already exists' not in erro_msg:
                    print(f"   ❌ Erro: {erro_msg[:80]}")
        
        cursor.close()
        print(f"\n   ✅ Resumo: {executados} executados, {erros} com erro/avisos")
        return executados, erros
        
    except FileNotFoundError:
        print(f"❌ Arquivo não encontrado: {arquivo_sql}")
        return 0, 1
    except Exception as e:
        print(f"❌ Erro: {e}")
        return 0, 1


def main():
    """Função principal"""
    print("\n" + "=" * 70)
    print("VALIDAÇÃO E EXECUÇÃO DA REFATORAÇÃO PARA DATA WAREHOUSE")
    print("Versão 2.0 - Com suporte à nomenclatura padronizada")
    print("=" * 70)
    
    conexao = conectar()
    if not conexao:
        print("❌ Não foi possível conectar ao banco de dados.")
        sys.exit(1)
    
    print(f"✅ Conectado ao banco de dados 'imp'")
    
    while True:
        print("\n" + "-" * 50)
        print("MENU PRINCIPAL")
        print("-" * 50)
        print("1. Validar banco (verificar pré-requisitos)")
        print("2. Aplicar padronização de nomenclatura")
        print("3. Criar PKs e FKs (após padronização)")
        print("4. Verificar resultado final")
        print("5. Sair")
        
        opcao = input("\nEscolha uma opção (1-5): ").strip()
        
        if opcao == '1':
            gerar_relatorio_validacao(conexao)
            
        elif opcao == '2':
            print("\n⚠️ ATENÇÃO: Esta operação irá renomear tabelas e colunas!")
            print("Certifique-se de ter um backup antes de continuar.")
            confirma = input("\nDeseja continuar? (s/n): ").strip().lower()
            
            if confirma == 's':
                if os.path.exists('script_padronizacao_nomenclatura.sql'):
                    print("\nExecutando padronização de nomenclatura...")
                    executar_script_sql(conexao, 'script_padronizacao_nomenclatura.sql')
                else:
                    print("❌ Arquivo 'script_padronizacao_nomenclatura.sql' não encontrado.")
            else:
                print("Operação cancelada.")
                
        elif opcao == '3':
            nomenclatura = detectar_nomenclatura(conexao)
            
            if nomenclatura == 'antiga':
                print("\n⚠️ A nomenclatura ainda está no padrão antigo.")
                print("Execute a opção 2 primeiro para padronizar.")
            else:
                print("\n⚠️ ATENÇÃO: Esta operação irá criar PKs e FKs!")
                confirma = input("\nDeseja continuar? (s/n): ").strip().lower()
                
                if confirma == 's':
                    if os.path.exists('criar_chaves_primarias_estrangeiras_v2.sql'):
                        print("\nCriando PKs e FKs...")
                        executar_script_sql(conexao, 'criar_chaves_primarias_estrangeiras_v2.sql')
                    else:
                        print("❌ Arquivo de PKs/FKs não encontrado.")
                else:
                    print("Operação cancelada.")
                    
        elif opcao == '4':
            print("\n📋 VERIFICAÇÃO PÓS-REFATORAÇÃO")
            print("-" * 50)
            
            nomenclatura = detectar_nomenclatura(conexao)
            print(f"\n   Nomenclatura: {nomenclatura.upper()}")
            
            pks = verificar_pks_existentes(conexao)
            fks = verificar_fks_existentes(conexao)
            indices = verificar_indices_existentes(conexao)
            
            print(f"   PKs criadas: {len(pks)}")
            print(f"   FKs criadas: {len(fks)}")
            print(f"   Índices criados: {len(indices)}")
            
            query = "SELECT COUNT(*) FROM dim_tempo"
            resultado, erro = executar_query(conexao, query)
            if resultado:
                print(f"   dim_tempo: {resultado[0][0]} registros")
            elif erro and 'doesn\'t exist' in str(erro):
                print(f"   dim_tempo: não existe ainda")
                
        elif opcao == '5':
            print("Saindo...")
            break
        else:
            print("Opção inválida.")
    
    conexao.close()
    print("\n✅ Conexão encerrada.")


if __name__ == "__main__":
    main()
