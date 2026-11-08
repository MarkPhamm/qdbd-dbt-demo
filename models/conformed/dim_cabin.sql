-- dim_cabin.sql
-- Conformed cabin dimension, shared by airline and seat reviews.
-- Grain: one row per cabin as the source spells it (Economy Class, Premium
-- Economy, Business Class, First Class, or 'unknown').
-- Surrogate key: dbt_utils hash of cabin_name.
-- Built from both subjects, so a cabin reviewed in only one still resolves.

with cabins as (

    select seat_type as cabin_name,
    from {{ ref('int_airline_reviews_cleaned') }}

    union

    select seat_type as cabin_name,
    from {{ ref('int_seat_reviews_cleaned') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['cabin_name']) }} as cabin_id,
        cabin_name,
    from cabins

)

select
    *,
from final
