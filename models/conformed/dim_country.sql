-- dim_country.sql
-- Conformed country dimension. Grain: one row per country a reviewer is from.

select
    country_id,
    country_name,
    region_name,
from (
    values
        (1, 'United Kingdom', 'Europe'),
        (2, 'United States', 'North America'),
        (3, 'Australia', 'Oceania'),
        (4, 'Singapore', 'Asia'),
        (5, 'unknown', 'unknown')
) as countries (country_id, country_name, region_name)
