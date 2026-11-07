-- dim_lounge.sql
-- Lounge dimension.
-- Grain: one row per unique (lounge_name, airport, type_of_lounge) combination.
-- Surrogate key: dbt_utils hash of the natural key.
-- type_of_lounge is part of the grain because the same physical lounge is
-- reviewed under different access tiers (Business Class, Frequent Flyer, ...).

with reviews as (

    select
        *,
    from {{ ref('int_lounge_reviews_cleaned') }}

),

distinct_lounges as (

    select distinct
        lounge_name,
        airport,
        type_of_lounge,
    from reviews

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['lounge_name', 'airport', 'type_of_lounge']) }} as lounge_id,
        lounge_name,
        airport,
        type_of_lounge,
    from distinct_lounges

)

select
    *,
from final
