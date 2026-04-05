/* ============================================================================
   Script: 01_etl_camada_semantica.sql
   Objetivo: Criar uma camada de visualização (VIEW) limpa e padronizada.
   Descrição: Este script transforma os dados brutos (inglês/formatos nativos)
              em uma tabela semântica amigável em português. Ele também trata
              anomalias conhecidas da base de dados (ex: DAYS_EMPLOYED) e
              converte dias absolutos em anos para facilitar a análise.
   ============================================================================ */

CREATE OR REPLACE VIEW view_risco_credito AS
SELECT
    "SK_ID_CURR"          AS sk_id_curr,
    "TARGET"              AS target,

    -- 1. Padronização Demográfica e de Identificação
    "CODE_GENDER"         AS genero,
    "CNT_CHILDREN"        AS qtd_filhos,
    "NAME_FAMILY_STATUS"  AS estado_civil,
    "NAME_EDUCATION_TYPE" AS escolaridade,

    -- 2. Padronização de Bens e Renda
    "FLAG_OWN_CAR"        AS possui_carro,
    "FLAG_OWN_REALTY"     AS possui_imovel,
    "NAME_INCOME_TYPE"    AS tipo_renda,
    "OCCUPATION_TYPE"     AS profissao,
    "AMT_INCOME_TOTAL"    AS renda_total,
    "AMT_CREDIT"          AS valor_credito,
    "AMT_ANNUITY"         AS valor_parcela,

    -- 3. Transformação de Regras de Negócio (Conversão de Tempo)
    -- Transforma dias absolutos de nascimento em idade em anos
    ABS("DAYS_BIRTH") / 365 AS idade,

    -- Trata a anomalia '365243' (que indica ausência de dados/desemprego) para 0,
    -- e converte os demais dias de emprego em anos de empresa.
    CASE
        WHEN "DAYS_EMPLOYED" = 365243 THEN 0
        ELSE ABS("DAYS_EMPLOYED") / 365
    END AS anos_de_casa

FROM
    public.tb_risco_credito;




