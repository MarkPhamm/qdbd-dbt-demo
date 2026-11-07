-- Intermediate: a reusable building block that isn't meant for end users.
--
-- Pulled out of `orders` so the chain under stg_payments is one model longer.
-- `state:modified+` then rebuilds int_order_payments and orders, and leaves
-- stg_orders alone.

with payments as (

    select * from {{ ref('stg_payments') }}

)

select
    order_id,
    count(*)    as payment_count,
    sum(amount) as total_amount

from payments
group by order_id
