-- dim_disruption.sql
-- Why a flight was late or missed. Grain: one row per disruption.

select
    disruption_id,
    disruption_name,
    disruption_severity,
from (
    values
        (1, 'none', 'none'),
        (2, 'late inbound aircraft', 'minor'),
        (3, 'weather', 'major'),
        (4, 'technical', 'major'),
        (5, 'crew', 'major'),
        (6, 'unknown', 'unknown')
) as disruptions (disruption_id, disruption_name, disruption_severity)
