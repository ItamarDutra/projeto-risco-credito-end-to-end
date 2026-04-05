import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError


# =============================================================================
# Script: 01_load_data_postgres.py
# Objetivo: Ingestão otimizada de dados de risco de crédito.
# Descrição: Lê um arquivo compactado volumoso, extraindo apenas as colunas
#            necessárias para a análise, e carrega no PostgreSQL.
#            Isso otimiza o uso de memória e o tempo de processamento.
# =============================================================================

def carregar_dados_credito():
    # 1. Definição das colunas estritamente necessárias (Governança de Dados)
    # Ignoramos 106 colunas para focar apenas nas métricas vitais para a modelagem.
    colunas_selecionadas = [
        'SK_ID_CURR', 'TARGET', 'CODE_GENDER', 'FLAG_OWN_CAR', 'FLAG_OWN_REALTY',
        'CNT_CHILDREN', 'AMT_INCOME_TOTAL', 'AMT_CREDIT', 'AMT_ANNUITY',
        'NAME_INCOME_TYPE', 'NAME_EDUCATION_TYPE', 'NAME_FAMILY_STATUS',
        'NAME_HOUSING_TYPE', 'DAYS_BIRTH', 'DAYS_EMPLOYED', 'OCCUPATION_TYPE'
    ]

    print("Iniciando a extração dos dados...")

    try:
        # 2. Leitura Inteligente com Chunks (Otimização de Memória)
        tamanho_bloco = 50000
        reader = pd.read_csv('../banco_de_dados/application_train.csv.zip',
                             usecols=colunas_selecionadas,
                             chunksize=tamanho_bloco)

        # 3. Conexão com o Banco de Dados
        string_conexao = 'postgresql://postgres:123456@localhost:5432/postgres'
        engine = create_engine(string_conexao)

        print("Conectando ao PostgreSQL e iniciando a carga em blocos (Chunks)...")

        # 4. Inserção dos dados em iteração
        primeiro_bloco = True
        linhas_totais = 0

        for chunk in reader:
            # No primeiro bloco usamos 'replace' para limpar a tabela antiga
            # Nos blocos seguintes usamos 'append' para adicionar os dados
            modo = 'replace' if primeiro_bloco else 'append'
            chunk.to_sql(name='tb_risco_credito', con=engine, if_exists=modo, index=False)
            primeiro_bloco = False

            linhas_totais += len(chunk)
            print(f"Inserido bloco de {len(chunk)} linhas... (Total processado: {linhas_totais})")

        print("Carga finalizada com sucesso! O banco está pronto para as consultas analíticas.")
    # 5. Tratamento de Erros Profissional
    except FileNotFoundError:
        print("Erro: O arquivo 'application_train.csv.zip' não foi encontrado no diretório atual.")
    except SQLAlchemyError as e:
        print(f"Erro ao conectar ou inserir no banco de dados: {e}")
    except Exception as e:
        print(f"Ocorreu um erro inesperado: {e}")


if __name__ == "__main__":
    carregar_dados_credito()