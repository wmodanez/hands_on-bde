"""
Script de Análise de Dados para Migração
Banco de dados: imp
Data: 24/02/2026

Objetivo: Analisar os tipos de dados reais nas tabelas antes da migração,
especialmente nas colunas d_1980 a d_2030 da tb_dados.
"""

import mysql.connector
from mysql.connector import Error
from datetime import datetime
import re
from collections import defaultdict

# Configurações
CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '123456',
    'database': 'imp'
}


def conectar():
    """Estabelece conexão com o banco de dados"""
    try:
        conexao = mysql.connector.connect(**CONFIG)
        if conexao.is_connected():
            return conexao
    except Error as e:
        print(f"❌ Erro ao conectar: {e}")
        return None


def classificar_valor(valor):
    """Classifica o tipo de dado de um valor"""
    if valor is None or valor == '':
        return 'VAZIO'
    
    valor_str = str(valor).strip()
    
    # Verificar se é inteiro
    if re.match(r'^-?\d+$', valor_str):
        return 'INTEIRO'
    
    # Verificar se é decimal com ponto
    if re.match(r'^-?\d+\.\d+$', valor_str):
        return 'DECIMAL_PONTO'
    
    # Verificar se é decimal com vírgula
    if re.match(r'^-?\d+,\d+$', valor_str):
        return 'DECIMAL_VIRGULA'
    
    # Verificar se é número com separador de milhares
    if re.match(r'^-?\d{1,3}(\.\d{3})+$', valor_str):
        return 'INTEIRO_PONTO_MILHARES'
    
    if re.match(r'^-?\d{1,3}(,\d{3})+$', valor_str):
        return 'INTEIRO_VIRGULA_MILHARES'
    
    # Verificar se é decimal com separadores mistos
    if re.match(r'^-?\d{1,3}(\.\d{3})+,\d+$', valor_str):
        return 'DECIMAL_PONTO_MILHARES_VIRGULA_DECIMAL'
    
    if re.match(r'^-?\d{1,3}(,\d{3})+\.\d+$', valor_str):
        return 'DECIMAL_VIRGULA_MILHARES_PONTO_DECIMAL'
    
    # Verificar se contém letras ou caracteres especiais
    if re.search(r'[a-zA-Z]', valor_str):
        return 'TEXTO_COM_LETRAS'
    
    # Verificar notação científica
    if re.match(r'^-?\d+\.?\d*[eE][+-]?\d+$', valor_str):
        return 'NOTACAO_CIENTIFICA'
    
    # Outros caracteres especiais
    if re.search(r'[^\d\.,\-\s]', valor_str):
        return 'TEXTO_ESPECIAL'
    
    return 'OUTRO'


def analisar_coluna_dados(conexao, coluna):
    """Analisa uma coluna específica da tabela tb_dados"""
    query = f"""
    SELECT `{coluna}`, COUNT(*) as qtd
    FROM tb_dados
    WHERE `{coluna}` IS NOT NULL AND `{coluna}` != ''
    GROUP BY `{coluna}`
    ORDER BY qtd DESC
    LIMIT 1000
    """
    
    cursor = conexao.cursor()
    cursor.execute(query)
    resultados = cursor.fetchall()
    cursor.close()
    
    # Classificar valores
    classificacao = defaultdict(lambda: {'count': 0, 'exemplos': []})
    
    for valor, qtd in resultados:
        tipo = classificar_valor(valor)
        classificacao[tipo]['count'] += qtd
        if len(classificacao[tipo]['exemplos']) < 5:
            classificacao[tipo]['exemplos'].append(str(valor))
    
    return classificacao


