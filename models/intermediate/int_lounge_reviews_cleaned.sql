-- int_lounge_reviews_cleaned.sql
-- Clean and normalize staged airport lounge reviews.
-- Grain: one row per review_id.
-- See int_airline_reviews_cleaned for the conventions applied here.

with source_data as (

    select
        *,
    from {{ ref('stg_skytrax__lounge_reviews') }}

),

cleaned as (

    select
        review_id,
        airline_id,
        coalesce(lounge_name, 'unknown') as lounge_name,
        coalesce(airport, 'unknown') as airport,
        coalesce(type_of_lounge, 'unknown') as type_of_lounge,
        coalesce(customer_name, 'unknown') as customer_name,
        coalesce(nationality, 'unknown') as nationality,
        date_submitted,
        date_visit,
        verify as is_verified,
        coalesce(type_of_traveller, 'unknown') as type_of_traveller,
        comfort::integer as comfort,
        cleanliness::integer as cleanliness,
        bar_and_beverages::integer as bar_and_beverages,
        catering::integer as catering,
        washrooms::integer as washrooms,
        wifi_connectivity::integer as wifi_connectivity,
        staff_service::integer as staff_service,
        recommended,
        review as review_text,
        updated_at,
    from source_data

)

select
    *,
from cleaned
