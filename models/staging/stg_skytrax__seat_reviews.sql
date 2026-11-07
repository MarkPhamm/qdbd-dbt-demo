-- stg_skytrax__seat_reviews.sql
-- Staging model for raw Skytrax aircraft seat reviews.
-- Grain: one row per review_id.
-- Dedup: the scrape assigns a fresh review_id each time it re-ingests a
-- review, so review_id alone does not identify a submission - the same review
-- lands more than once under different ids. Deduplicate on the content that
-- actually identifies a submission and keep the most recently updated copy,
-- tie-breaking on review_id so the surviving row is stable across runs.

with source_data as (

    select
        *,
    from {{ source('skytrax_raw', 'seat_reviews') }}

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
    type_of_traveller,
    seat_type,
    aircraft_type,
    seat_layout,
    verify,
    date_submitted,
    date_flown,
    customer_name,
    nationality,
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
    review,
    updated_at,
from deduped
