-- stg_skytrax__airports.sql
-- Airport lookup from the source system.
-- Grain: one row per airport_id.

with source_data as (

    select
        *,
    from {{ source('skytrax_raw', 'airports') }}

)

select
    airport_id,
    airport_name,
from source_data
