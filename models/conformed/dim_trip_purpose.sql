-- dim_trip_purpose.sql
-- Why the reviewer travelled. Grain: one row per purpose.

select
    trip_purpose_id,
    purpose_name,
    purpose_group,
from (
    values
        (1, 'Holiday', 'leisure'),
        (2, 'Visiting family', 'leisure'),
        (3, 'Business meeting', 'work'),
        (4, 'Crew layover', 'work'),
        (5, 'unknown', 'unknown')
) as purposes (trip_purpose_id, purpose_name, purpose_group)
