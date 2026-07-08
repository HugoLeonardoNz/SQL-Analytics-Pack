with seller_stats as (
    select
        sl.id                                                     as seller_id,
        sl.name                                                   as vendedor,
        count(s.id) filter (where s.sale_type = 'NEW')            as novas_vendas,
        count(s.id) filter (where s.sale_type = 'UPGRADE')        as upgrades,
        count(s.id) filter (where s.sale_type = 'DOWNGRADE')      as downgrades,
        round(
            sum(s.amount_after) filter (where s.sale_type = 'NEW')
        , 2)                                                      as receita_nova,
        count(distinct ct.contract_id) filter (
            where ct.status = 'cancelled'
              and s.sale_type = 'NEW'
        )                                                         as vendas_canceladas
    from {{ source('fibernet', 'sellers') }} sl
    left join {{ source('fibernet', 'sales') }} s  on s.seller_id = sl.id
    left join {{ ref('stg_contracts') }} ct         on ct.contract_id = s.contract_id
    group by sl.id, sl.name
)

select
    vendedor,
    novas_vendas,
    upgrades,
    downgrades,
    receita_nova,
    vendas_canceladas,
    round(
        vendas_canceladas * 100.0 / nullif(novas_vendas, 0), 1
    )                                                             as churn_pct_carteira,
    dense_rank() over (order by receita_nova desc)                as ranking
from seller_stats
order by ranking
