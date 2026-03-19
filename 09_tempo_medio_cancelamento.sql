-- ============================================================
-- 09_tempo_medio_cancelamento.sql
-- Tempo médio de permanência até o cancelamento
--
-- Objetivo: entender em que momento do ciclo de vida o cliente
-- tende a cancelar, por plano e motivo, para direcionar ações
-- de onboarding e retenção preventiva no período crítico.
-- ============================================================

WITH cancelled AS (
    SELECT
        ct.id,
        p.name                                         AS plano,
        p.amount                                       AS valor,
        ct.start_date,
        ct.cancellation_date,
        ct.cancellation_reason                         AS motivo,
        (ct.cancellation_date - ct.start_date)         AS dias_ativo
    FROM contracts ct
    JOIN plans p ON p.id = ct.plan_id
    WHERE ct.status = 'cancelled'
      AND ct.cancellation_date IS NOT NULL
)
SELECT
    plano,
    valor,
    COUNT(*)                                           AS total_cancelamentos,
    ROUND(AVG(dias_ativo), 0)                          AS media_dias_ativo,
    ROUND(AVG(dias_ativo) / 30.0, 1)                   AS media_meses_ativo,
    ROUND(MIN(dias_ativo), 0)                          AS min_dias,
    ROUND(MAX(dias_ativo), 0)                          AS max_dias,
    -- Motivo mais frequente
    MODE() WITHIN GROUP (ORDER BY motivo)              AS motivo_principal
FROM cancelled
GROUP BY plano, valor
ORDER BY valor;
