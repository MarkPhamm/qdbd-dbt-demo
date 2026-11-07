-- One row per order, with payment totals folded in.
--
-- Refs stg_orders and int_order_payments. An edit to stg_payments rebuilds
-- this model (two hops down) and does not rebuild stg_orders. That is the
-- split `--defer` and `state:modified+` rely on.

with orders as (

    select * from {{ ref('stg_orders') }}

),

order_payments as (

    select * from {{ ref('int_order_payments') }}

)

select
    orders.order_id,
    orders.customer_id,
    orders.order_date,
    orders.status,
    coalesce(order_payments.payment_count, 0) as payment_count,
    coalesce(order_payments.total_amount, 0)  as amount

from orders
left join order_payments
    on orders.order_id = order_payments.order_id
