-- fct_seat_review.sql
-- Aircraft seat review fact.
-- Grain: one row per review submission.
-- Primary key: review_id, carried through from the source.

{% set rating_columns = [
    'seat_legroom',
    'seat_recline',
    'seat_width',
    'aisle_space',
    'seat_storage',
    'power_supply',
    'viewing_tv_screen',
    'sleep_comfort',
    'sitting_comfort',
    'seat_bed_width',
    'seat_bed_length',
    'seat_privacy',
] %}

with base as (

    select
        src.*,
    from {{ ref('int_seat_reviews_cleaned') }} as src

),

with_customer as (

    select
        b.*,
        dc.customer_id,
    from base as b
    left join {{ ref('dim_customer') }} as dc
        on b.customer_name = dc.customer_name
        and b.nationality = dc.nationality

),

with_aircraft as (

    select
        wc.*,
        da.aircraft_id,
    from with_customer as wc
    left join {{ ref('dim_aircraft') }} as da
        on wc.aircraft_model = da.aircraft_model

),

with_seat_configuration as (

    select
        wa.*,
        dsc.seat_configuration_id,
    from with_aircraft as wa
    left join {{ ref('dim_seat_configuration') }} as dsc
        on wa.seat_type = dsc.seat_type
        and wa.seat_layout = dsc.seat_layout

),

with_cabin as (

    select
        wsc.*,
        dcb.cabin_id,
    from with_seat_configuration as wsc
    left join {{ ref('dim_cabin') }} as dcb
        on wsc.seat_type = dcb.cabin_name

),

with_dates as (

    select
        wsc.*,
        ds.date_id as date_submitted_id,
        df.date_id as date_flown_id,
    from with_cabin as wsc
    left join {{ ref('dim_date') }} as ds
        on wsc.date_submitted = ds.date_id
    left join {{ ref('dim_date') }} as df
        on wsc.date_flown = df.date_id

),

with_ratings as (

    select
        wd.*,
        {{ average_rating(rating_columns) }} as average_rating,
    from with_dates as wd

),

final as (

    select
        review_id,
        airline_id,
        aircraft_id,
        seat_configuration_id,
        cabin_id,
        customer_id,
        date_submitted_id,
        date_flown_id,
        is_verified,
        type_of_traveller,
        seat_legroom,
        seat_recline,
        seat_width,
        aisle_space,
        seat_storage,
        power_supply,
        viewing_tv_screen,
        sleep_comfort,
        sitting_comfort,
        seat_bed_width,
        seat_bed_length,
        seat_privacy,
        recommended,
        average_rating,
        {{ rating_band('average_rating') }} as rating_band,
        review_text,
        updated_at as source_updated_at,
        current_timestamp as dbt_loaded_at,
    from with_ratings
    where
        customer_id is not null
        and aircraft_id is not null
        and seat_configuration_id is not null
        and cabin_id is not null
        and date_submitted_id is not null
        and {{ valid_ratings_filter(rating_columns) }}

)

select
    *,
from final
