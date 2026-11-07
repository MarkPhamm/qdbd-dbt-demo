-- stg_skytrax__airport_reviews.sql
-- Staging model for raw Skytrax airport reviews.
-- Grain: one row per review_id.
-- Dedup: the scrape assigns a fresh review_id each time it re-ingests a
-- review, so review_id alone does not identify a submission - the same review
-- lands more than once under different ids. Deduplicate on the content that
-- actually identifies a submission and keep the most recently updated copy,
-- tie-breaking on review_id so the surviving row is stable across runs.

with source_data as (

    select
        *,
    from {{ source('skytrax_raw', 'airport_reviews') }}

),

deduped as (

    select
        *,
    from source_data
    qualify
        row_number() over (
            partition by customer_name, nationality, airport_id, date_submitted, review
            order by updated_at desc, review_id
        ) = 1

)

select
    review_id,
    airport_id,
    verify,
    date_submitted,
    date_visit,
    customer_name,
    nationality,
    experience_at_airport,
    type_of_traveller,
    queuing_times,
    terminal_cleanliness,
    terminal_seating,
    terminal_signs,
    food_beverages,
    airport_shopping,
    airport_staff,
    wifi_connectivity,
    recommended,
    review,
    updated_at,
from deduped
