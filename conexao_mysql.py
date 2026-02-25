import mysql.connector
from mysql.connector import Error

# =========================================
# ⚠️ ALTERE PARA SEUS DADOS DE ACESSO
# =========================================
CONFIG = {
    'host': '10.209.59.96',
    'user': 'colabX',            # ← seu usuário
    'password': 'sua_senha',     # ← sua senha
    'database': 'colabX'          # ← seu banco (padrão)
}

def conectar(database=CONFIG['database']):
    """Conecta ao banco de dados MySQL
    
    Args:
        database (str): Nome do banco a conectar.
                       'colabX' = seu banco (padrão)
                       'imp' = banco de referência com dados originais
    """
    try:
        config = CONFIG.copy()
        config['database'] = database
        
        conexao = mysql.connector.connect(**config)
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
    # Conectar ao seu banco (padrão)
    conn = conectar()
    if conn:
        colunas, tabelas = executar_query(conn, "SHOW TABLES;")
        print(f"\n📦 Tabelas encontradas: {len(tabelas)}")
        for t in tabelas:
            print(f"   • {t[0]}")
        fechar(conn)
    
    # Se quiser consultar o banco 'imp' para diagnóstico:
    # conn_imp = conectar(database='imp')
    # if conn_imp:
    #     colunas, tabelas = executar_query(conn_imp, "SHOW TABLES;")
    #     print(f"\n📦 Tabelas em 'imp': {len(tabelas)}")
    #     fechar(conn_imp)
