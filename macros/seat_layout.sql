{% macro normalize_seat_layout(column_name) %}
{#-
    Reviewers write the same cabin layout half a dozen ways - "3x3", "3-3",
    "3X3", "3*3", "3 x 3", "3+3" and the unicode "3×3" are all the same seating
    arrangement. Fold every separator onto a single lowercase 'x' so the seat
    configuration dimension gets one member per real layout instead of one per
    spelling. Anything that is not a separator is left alone, so genuinely
    unparseable values stay visible rather than being silently mangled.
-#}
nullif(
    regexp_replace(
        lower(trim(coalesce({{ column_name }}, ''))),
        '[\s\-*+×x]+',
        'x',
        'g'
    ),
    ''
)
{% endmacro %}


{% macro seats_per_row(column_name) %}
{#-
    Total seats abreast, summed across the aisle groups of a normalized layout
    ("3x4x3" -> 10). Null when the layout does not follow the NxNxN pattern.
-#}
case
    when regexp_full_match({{ column_name }}, '^\d+(x\d+)*$')
        then list_reduce(
            list_transform(string_split({{ column_name }}, 'x'), x -> x::integer),
            (a, b) -> a + b
        )
end
{% endmacro %}
