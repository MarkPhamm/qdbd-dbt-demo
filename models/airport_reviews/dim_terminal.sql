-- dim_terminal.sql
-- Terminal inside an airport. Grain: one row per terminal.

select
    terminal_id,
    terminal_name,
    airport_id,
from (
    values
        (1, 'Main', 1),
        (2, 'North', 1),
        (3, 'Satellite', 2),
        (4, 'unknown', 0)
) as terminals (terminal_id, terminal_name, airport_id)
