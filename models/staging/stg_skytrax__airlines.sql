-- stg_skytrax__airlines.sql
-- Airline lookup from the source system.
-- Grain: one row per airline_id.

with source_data as (

    select
        *,
    from {{ source('skytrax_raw', 'airlines') }}

)

select
    airline_id,
    airline_name,
from source_data