def analisar_tb_dados_completa(conexao):
    """Analisa todas as colunas d_YYYY da tb_dados"""
    print("=" * 80)
    print("ANÁLISE DETALHADA DA TABELA tb_dados")
    print("=" * 80)
    
    # Obter total de registros
    cursor = conexao.cursor()
    cursor.execute("SELECT COUNT(*) FROM tb_dados")
    total_registros = cursor.fetchone()[0]
    print(f"\n📊 Total de registros na tb_dados: {total_registros:,}")
    
    # Analisar cada ano
    anos = range(1980, 2031)
    resultados_gerais = defaultdict(lambda: {'total': 0, 'anos': []})
    
    print("\n🔍 Analisando colunas de dados por ano...\n")
    
    for ano in anos:
        coluna = f'd_{ano}'
        
        # Contar valores não vazios
        cursor.execute(f"""
            SELECT COUNT(*) 
            FROM tb_dados 
            WHERE `{coluna}` IS NOT NULL AND `{coluna}` != ''
        """)
        valores_preenchidos = cursor.fetchone()[0]
        
        if valores_preenchidos > 0:
            print(f"   Analisando {coluna}... ({valores_preenchidos:,} valores)")
            classificacao = analisar_coluna_dados(conexao, coluna)
            
            # Agregar resultados
            for tipo, dados in classificacao.items():
                resultados_gerais[tipo]['total'] += dados['count']
                resultados_gerais[tipo]['anos'].append(ano)
                if 'exemplos' not in resultados_gerais[tipo]:
                    resultados_gerais[tipo]['exemplos'] = dados['exemplos']
    
    cursor.close()
    
    # Exibir resultados consolidados
    print("\n" + "=" * 80)
    print("RESUMO DE TIPOS DE DADOS ENCONTRADOS")
    print("=" * 80)
    
    total_valores = sum(r['total'] for r in resultados_gerais.values())
    
    # Ordenar por quantidade
    tipos_ordenados = sorted(
        resultados_gerais.items(), 
        key=lambda x: x[1]['total'], 
        reverse=True
    )
    
    for tipo, dados in tipos_ordenados:
        percentual = (dados['total'] / total_valores * 100) if total_valores > 0 else 0
        print(f"\n📌 {tipo}")
        print(f"   Quantidade: {dados['total']:,} ({percentual:.2f}%)")
        print(f"   Anos afetados: {len(dados['anos'])} anos")
        print(f"   Exemplos: {', '.join(dados['exemplos'][:5])}")
    
    print("\n" + "=" * 80)
    
    return resultados_gerais


def analisar_valores_extremos(conexao):
    """Analisa valores extremos nas colunas de dados"""
    print("\n" + "=" * 80)
    print("ANÁLISE DE VALORES EXTREMOS")
    print("=" * 80)
    
    cursor = conexao.cursor()
    
    for ano in [1980, 1990, 2000, 2010, 2020, 2030]:
        coluna = f'd_{ano}'
        
        # Maior valor (como string)
        cursor.execute(f"""
            SELECT `{coluna}`, LENGTH(`{coluna}`)
            FROM tb_dados
            WHERE `{coluna}` IS NOT NULL AND `{coluna}` != ''
            ORDER BY LENGTH(`{coluna}`) DESC
            LIMIT 5
        """)
        maiores = cursor.fetchall()
        
        if maiores:
            print(f"\n📊 Coluna {coluna}:")
            print(f"   Valores mais longos (maior string):")
            for valor, tamanho in maiores:
                print(f"      - '{valor}' (tamanho: {tamanho})")
    
    cursor.close()


def analisar_caracteres_especiais(conexao):
    """Identifica caracteres especiais nas colunas de dados"""
    print("\n" + "=" * 80)
    print("ANÁLISE DE CARACTERES ESPECIAIS")
    print("=" * 80)
    
    cursor = conexao.cursor()
    
    # Procurar por diferentes padrões (SIMPLIFICADO - apenas anos chave)
    padroes = {
        'Com vírgula': '%,%',
        'Com ponto': '%.%',
        'Com espaço': '% %',
        'Com hífen/menos': '%-%',
        'Com letras': '%x%',  # Simplificado
        'Com colchetes': '%[%',
    }
    
    for ano in [2000, 2010, 2020]:  # Apenas 3 anos para acelerar
        coluna = f'd_{ano}'
        encontrou_algo = False
        
        for descricao, padrao in padroes.items():
            try:
                cursor.execute(f"""
                    SELECT COUNT(*) 
                    FROM tb_dados 
                    WHERE `{coluna}` LIKE %s
                """, (padrao,))
                qtd = cursor.fetchone()[0]
                
                if qtd > 0:
                    if not encontrou_algo:
                        print(f"\n📊 Coluna {coluna}:")
                        encontrou_algo = True
                    
                    # Buscar exemplos
                    cursor.execute(f"""
                        SELECT DISTINCT `{coluna}` 
                        FROM tb_dados 
                        WHERE `{coluna}` LIKE %s
                        LIMIT 3
                    """, (padrao,))
                    exemplos = [r[0] for r in cursor.fetchall()]
                    print(f"   {descricao}: {qtd:,} registros - Ex: {', '.join(exemplos)}")
            except Exception as e:
                print(f"   Erro ao analisar {descricao}: {e}")
    
    cursor.close()


