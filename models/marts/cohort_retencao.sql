-- O tamanho da coorte sai de uma agregacao propria, e nao de
-- count(distinct ...) over (partition by ...): PostgreSQL nao implementa
-- DISTINCT dentro de window function ("DISTINCT is not implemented for
-- window functions"), e era isso que derrubava o CI.
with clientes as (
    select
        cl.client_id,
        date_trunc('quarter', cl.created_at)              as cohort_quarter
    from {{ ref('stg_clients') }} cl
),

tamanho_coorte as (
    select
        cohort_quarter,
        count(distinct client_id)                         as total_cohort
    from clientes
    group by cohort_quarter
),

cohort_base as (
    select
        c.client_id,
        c.cohort_quarter,
        t.total_cohort
    from clientes c
    join tamanho_coorte t on t.cohort_quarter = c.cohort_quarter
),

monthly_payers as (
    select distinct
        ct.client_id,
        date_trunc('month', fr.competence)                as activity_month
    from {{ ref('stg_financial_receivables') }} fr
    join {{ ref('stg_contracts') }} ct on ct.contract_id = fr.contract_id
    where fr.is_paid = true
),

cohort_activity as (
    select
        cb.cohort_quarter,
        cb.total_cohort,
        mp.client_id,
        mp.activity_month,
        (extract(year  from mp.activity_month) - extract(year  from cb.cohort_quarter)) * 12
        + (extract(month from mp.activity_month) - extract(month from cb.cohort_quarter))
                                                          as months_since_start
    from cohort_base cb
    join monthly_payers mp on mp.client_id = cb.client_id
    where mp.activity_month >= cb.cohort_quarter
),

cohort_retention as (
    select
        cohort_quarter,
        total_cohort,
        months_since_start,
        count(distinct client_id)                         as retained
    from cohort_activity
    group by cohort_quarter, total_cohort, months_since_start
)

select
    to_char(cohort_quarter, 'YYYY "Q"Q')                  as coorte,
    months_since_start                                    as mes_n,
    total_cohort                                          as total_clientes,
    retained                                              as clientes_retidos,
    round(
        retained * 100.0 / nullif(total_cohort, 0), 1
    )                                                     as retencao_pct
from cohort_retention
where months_since_start in (0, 1, 3, 6, 9, 12, 18, 24)
order by cohort_quarter, months_since_start
