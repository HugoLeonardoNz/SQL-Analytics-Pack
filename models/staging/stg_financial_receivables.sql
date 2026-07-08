with source as (
    select * from {{ source('fibernet', 'financial_receivables') }}
)

select
    id              as receivable_id,
    contract_id,
    amount,
    due_date,
    paid_at,
    competence,
    paid_at is not null                           as is_paid,
    (paid_at is null and due_date < current_date) as is_overdue
from source
