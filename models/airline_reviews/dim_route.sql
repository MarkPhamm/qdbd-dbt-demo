-- dim_route.sql
-- Route dimension: where a flight started and where it ended.
-- Grain: one row per unique (origin, destination) location pair, regardless of
-- airline or layover.
-- Surrogate key: dbt_utils hash of the two location ids. The location ids are
-- hashed exactly as dim_location hashes (city, airport), so they join back to
-- it; the relationships tests in the yml guard that.

with reviews as (

    select
        *,
    from {{ ref('int_airline_reviews_cleaned') }}

),

pairs as (

    select distinct
        {{ dbt_utils.generate_surrogate_key(['origin_city', 'origin_airport']) }} as origin_location_id,
        {{ dbt_utils.generate_surrogate_key(['destination_city', 'destination_airport']) }} as destination_location_id,
    from reviews

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['origin_location_id', 'destination_location_id']) }} as route_id,
        origin_location_id,
        destination_location_id,
    from pairs

)

select
    *,
from final
