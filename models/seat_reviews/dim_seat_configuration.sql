-- dim_seat_configuration.sql
-- Seat configuration dimension.
-- Grain: one row per unique (seat_type, seat_layout) combination.
-- Surrogate key: dbt_utils hash of the natural key.
-- seat_layout arrives already normalized from the intermediate layer, so the
-- spellings '3-3', '3X3', '3*3' and '3 x 3' collapse onto one member.
-- seats_per_row is parsed out of it ("3x4x3" -> 10) so cabin density can be
-- compared without string handling in the BI layer; layouts that do not follow
-- the NxN pattern yield null.

with reviews as (

    select
        *,
    from {{ ref('int_seat_reviews_cleaned') }}

),

distinct_configurations as (

    select distinct
        seat_type,
        seat_layout,
    from reviews

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['seat_type', 'seat_layout']) }} as seat_configuration_id,
        seat_type,
        seat_layout,
        {{ seats_per_row('seat_layout') }} as seats_per_row,
    from distinct_configurations

)

select
    *,
from final
