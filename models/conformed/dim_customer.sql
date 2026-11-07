-- dim_customer.sql
-- Conformed customer dimension, shared by every review fact.
-- Grain: one row per unique (customer_name, nationality) combination.
-- Surrogate key: dbt_utils hash of the natural key, so it is deterministic and
-- identical to the key each fact already stores.
-- Note: reviewers are not identified in the source, so (name, nationality) is
-- the best available proxy for a person. Two different people sharing a name
-- and nationality collapse into one row.
-- Counts and first/latest dates span all four review subjects. A customer who
-- only appears in one subject still gets a row; the other subject counts are 0.

with reviews as (

    select customer_name, nationality, date_submitted, 'airline' as review_subject,
    from {{ ref('int_airline_reviews_cleaned') }}

    union all

    select customer_name, nationality, date_submitted, 'airport' as review_subject,
    from {{ ref('int_airport_reviews_cleaned') }}

    union all

    select customer_name, nationality, date_submitted, 'lounge' as review_subject,
    from {{ ref('int_lounge_reviews_cleaned') }}

    union all

    select customer_name, nationality, date_submitted, 'seat' as review_subject,
    from {{ ref('int_seat_reviews_cleaned') }}

),

customer_agg as (

    select
        customer_name,
        nationality,
        count(*) as number_of_reviews,
        count(*) filter (where review_subject = 'airline') as airline_review_count,
        count(*) filter (where review_subject = 'airport') as airport_review_count,
        count(*) filter (where review_subject = 'lounge') as lounge_review_count,
        count(*) filter (where review_subject = 'seat') as seat_review_count,
        min(date_submitted) as first_review_date,
        max(date_submitted) as latest_review_date,
    from reviews
    group by
        customer_name,
        nationality

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['customer_name', 'nationality']) }} as customer_id,
        customer_name,
        nationality,
        number_of_reviews,
        airline_review_count,
        airport_review_count,
        lounge_review_count,
        seat_review_count,
        first_review_date,
        latest_review_date,
    from customer_agg

)

select
    *,
from final
