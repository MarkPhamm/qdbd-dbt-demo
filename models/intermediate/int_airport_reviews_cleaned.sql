-- int_airport_reviews_cleaned.sql
-- Clean and normalize staged airport reviews.
-- Grain: one row per review_id.
-- See int_airline_reviews_cleaned for the conventions applied here.

with source_data as (

    select
        *,
    from {{ ref('stg_skytrax__airport_reviews') }}

),

cleaned as (

    select
        review_id,
        airport_id,
        coalesce(customer_name, 'unknown') as customer_name,
        coalesce(nationality, 'unknown') as nationality,
        date_submitted,
        date_visit,
        verify as is_verified,
        coalesce(experience_at_airport, 'unknown') as experience_at_airport,
        coalesce(type_of_traveller, 'unknown') as type_of_traveller,
        queuing_times::integer as queuing_times,
        terminal_cleanliness::integer as terminal_cleanliness,
        terminal_seating::integer as terminal_seating,
        terminal_signs::integer as terminal_signs,
        food_beverages::integer as food_beverages,
        airport_shopping::integer as airport_shopping,
        airport_staff::integer as airport_staff,
        wifi_connectivity::integer as wifi_connectivity,
        recommended,
        review as review_text,
        updated_at,
    from source_data

)

select
    *,
from cleaned
