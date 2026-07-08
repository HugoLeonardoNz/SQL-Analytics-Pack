with source as (
    select * from {{ source('fibernet', 'tickets') }}
)

select
    id              as ticket_id,
    contract_id,
    protocol,
    category,
    status,
    created_at,
    closed_at,
    sla_seconds,
    status = 'open'                                           as is_open,
    extract(epoch from (closed_at - created_at)) / 3600.0    as resolution_hours
from source
where status is not null
