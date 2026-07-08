with boleto_atraso as (
    select
        ct.contract_id,
        count(fr.receivable_id)                    as boletos_em_atraso,
        round(sum(fr.amount), 2)                   as valor_em_atraso,
        max(current_date - fr.due_date)            as max_dias_atraso
    from {{ ref('stg_financial_receivables') }} fr
    join {{ ref('stg_contracts') }} ct on ct.contract_id = fr.contract_id
    where fr.is_paid = false
      and fr.due_date < current_date
      and ct.status = 'active'
    group by ct.contract_id
),

tickets_abertos as (
    select
        contract_id,
        count(*)                                   as tickets_abertos
    from {{ ref('stg_support_tickets') }}
    where is_open = true
    group by contract_id
),

risk_score as (
    select
        ct.contract_id,
        cl.city                                    as cidade,
        p.name                                     as plano,
        ct.monthly_amount                          as mensalidade,
        coalesce(ba.boletos_em_atraso, 0)          as boletos_em_atraso,
        coalesce(ba.valor_em_atraso,   0)          as valor_em_atraso,
        coalesce(ba.max_dias_atraso,   0)          as max_dias_atraso,
        coalesce(ta.tickets_abertos,   0)          as tickets_abertos,
        (coalesce(ba.boletos_em_atraso, 0)
         + coalesce(ta.tickets_abertos, 0) * 2)   as score_risco
    from {{ ref('stg_contracts') }} ct
    join {{ ref('stg_clients') }} cl on cl.client_id = ct.client_id
    join {{ source('fibernet', 'plans') }} p on p.id = ct.plan_id
    left join boleto_atraso   ba on ba.contract_id = ct.contract_id
    left join tickets_abertos ta on ta.contract_id = ct.contract_id
    where ct.status = 'active'
)

select
    contract_id,
    cidade,
    plano,
    mensalidade,
    boletos_em_atraso,
    valor_em_atraso,
    max_dias_atraso,
    tickets_abertos,
    score_risco,
    case
        when score_risco >= 5 then 'CRÍTICO'
        when score_risco >= 3 then 'ALTO'
        when score_risco >= 1 then 'MÉDIO'
    end                                            as nivel_risco
from risk_score
where score_risco > 0
order by score_risco desc, max_dias_atraso desc