def gerar_recomendacoes(resultados_gerais):
    """Gera recomendações baseadas na análise"""
    print("\n" + "=" * 80)
    print("RECOMENDAÇÕES PARA MIGRAÇÃO")
    print("=" * 80)
    
    print("\n📋 1. TIPO DE DADOS PARA AS COLUNAS")
    print("-" * 50)
    
    # Verificar se há apenas números
    tipos_numericos = {
        'INTEIRO', 'DECIMAL_PONTO', 'DECIMAL_VIRGULA',
        'INTEIRO_PONTO_MILHARES', 'INTEIRO_VIRGULA_MILHARES',
        'DECIMAL_PONTO_MILHARES_VIRGULA_DECIMAL',
        'DECIMAL_VIRGULA_MILHARES_PONTO_DECIMAL',
        'NOTACAO_CIENTIFICA'
    }
    
    tipos_encontrados = set(resultados_gerais.keys())
    tem_texto = bool(tipos_encontrados - tipos_numericos - {'VAZIO'})
    
    if tem_texto:
        print("   ⚠️ ATENÇÃO: Foram encontrados valores NÃO NUMÉRICOS!")
        print("   Recomendação: Usar VARCHAR(100) para preservar todos os dados")
        print("   Adicionar uma coluna DECIMAL separada para valores numéricos convertidos")
    else:
        print("   ✓ Todos os valores são numéricos ou vazios")
        print("   Recomendação: Usar DECIMAL(20,6) para valores numéricos")
    
    print("\n📋 2. PROCESSO DE NORMALIZAÇÃO")
    print("-" * 50)
    
    if 'DECIMAL_VIRGULA' in resultados_gerais:
        print("   • Converter vírgulas para pontos: '1234,56' → 1234.56")
    
    if 'INTEIRO_PONTO_MILHARES' in resultados_gerais:
        print("   • Remover pontos de milhares: '1.234' → 1234")
    
    if 'INTEIRO_VIRGULA_MILHARES' in resultados_gerais:
        print("   • Remover vírgulas de milhares: '1,234' → 1234")
    
    if 'DECIMAL_PONTO_MILHARES_VIRGULA_DECIMAL' in resultados_gerais:
        print("   • Formato BR: '1.234,56' → 1234.56 (remover ponto, vírgula→ponto)")
    
    if 'DECIMAL_VIRGULA_MILHARES_PONTO_DECIMAL' in resultados_gerais:
        print("   • Formato US: '1,234.56' → 1234.56 (remover vírgula)")
    
    print("\n📋 3. ESTRUTURA PROPOSTA PARA TABELA FATO")
    print("-" * 50)
    print("""
   CREATE TABLE fact_indicador (
       indicador_id BIGINT AUTO_INCREMENT PRIMARY KEY,
       localidade_id SMALLINT UNSIGNED NOT NULL,
       variavel_id SMALLINT UNSIGNED NOT NULL,
       tempo_id INT NOT NULL,
       indicador_txt VARCHAR(100) NULL,        -- Valor original (preservado)
       indicador_vlr DECIMAL(20,6) NULL,       -- Valor convertido para número
       indicador_tipo ENUM('numero', 'texto', 'vazio') NOT NULL,
       conversao_status ENUM('ok', 'erro', 'nao_aplicavel') DEFAULT 'ok',
       carga_dh TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       UNIQUE KEY uk_indicador (localidade_id, variavel_id, tempo_id)
   );
    """)
    
    print("\n📋 4. SCRIPT DE CONVERSÃO")
    print("-" * 50)
    print("   Será necessário criar uma função de conversão que:")
    print("   • Trate diferentes formatos de números")
    print("   • Preserve o valor original em indicador_txt")
    print("   • Registre erros de conversão")
    print("   • Classifique o tipo de dado")


