# How Shopping Frequency Shapes Grocery Baskets: Instacart Summary

**Question:** When the same customer waits longer between grocery orders, how does their cart change?

**Data:** 3.3 million Instacart orders with known contents from 206,209 customers. The main comparison uses the 88,202 customers who placed both **short-interval** orders (1–3 days after their previous order) and **long-interval** orders (8–30 days).

## Bottom line

**Shopping frequency is linked much more to *how much* customers buy than to *what* they buy.** After a longer wait, the same customers buy bigger baskets, but the mix of categories stays largely the same.

## Key findings

| | Short interval | Long interval | Change |
|---|---|---|---|
| Average basket size | 7.7 items | 10.1 items | **+31%** |
| Customers with bigger long-interval baskets | | | **71%** |
| Different aisles per basket | 5.8 | 7.3 | +1.5 |
| Fresh produce share of items | 24.6% | 25.7% | +1.1 pts |
| Snacks share of items | 7.2% | 6.8% | −0.3 pts |

- **Bigger baskets:** +2.4 items per order after a long wait (median +1.7). The result holds under several checks.
- **Stable mix:** no tracked category's share of the basket moves by more than about one percentage point. Staples gain slightly: produce +1.1, yogurt +0.6, milk +0.3, eggs +0.2.
- **More categories, mostly from more items:** yogurt appears in 25.8% of long-interval orders vs 17.7% of short ones, and milk in 24.2% vs 16.9%. At the same basket size, though, both kinds of order cover about the same number of aisles.
- **Context, across customers:** in their first 90 days, the most frequent shoppers (13+ orders) bought 175 items against 49 for the least frequent (4–5 orders). Their average basket sizes were similar, about 10 items.

## Possible implications (to test, not assume)

1. **Use "days since last order" as a simple signal.** Customers returning after a week or more tend to place bigger orders. That's useful for capacity planning and for timing basket-building offers.
2. **Lead with the customer's usual items.** Long-gap baskets are mostly fuller versions of the normal shop, so "buy it again" lists are likely to fit better than pushing new categories.
3. **Remind customers about staples after a gap.** Milk, yogurt, eggs and produce show the largest increase in how often they appear.
4. **Encourage regular ordering.** Total volume tracks how often customers shop, not their basket size. Programs that make ordering more frequent and convenient are worth testing.

## Limitations

- **Association, not causation.** A big stock-up order may be what causes the longer gap, rather than the other way round.
- **Intervals are capped at 30 days**, so "30" means 30 or more, and very infrequent shoppers can't be identified.
- **No prices, quantities or dates.** Results are about product lines in the cart, not spend or seasonality.
- **Coverage:** the within-customer group (43% of customers) leans towards frequent shoppers. Seafood and poultry are under 1% of items.

*Tools: PostgreSQL, Python (pandas, matplotlib). Full method and code are in the project README.*
