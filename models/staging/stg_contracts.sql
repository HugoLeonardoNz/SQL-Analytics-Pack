with source as (
    select * from {{ source('fibernet', 'contracts') }}
)

select
    id                  as contract_id,
    client_id,
    plan_id,
    seller_id,
    amount              as monthly_amount,
    start_date,
    cancellation_date,
    status,
    cancellation_reason
from source
where status is not null
