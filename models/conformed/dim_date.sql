-- dim_date.sql
-- Conformed date dimension, shared by every review fact.
-- Grain: one row per calendar day.
-- Key: date_id (the date itself), so fact rows join on the raw date.
-- The spine covers every date column on all four cleaned models, so a date
-- that appears in only one subject still resolves. See generate_dates_dimension.

{{ generate_dates_dimension([
    {'relation': ref('int_airline_reviews_cleaned'), 'columns': ['date_submitted', 'date_flown']},
    {'relation': ref('int_airport_reviews_cleaned'), 'columns': ['date_submitted', 'date_visit']},
    {'relation': ref('int_lounge_reviews_cleaned'), 'columns': ['date_submitted', 'date_visit']},
    {'relation': ref('int_seat_reviews_cleaned'), 'columns': ['date_submitted', 'date_flown']},
]) }}
