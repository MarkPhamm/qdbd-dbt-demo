-- dim_traveller_type.sql
-- Conformed traveller-type dimension, shared by every review fact.
-- Grain: one row per way a reviewer described the trip.

select
    traveller_type_id,
    traveller_type_name,
    traveller_type_group,
from (
    values
        (1, 'Solo Leisure', 'leisure'),
        (2, 'Couple Leisure', 'leisure'),
        (3, 'Family Leisure', 'leisure'),
        (4, 'Business', 'work'),
        (5, 'unknown', 'unknown')
) as traveller_types (traveller_type_id, traveller_type_name, traveller_type_group)