def analisar_amostra_por_variavel(conexao):
    """Analisa algumas variáveis específicas para entender melhor os dados"""
    print("\n" + "=" * 80)
    print("ANÁLISE POR VARIÁVEL (AMOSTRA)")
    print("=" * 80)
    
    cursor = conexao.cursor()
    
    # Pegar 5 variáveis com mais dados
    cursor.execute("""
        SELECT var_cod, COUNT(*) as qtd
        FROM tb_dados
        WHERE d_2020 IS NOT NULL AND d_2020 != ''
        GROUP BY var_cod
        ORDER BY qtd DESC
        LIMIT 5
    """)
    
    variaveis = cursor.fetchall()
    
    for var_cod, qtd in variaveis:
        # Buscar nome da variável
        cursor.execute(f"SELECT var_nome FROM tb_variavel WHERE var_cod = {var_cod}")
        resultado = cursor.fetchone()
        var_nome = resultado[0] if resultado else 'Desconhecida'
        
        print(f"\n📊 Variável {var_cod}: {var_nome[:50]}")
        print(f"   Registros: {qtd:,}")
        
        # Buscar alguns valores de 2020
        cursor.execute(f"""
            SELECT DISTINCT d_2020
            FROM tb_dados
            WHERE var_cod = {var_cod} AND d_2020 IS NOT NULL AND d_2020 != ''
            LIMIT 10
        """)
        valores = [r[0] for r in cursor.fetchall()]
        
        # Classificar valores
        tipos_var = defaultdict(list)
        for valor in valores:
            tipo = classificar_valor(valor)
            tipos_var[tipo].append(str(valor))
        
        for tipo, exemplos in tipos_var.items():
            print(f"   • {tipo}: {', '.join(exemplos[:3])}")
    
    cursor.close()


def exportar_problemas_para_arquivo(conexao):
    """Exporta registros problemáticos para análise"""
    print("\n" + "=" * 80)
    print("EXPORTANDO REGISTROS PROBLEMÁTICOS")
    print("=" * 80)
    
    cursor = conexao.cursor()
    
    with open('dados_problematicos.txt', 'w', encoding='utf-8') as f:
        f.write("REGISTROS COM DADOS POTENCIALMENTE PROBLEMÁTICOS\n")
        f.write("=" * 80 + "\n\n")
        
        # Procurar valores com letras (apenas anos chave)
        for ano in [2000, 2010, 2020]:
            coluna = f'd_{ano}'
            
            try:
                cursor.execute(f"""
                    SELECT loc_cod, var_cod, `{coluna}`
                    FROM tb_dados
                    WHERE `{coluna}` LIKE '%x%' OR `{coluna}` LIKE '%[%'
                    LIMIT 20
                """)
                
                resultados = cursor.fetchall()
                
                if resultados:
                    f.write(f"\nColuna {coluna} - Valores com caracteres especiais:\n")
                    f.write("-" * 50 + "\n")
                    for loc_cod, var_cod, valor in resultados:
                        f.write(f"  loc_cod={loc_cod}, var_cod={var_cod}, valor='{valor}'\n")
            except Exception as e:
                f.write(f"Erro ao analisar {coluna}: {e}\n")
    
    cursor.close()
    print(f"   ✓ Arquivo 'dados_problematicos.txt' criado")


def main():
    """Função principal"""
    print("\n" + "=" * 80)
    print("ANÁLISE DE DADOS PARA MIGRAÇÃO - BANCO 'imp'")
    print("Data:", datetime.now().strftime('%d/%m/%Y %H:%M:%S'))
    print("=" * 80)
    
    conexao = conectar()
    if not conexao:
        return
    
    print("\n✅ Conectado ao banco de dados 'imp'")
    
    try:
        # Executar análises
        resultados_gerais = analisar_tb_dados_completa(conexao)
        analisar_valores_extremos(conexao)
        analisar_caracteres_especiais(conexao)
        analisar_amostra_por_variavel(conexao)
        
        # Gerar recomendações
        gerar_recomendacoes(resultados_gerais)
        
        # Exportar problemas
        exportar_problemas_para_arquivo(conexao)
        
        print("\n" + "=" * 80)
        print("✅ ANÁLISE CONCLUÍDA")
        print("=" * 80)
        print("\nPróximos passos:")
        print("1. Revisar o arquivo 'dados_problematicos.txt'")
        print("2. Decidir estratégia de conversão baseado nos resultados")
        print("3. Atualizar script de migração conforme recomendações")
        
    finally:
        conexao.close()
        print("\n✅ Conexão encerrada.")


if __name__ == "__main__":
    main()
