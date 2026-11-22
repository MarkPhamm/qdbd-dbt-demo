-- dim_review_channel.sql
-- How the review was submitted. Grain: one row per channel.

select
    review_channel_id,
    channel_name,
    is_mobile,
from (
    values
        (1, 'website', false),
        (2, 'ios', true),
        (3, 'android', true),
        (4, 'unknown', false)
) as review_channels (review_channel_id, channel_name, is_mobile)
