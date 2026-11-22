-- dim_amenity.sql
-- Lounge amenity. Grain: one row per amenity a lounge can offer.

select
    amenity_id,
    amenity_name,
    amenity_group,
from (
    values
        (1, 'shower', 'washroom'),
        (2, 'day bed', 'rest'),
        (3, 'spa', 'rest'),
        (4, 'hot food', 'dining'),
        (5, 'none', 'none')
) as amenities (amenity_id, amenity_name, amenity_group)
