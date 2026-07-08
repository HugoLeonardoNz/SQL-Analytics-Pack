with monthly_new as (
    select
        date_trunc('month', s.sale_date)           as mes,
        round(sum(s.amount_after), 2)              as mrr_novo
    from {{ source('fibernet', 'sales') }} s
    where s.sale_type = 'NEW'
    group by mes
),

monthly_churn as (
    select
        date_trunc('month', ct.cancellation_date)  as mes,
        round(sum(ct.monthly_amount), 2)           as mrr_cancelado
    from {{ ref('stg_contracts') }} ct
    where ct.status = 'cancelled'
      and ct.cancellation_date is not null
    group by mes
),

monthly_combined as (
    select
        coalesce(n.mes, ch.mes)                    as mes,
        coalesce(n.mrr_novo, 0)                    as mrr_novo,
        coalesce(ch.mrr_cancelado, 0)              as mrr_cancelado
    from monthly_new n
    full outer join monthly_churn ch on ch.mes = n.mes
)

select
    to_char(mes, 'YYYY-MM')                        as mes,
    mrr_novo,
    mrr_cancelado,
    mrr_novo - mrr_cancelado                       as crescimento_liquido,
    round(
        sum(mrr_novo - mrr_cancelado)
        over (order by mes rows between unbounded preceding and current row)
    , 2)                                           as mrr_acumulado
from monthly_combined
order by mes
