/* ============================================================================
   Script: 02_eda_analise_exploratoria.sql
   Objetivo: Investigar padrões de inadimplência e perfis de risco.
   Descrições: Consultas focadas em entender a relação entre escolaridade, 
               renda, ocupação e comportamento de pagamento (Target).
   ============================================================================ */

-- 1. ANÁLISE DE ESCOLARIDADE VS INADIMPLÊNCIA
-- Insight: Existe uma correlação direta onde maior nível educacional 
-- resulta em menores taxas de inadimplência (Target próximo de zero).
SELECT 
    escolaridade,
    COUNT(sk_id_curr) AS total_clientes,
    ROUND(AVG(target) * 100, 2) AS taxa_inadimplencia_perc
FROM view_risco_credito
GROUP BY 1
ORDER BY 3 DESC;


-- 2. INVESTIGAÇÃO DE INADIMPLENCIA E REPRESENTAÇÃO DE DIVIDA POR PROFISSÃO
-- Pergunta: Profissões que recebem mais, possuem taxa de inadimplência menores?
-- Conclusão: Não há nenhuma correlação direta.
--
-- Resultado: a unica coisa vísivel é que, pessoas que recebem mais,
-- fazem emprestimos de uma representação menor dos seus salários.
--
-- Insight: nada importante para analise, pois mesmo assim existe médias
-- de inadimplência altissímas até para pessoas que fazem uma dívida
-- com uma representação menor do seu salário.
SELECT
    profissao,
    ROUND(AVG(target * 100), 2) AS taxa_inadimplencia,
    ROUND(AVG(renda_total::numeric), 2) AS media_renda,
    ROUND(AVG(valor_parcela::numeric), 2) AS media_parcela,
    -- Cálculo da representação da parcela sobre a renda
    ROUND(AVG((valor_parcela::numeric/ NULLIF(renda_total, 0)::numeric)) * 100), 2) AS perc_comprometimento_renda
FROM view_risco_credito
GROUP BY 1
ORDER BY 5 DESC;


-- 3. PERFIL PATRIMONIAL (BENS)
-- Insight: Surpreendentemente, possuir apenas carro apresenta-se como 
-- um indicador de 'menor inadimplência' MELHOR do que casa e carro.
-- Porém, usarei a posse de qualquer um pela diferença entre carro e casa ser pequena e
-- conseguir englobar uma maior quantidade de clientes mantendo a inadimplência baixa.
SELECT 
    possui_carro,
    possui_imovel,
    ROUND(AVG(target) * 100, 2) AS taxa_inadimplencia
FROM view_risco_credito
GROUP BY 1, 2;


-- 4. ANÁLISE TEMPORAL (IDADE E TEMPO DE CASA)
-- Utilização de NTILE para criar quintis de idade e analisar o risco por faixa.
-- Insight: Quanto mais idade a pessoa possui, a frequência é que,
-- ela seja melhor pagadora. Isso porque a média de inadimplência
-- é diretamente proporcional a idade.
SELECT
    vrc.grup_idade,
    MIN(vrc.idade) AS idade_min,
    MAX(vrc.idade) AS idade_max,
    ROUND(AVG(vrc.target) * 100, 2) AS taxa_inadimplencia
FROM (
    SELECT *, NTILE(5) OVER(ORDER BY idade::int) AS grup_idade
    FROM view_risco_credito
) AS vrc
GROUP BY 1
ORDER BY 1 DESC;



-- 5. GOVERNANÇA E QUALIDADE DE DADOS
-- Verificação de duplicidade de IDs e integridade da chave primária.
SELECT 
    COUNT(DISTINCT sk_id_curr) AS ids_unicos,
    COUNT(*) AS total_linhas,
    PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY sk_id_curr) AS mediana_id
FROM view_risco_credito;
-- Resultado: Não há duplicidade de IDs (IDs únicos = Total de linhas).

