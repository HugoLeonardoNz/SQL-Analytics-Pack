with source as (
    select * from {{ source('fibernet', 'clients') }}
)

select
    id           as client_id,
    city,
    neighborhood,
    created_at,
    status
from source
where status is not null
