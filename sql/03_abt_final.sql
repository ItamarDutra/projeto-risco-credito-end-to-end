/* ============================================================================
   Script: 03_abt_final.sql
   Objetivo: Criação da Analytical Base Table (ABT) para consumo no Power BI.
   Descrição: Esta view consolida as regras de negócio de classificação de risco
              (baseadas nos insights da EDA) e pré-calcula métricas agregadas
              usando Window Functions. O objetivo é entregar os dados otimizados
              para o Dashboard, reduzindo a complexidade de cálculos no DAX.
   ============================================================================ */

CREATE OR REPLACE VIEW vw_base_analitica_final AS
WITH classification_risco AS (
    SELECT
        *,
        -- 1. CLASSIFICAÇÃO DO GRUPO DE RISCO
        -- Regras baseadas na Análise Exploratória (EDA):
        -- Grupo 1 (Baixo Risco): Alta escolaridade com bens, ou idosos (>60).
        -- Grupo 3 (Alto Risco): Jovens (<35) com menor grau de instrução.
        -- Grupo 2 (Médio Risco): Demais perfis.
        CASE
            WHEN escolaridade = 'Academic degree'
                OR (escolaridade = 'Higher education' AND (possui_carro = 'Y' OR possui_imovel = 'Y') AND idade > 30)
                OR idade > 60 THEN '1 - Baixo Risco'
            WHEN idade < 35 AND escolaridade NOT IN ('Higher education', 'Academic degree') THEN '3 - Alto Risco'
            ELSE '2 - Médio Risco'
        END AS grup_risco,

        -- 2. CÁLCULO DE COMPROMETIMENTO DE RENDA
        -- Utilização de NULLIF para garantir segurança na divisão, evitando erros de "Division by Zero".
        ROUND((valor_parcela::NUMERIC / NULLIF(renda_total, 0)::NUMERIC) * 100, 2) AS representacao_divida
    FROM
        view_risco_credito vrc
)
-- 3. PRÉ-AGREGAÇÃO DE MÉTRICAS (OTIMIZAÇÃO PARA POWER BI)
-- Uso de Window Functions para calcular estatísticas dos grupos sem precisar agrupar (GROUP BY) a base inteira,
-- mantendo a granularidade a nível de cliente (sk_id_curr).
SELECT
    *,
    ROUND(AVG(target * 100) OVER(PARTITION BY grup_risco), 2) AS taxa_inadimplencia_grup,
    COUNT(*) OVER(PARTITION BY grup_risco) AS quant_pessoas,
    ROUND(COUNT(*) OVER(PARTITION BY grup_risco)::NUMERIC / COUNT(*) OVER()::NUMERIC * 100, 2) AS representacao_todo
FROM
    classification_risco;


