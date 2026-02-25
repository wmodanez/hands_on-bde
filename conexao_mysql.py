import mysql.connector
from mysql.connector import Error

def conectar_banco():
    """
    Conecta ao banco de dados MySQL 'imp' no localhost
    Usuário: root
    Senha: 123456
    """
    try:
        conexao = mysql.connector.connect(
            host='localhost',
            user='root',
            password='123456',
            database='imp'
        )
        
        if conexao.is_connected():
            info_db = conexao.get_server_info()
            print(f"Conectado com sucesso ao servidor MySQL versão {info_db}")
            
            cursor = conexao.cursor()
            cursor.execute("SELECT DATABASE();")
            banco_atual = cursor.fetchone()
            print(f"Banco de dados atual: {banco_atual[0]}")
            
            return conexao
        
    except Error as e:
        print(f"Erro ao conectar ao MySQL: {e}")
        return None

def executar_query(conexao, query):
    """
    Executa uma query SELECT no banco de dados
    """
    try:
        cursor = conexao.cursor()
        cursor.execute(query)
        resultado = cursor.fetchall()
        
        # Exibe os resultados
        for linha in resultado:
            print(linha)
        
        cursor.close()
        return resultado
        
    except Error as e:
        print(f"Erro ao executar query: {e}")
        return None

def fechar_conexao(conexao):
    """
    Fecha a conexão com o banco de dados
    """
    if conexao.is_connected():
        conexao.close()
        print("Conexão fechada com sucesso")

if __name__ == "__main__":
    # Conecta ao banco de dados
    conexao = conectar_banco()
    
    if conexao:
        # Exemplo: listar todas as tabelas do banco
        print("\n--- Tabelas do banco de dados ---")
        executar_query(conexao, "SHOW TABLES;")
        
        # Exemplo: executar uma query
        # executar_query(conexao, "SELECT * FROM sua_tabela;")
        
        # Fecha a conexão
        fechar_conexao(conexao)
