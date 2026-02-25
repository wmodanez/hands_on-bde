"""
Script para comparar a estrutura entre o banco 'imp' (referência) e seu banco pessoal
Útil para diagnóstico e validação durante os exercícios
"""

import mysql.connector
from mysql.connector import Error

# =========================================
# ⚠️ ALTERE PARA SEUS DADOS DE ACESSO
# =========================================
CONFIG = {
    'host': '10.209.59.96',
    'user': 'colabX',            # ← seu usuário
    'password': 'sua_senha',     # ← sua senha
}

def conectar(database):
    """Conecta ao banco de dados MySQL"""
    try:
        config = CONFIG.copy()
        config['database'] = database
        
        conexao = mysql.connector.connect(**config)
        if conexao.is_connected():
            return conexao
    except Error as e:
        print(f"❌ Erro ao conectar a '{database}': {e}")
        return None

def obter_tabelas(conexao):
    """Obtém lista de tabelas"""
    try:
        cursor = conexao.cursor()
        cursor.execute("SHOW TABLES;")
        tabelas = [t[0] for t in cursor.fetchall()]
        cursor.close()
        return tabelas
    except Error as e:
        print(f"❌ Erro ao obter tabelas: {e}")
        return []

def comparar_bancos(banco_usuario, banco_referencia='imp'):
    """Compara estrutura entre dois bancos"""
    
    print("\n" + "="*70)
    print(f"📊 COMPARAÇÃO: '{banco_usuario}' vs '{banco_referencia}'")
    print("="*70)
    
    # Conectar aos dois bancos
    conn_user = conectar(banco_usuario)
    conn_imp = conectar(banco_referencia)
    
    if not conn_user or not conn_imp:
        print("❌ Falha ao conectar aos bancos")
        return
    
    # Obter tabelas
    tabelas_user = obter_tabelas(conn_user)
    tabelas_imp = obter_tabelas(conn_imp)
    
    # Exibir resultados
    print(f"\n📦 Banco '{banco_usuario}':")
    print(f"   Total de tabelas: {len(tabelas_user)}")
    if tabelas_user:
        for t in tabelas_user:
            print(f"   • {t}")
    else:
        print("   (vazio)")
    
    print(f"\n📦 Banco '{banco_referencia}' (Referência):")
    print(f"   Total de tabelas: {len(tabelas_imp)}")
    if tabelas_imp:
        for t in tabelas_imp:
            print(f"   • {t}")
    
    # Análise comparativa
    print(f"\n📈 Análise:")
    if len(tabelas_user) == 0:
        print(f"   ✓ Seu banco está vazio (início dos exercícios)")
        print(f"   ✓ Referência tem {len(tabelas_imp)} tabelas para estudar")
    elif len(tabelas_user) == len(tabelas_imp):
        print(f"   ✓ Seu banco tem a mesma quantidade de tabelas!")
        
        # Verificar quais tabelas faltam
        faltam = set(tabelas_imp) - set(tabelas_user)
        extras = set(tabelas_user) - set(tabelas_imp)
        
        if faltam:
            print(f"\n   ⚠️ Tabelas faltando: {len(faltam)}")
            for t in sorted(faltam):
                print(f"      • {t}")
        
        if extras:
            print(f"\n   ℹ️ Tabelas extras (não em 'imp'): {len(extras)}")
            for t in sorted(extras):
                print(f"      • {t}")
        
        if not faltam and not extras:
            print(f"   ✅ Estrutura idêntica!")
    else:
        print(f"   ⚠️ Diferença: {len(tabelas_imp) - len(tabelas_user)} tabelas faltando")
    
    # Fechar conexões
    conn_user.close()
    conn_imp.close()
    
    print("\n" + "="*70 + "\n")

# Teste rápido
if __name__ == "__main__":
    # Substituir 'colabX' pelo seu banco
    seu_banco = 'colabX'  # ← ALTERE PARA SEU BANCO
    
    comparar_bancos(seu_banco, 'imp')
    
    # Exemplos adicionais (descomente conforme necessário):
    # comparar_bancos('bruna', 'imp')
    # comparar_bancos('lorenna', 'imp')
