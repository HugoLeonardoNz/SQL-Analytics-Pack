-- Falha se mrr_acumulado for negativo — indica dados corrompidos,
-- pois MRR acumulado partindo de zero nunca pode ficar abaixo de zero.
select *
from {{ ref('mrr_mensal') }}
where mrr_acumulado < 0
