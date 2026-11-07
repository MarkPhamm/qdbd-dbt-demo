-- fct_lounge_review.sql
-- Airport lounge review fact.
-- Grain: one row per review submission.
-- Primary key: review_id, carried through from the source.

{% set rating_columns = [
    'comfort',
    'cleanliness',
    'bar_and_beverages',
    'catering',
    'washrooms',
    'wifi_connectivity',
    'staff_service',
] %}

with base as (

    select
        src.*,
    from {{ ref('int_lounge_reviews_cleaned') }} as src

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

with_lounge as (

    select
        wc.*,
        dl.lounge_id,
    from with_customer as wc
    left join {{ ref('dim_lounge') }} as dl
        on wc.lounge_name = dl.lounge_name
        and wc.airport = dl.airport
        and wc.type_of_lounge = dl.type_of_lounge

),

with_dates as (

    select
        wl.*,
        ds.date_id as date_submitted_id,
        dv.date_id as date_visit_id,
    from with_lounge as wl
    left join {{ ref('dim_date') }} as ds
        on wl.date_submitted = ds.date_id
    left join {{ ref('dim_date') }} as dv
        on wl.date_visit = dv.date_id

),

with_ratings as (

    select
        wd.*,
        {{ average_rating(rating_columns) }} as average_rating,
    from with_dates as wd

),

final as (

    select
        review_id,
        airline_id,
        lounge_id,
        customer_id,
        date_submitted_id,
        date_visit_id,
        is_verified,
        type_of_traveller,
        comfort,
        cleanliness,
        bar_and_beverages,
        catering,
        washrooms,
        wifi_connectivity,
        staff_service,
        recommended,
        average_rating,
        {{ rating_band('average_rating') }} as rating_band,
        review_text,
        updated_at as source_updated_at,
        current_timestamp as dbt_loaded_at,
    from with_ratings
    where
        customer_id is not null
        and lounge_id is not null
        and date_submitted_id is not null
        and {{ valid_ratings_filter(rating_columns) }}

)

select
    *,
from final
