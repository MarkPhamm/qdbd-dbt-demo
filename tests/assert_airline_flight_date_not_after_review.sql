{{ config(severity='warn') }}

-- A flight cannot be taken after the review of it was submitted. A small number
-- of source rows violate this (the scrape appears to mis-parse some date_flown
-- values). They are left in the model rather than dropped - the flight date is
-- the only suspect field - so this warns instead of failing the build.

select
    review_id,
    date_submitted_id,
    date_flown_id,
from {{ ref('fct_airline_review') }}
where
    date_flown_id is not null
    and date_flown_id > date_submitted_id
