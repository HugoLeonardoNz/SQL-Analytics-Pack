with plan_revenue as (
    select
        p.name                                     as plano,
        p.amount                                   as valor_plano,
        count(ct.contract_id)                      as contratos_ativos,
        round(sum(ct.monthly_amount), 2)           as mrr_plano,
        round(avg(
            extract(month from age(
                coalesce(ct.cancellation_date, current_date),
                ct.start_date
            )) +
            extract(year from age(
                coalesce(ct.cancellation_date, current_date),
                ct.start_date
            )) * 12
        ), 1)                                      as tempo_medio_meses,
        round(
            p.amount * avg(
                extract(month from age(
                    coalesce(ct.cancellation_date, current_date),
                    ct.start_date
                )) +
                extract(year from age(
                    coalesce(ct.cancellation_date, current_date),
                    ct.start_date
                )) * 12
            ), 2
        )                                          as ltv_estimado
    from {{ source('fibernet', 'plans') }} p
    join {{ ref('stg_contracts') }} ct on ct.plan_id = p.id
    where ct.status = 'active'
    group by p.id, p.name, p.amount
)

select
    plano,
    valor_plano,
    contratos_ativos,
    mrr_plano,
    tempo_medio_meses,
    ltv_estimado,
    round(
        mrr_plano * 100.0 / sum(mrr_plano) over (), 2
    )                                              as pct_mrr_total
from plan_revenue
order by valor_plano
