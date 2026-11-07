-- fct_airline_review.sql
-- Airline (flight) review fact.
-- Grain: one row per review submission.
-- Primary key: review_id, carried through from the source.
-- Every dimensional attribute is a foreign key to a conformed dimension; the
-- ratings and the derived average/band are the measures.

{% set rating_columns = [
    'seat_comfort',
    'cabin_staff_service',
    'food_and_beverages',
    'inflight_entertainment',
    'ground_service',
    'wifi_and_connectivity',
    'value_for_money',
] %}

with base as (

    select
        src.*,
    from {{ ref('int_airline_reviews_cleaned') }} as src

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

with_dates as (

    select
        wc.*,
        ds.date_id as date_submitted_id,
        df.date_id as date_flown_id,
    from with_customer as wc
    left join {{ ref('dim_date') }} as ds
        on wc.date_submitted = ds.date_id
    left join {{ ref('dim_date') }} as df
        on wc.date_flown = df.date_id

),

with_locations as (

    select
        wd.*,
        lo_origin.location_id as origin_location_id,
        lo_dest.location_id as destination_location_id,
        lo_transit.location_id as transit_location_id,
    from with_dates as wd
    left join {{ ref('dim_location') }} as lo_origin
        on wd.origin_city = lo_origin.city
        and wd.origin_airport = lo_origin.airport
    left join {{ ref('dim_location') }} as lo_dest
        on wd.destination_city = lo_dest.city
        and wd.destination_airport = lo_dest.airport
    left join {{ ref('dim_location') }} as lo_transit
        on wd.transit_city = lo_transit.city
        and wd.transit_airport = lo_transit.airport

),

with_aircraft as (

    select
        wl.*,
        da.aircraft_id,
    from with_locations as wl
    left join {{ ref('dim_aircraft') }} as da
        on wl.aircraft_model = da.aircraft_model

),

with_cabin as (

    select
        wa.*,
        dcb.cabin_id,
    from with_aircraft as wa
    left join {{ ref('dim_cabin') }} as dcb
        on wa.seat_type = dcb.cabin_name

),

with_route as (

    select
        wcb.*,
        dr.route_id,
    from with_cabin as wcb
    left join {{ ref('dim_route') }} as dr
        on wcb.origin_location_id = dr.origin_location_id
        and wcb.destination_location_id = dr.destination_location_id

),

with_ratings as (

    select
        wr.*,
        {{ average_rating(rating_columns) }} as average_rating,
    from with_route as wr

),

final as (

    select
        review_id,
        airline_id,
        customer_id,
        date_submitted_id,
        date_flown_id,
        origin_location_id,
        destination_location_id,
        transit_location_id,
        route_id,
        aircraft_id,
        cabin_id,
        is_verified,
        type_of_traveller,
        transit_city != 'unknown' as has_layover,
        seat_comfort,
        cabin_staff_service,
        food_and_beverages,
        inflight_entertainment,
        ground_service,
        wifi_and_connectivity,
        value_for_money,
        recommended,
        average_rating,
        {{ rating_band('average_rating') }} as rating_band,
        review_text,
        updated_at as source_updated_at,
        current_timestamp as dbt_loaded_at,
    from with_ratings
    where
        -- Drop rows whose mandatory foreign keys failed to resolve. date_flown
        -- and the location/aircraft keys are optional on the source, but the
        -- 'unknown' coalescing in the intermediate layer means they always
        -- resolve to a dimension row in practice - a null here is a real defect.
        customer_id is not null
        and date_submitted_id is not null
        and origin_location_id is not null
        and destination_location_id is not null
        and transit_location_id is not null
        and route_id is not null
        and aircraft_id is not null
        and cabin_id is not null
        -- Every rating is unscored (null) or a valid 1-5 score.
        and {{ valid_ratings_filter(rating_columns) }}

)

select
    *,
from final
