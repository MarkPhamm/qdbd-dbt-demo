-- dim_airport.sql
-- Airport dimension.
-- Grain: one row per airport in the source airport lookup.
-- Key: airport_id straight from the source - a stable natural key.
-- Built from the full lookup, so airports with no reviews are still present.

with airports as (

    select
        *,
    from {{ ref('stg_skytrax__airports') }}

),

final as (

    select
        airport_id,
        airport_name,
        lower(trim(airport_name)) as airport_name_cleaned,
    from airports

)

select
    *,
from final
