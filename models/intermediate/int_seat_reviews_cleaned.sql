-- int_seat_reviews_cleaned.sql
-- Clean and normalize staged aircraft seat reviews.
-- Grain: one row per review_id.
-- See int_airline_reviews_cleaned for the conventions applied here.
-- seat_layout is additionally normalized ('3-3', '3X3', '3*3' -> '3x3') so the
-- seat configuration dimension has one member per layout, not per spelling.

with source_data as (

    select
        *,
    from {{ ref('stg_skytrax__seat_reviews') }}

),

cleaned as (

    select
        review_id,
        airline_id,
        coalesce(customer_name, 'unknown') as customer_name,
        coalesce(nationality, 'unknown') as nationality,
        date_submitted,
        date_flown,
        verify as is_verified,
        coalesce(type_of_traveller, 'unknown') as type_of_traveller,
        coalesce(seat_type, 'unknown') as seat_type,
        coalesce({{ normalize_seat_layout('seat_layout') }}, 'unknown') as seat_layout,
        coalesce(aircraft_type, 'unknown') as aircraft_model,
        seat_legroom::integer as seat_legroom,
        seat_recline::integer as seat_recline,
        seat_width::integer as seat_width,
        aisle_space::integer as aisle_space,
        seat_storage::integer as seat_storage,
        power_supply::integer as power_supply,
        viewing_tv_screen::integer as viewing_tv_screen,
        sleep_comfort::integer as sleep_comfort,
        sitting_comfort::integer as sitting_comfort,
        seat_bed_width::integer as seat_bed_width,
        seat_bed_length::integer as seat_bed_length,
        seat_privacy::integer as seat_privacy,
        recommended,
        review as review_text,
        updated_at,
    from source_data

)

select
    *,
from cleaned
