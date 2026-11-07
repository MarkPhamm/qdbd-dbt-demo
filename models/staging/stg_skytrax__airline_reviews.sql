-- stg_skytrax__airline_reviews.sql
-- Staging model for raw Skytrax airline (flight) reviews.
-- Grain: one row per review_id.
-- Dedup: the scrape assigns a fresh review_id each time it re-ingests a
-- review, so review_id alone does not identify a submission - the same review
-- lands more than once under different ids. Deduplicate on the content that
-- actually identifies a submission and keep the most recently updated copy,
-- tie-breaking on review_id so the surviving row is stable across runs.

with source_data as (

    select
        *,
    from {{ source('skytrax_raw', 'airline_reviews') }}

),

deduped as (

    select
        *,
    from source_data
    qualify
        row_number() over (
            partition by customer_name, nationality, airline_id, date_submitted, review
            order by updated_at desc, review_id
        ) = 1

)

select
    review_id,
    airline_id,
    verify,
    date_submitted,
    date_flown,
    customer_name,
    nationality,
    type_of_traveller,
    seat_type,
    aircraft,
    origin_city,
    origin_airport,
    destination_city,
    destination_airport,
    transit_city,
    transit_airport,
    seat_comfort,
    cabin_staff_service,
    food_and_beverages,
    inflight_entertainment,
    ground_service,
    wifi_and_connectivity,
    value_for_money,
    recommended,
    review,
    updated_at,
from deduped
