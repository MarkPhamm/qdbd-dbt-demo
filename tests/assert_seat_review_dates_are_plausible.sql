{{ config(severity='warn') }}

-- A handful of seat reviews carry an epoch-sentinel date_submitted of
-- 1970-01-01, which is not a real submission date. The rows are kept (the
-- ratings and review text are genuine) but flagged, so the count is visible
-- rather than quietly skewing any time series.

select
    review_id,
    date_submitted_id,
from {{ ref('fct_seat_review') }}
where date_submitted_id < '1995-01-01'
