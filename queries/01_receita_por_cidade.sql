-- ============================================================
-- 01_receita_por_cidade.sql
-- Receita Recorrente Mensal (MRR) por cidade
--
-- Objetivo: identificar quais cidades concentram maior receita
-- ativa para priorizar expansão de cobertura e esforço comercial.
-- ============================================================

SELECT
    c.city                                         AS cidade,
    COUNT(DISTINCT ct.id)                          AS contratos_ativos,
    ROUND(SUM(ct.amount), 2)                       AS mrr_total,
    ROUND(AVG(ct.amount), 2)                       AS ticket_medio,
    ROUND(
        SUM(ct.amount) * 100.0
        / SUM(SUM(ct.amount)) OVER (), 2
    )                                              AS pct_receita
FROM contracts ct
JOIN clients c ON c.id = ct.client_id
WHERE ct.status = 'active'
GROUP BY c.city
ORDER BY mrr_total DESC;
