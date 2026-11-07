-- int_airline_reviews_cleaned.sql
-- Clean and normalize staged airline reviews.
-- Grain: one row per review_id.
-- All nullability handling and renaming is centralized here so the marts only
-- do key lookups and measure derivation.
-- Free-text attributes that become dimension keys are coalesced to 'unknown'
-- rather than left null, so every fact row still joins to a dimension row.

with source_data as (

    select
        *,
    from {{ ref('stg_skytrax__airline_reviews') }}

),

cleaned as (

    select
        review_id,
        airline_id,
        coalesce(customer_name, 'unknown') as customer_name,
        coalesce(nationality, 'unknown') as nationality,
        date_submitted,
        date_flown,
        coalesce(origin_city, 'unknown') as origin_city,
        coalesce(origin_airport, 'unknown') as origin_airport,
        coalesce(destination_city, 'unknown') as destination_city,
        coalesce(destination_airport, 'unknown') as destination_airport,
        coalesce(transit_city, 'unknown') as transit_city,
        coalesce(transit_airport, 'unknown') as transit_airport,
        coalesce(aircraft, 'unknown') as aircraft_model,
        verify as is_verified,
        coalesce(seat_type, 'unknown') as seat_type,
        coalesce(type_of_traveller, 'unknown') as type_of_traveller,
        seat_comfort::integer as seat_comfort,
        cabin_staff_service::integer as cabin_staff_service,
        food_and_beverages::integer as food_and_beverages,
        inflight_entertainment::integer as inflight_entertainment,
        ground_service::integer as ground_service,
        wifi_and_connectivity::integer as wifi_and_connectivity,
        value_for_money::integer as value_for_money,
        recommended,
        review as review_text,
        updated_at,
    from source_data

)

select
    *,
from cleaned
