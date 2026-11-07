{% macro average_rating(columns) %}
{#-
    Mean of the supplied 1-5 rating columns, ignoring nulls.
    Reviewers only score the categories they care about, so a plain average
    over all columns would punish sparse reviews - divide by the number of
    categories actually scored instead. Returns null when nothing was scored.
-#}
round(
    (
        {% for column in columns -%}
        coalesce({{ column }}, 0){{ ' + ' if not loop.last }}
        {%- endfor %}
    )
    /
    nullif(
        {% for column in columns -%}
        ({{ column }} is not null)::int{{ ' + ' if not loop.last }}
        {%- endfor %},
        0
    ),
    2
)
{% endmacro %}


{% macro rating_band(column_name) %}
{#-
    Bucket an average rating into a reporting band.
-#}
case
    when {{ column_name }} is null then 'unknown'
    when {{ column_name }} < 2 then 'bad'
    when {{ column_name }} < 4 then 'medium'
    else 'good'
end
{% endmacro %}


{% macro valid_ratings_filter(columns) %}
{#-
    Defensive guard: every rating is either null (not scored) or within 1-5.
    Emits a boolean expression for use in a WHERE clause.
-#}
{% for column in columns -%}
({{ column }} is null or {{ column }} between 1 and 5){{ '\n        and ' if not loop.last }}
{%- endfor %}
{% endmacro %}
