-- stg_skytrax__lounge_reviews.sql
-- Staging model for raw Skytrax airport lounge reviews.
-- Grain: one row per review_id.
-- Dedup: the scrape assigns a fresh review_id each time it re-ingests a
-- review, so review_id alone does not identify a submission - the same review
-- lands more than once under different ids. Deduplicate on the content that
-- actually identifies a submission and keep the most recently updated copy,
-- tie-breaking on review_id so the surviving row is stable across runs.

with source_data as (

    select
        *,
    from {{ source('skytrax_raw', 'lounge_reviews') }}

),

deduped as (

    select
        *,
    from source_data
    qualify
        row_number() over (
            partition by customer_name, nationality, airline_id, lounge_name, date_submitted, review
            order by updated_at desc, review_id
        ) = 1

)

select
    review_id,
    airline_id,
    lounge_name,
    airport,
    type_of_lounge,
    type_of_traveller,
    verify,
    date_submitted,
    date_visit,
    customer_name,
    nationality,
    comfort,
    cleanliness,
    bar_and_beverages,
    catering,
    washrooms,
    wifi_connectivity,
    staff_service,
    recommended,
    review,
    updated_at,
from deduped
