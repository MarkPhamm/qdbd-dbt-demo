-- dim_location.sql
-- Location dimension covering origin, destination and transit airports.
-- Grain: one row per unique (city, airport) combination.
-- Surrogate key: dbt_utils hash of the natural key.
-- One conformed dimension is used for all three roles on the fact, which then
-- joins to it three times (a role-playing dimension).

with reviews as (

    select
        *,
    from {{ ref('int_airline_reviews_cleaned') }}

),

all_locations as (

    select
        origin_city as city,
        origin_airport as airport,
    from reviews

    union all

    select
        destination_city as city,
        destination_airport as airport,
    from reviews

    union all

    select
        transit_city as city,
        transit_airport as airport,
    from reviews

),

-- union all above is safe: this select distinct dedupes the combined set
distinct_locations as (

    select distinct
        city,
        airport,
    from all_locations

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['city', 'airport']) }} as location_id,
        city,
        airport,
    from distinct_locations

)

select
    *,
from final
