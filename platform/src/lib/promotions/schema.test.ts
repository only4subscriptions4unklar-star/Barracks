import { describe, expect, it } from "vitest";
import { formatMoney, fromRupees } from "@/lib/money";
import { evaluateCart } from "./engine";
import { parseRule, toPromotion, type PromotionRow } from "./schema";
import type { CartLine } from "./types";

/**
 * These assert that the rows written by 0003_seed.sql drive the engine
 * correctly — the seam where a schema change would otherwise silently misprice
 * the Standard Offer.
 */

/** Verbatim from supabase/migrations/0003_seed.sql. */
const SEEDED_STANDARD_OFFER: PromotionRow = {
  id: "e0000000-0000-4000-8000-000000000001",
  name: "The Standard Offer",
  customer_message: "Any two trousers · Rs 5,000",
  rule_kind: "BUNDLE_FIXED_PRICE",
  rule_config: { quantity: 2, bundlePriceMinor: 500000 },
  status: "ACTIVE",
  starts_at: null,
  ends_at: null,
  coupon_code: null,
  min_quantity: null,
  min_cart_value_minor: null,
  priority: 10,
  stackable: false,
  category_ids: ["a0000000-0000-4000-8000-000000000001"],
};

const SEEDED_FREE_DELIVERY: PromotionRow = {
  ...SEEDED_STANDARD_OFFER,
  id: "e0000000-0000-4000-8000-000000000002",
  name: "Complimentary island-wide delivery",
  customer_message: "Complimentary island-wide delivery above Rs 7,500",
  rule_kind: "FREE_SHIPPING",
  rule_config: { minSpendMinor: 750000 },
  priority: 100,
  stackable: true,
  category_ids: null,
};

/** Seeded prices, in minor units, as stored by the migration. */
function line(id: string, priceMinorUnits: number): CartLine {
  return {
    id,
    productId: `product-${id}`,
    collectionIds: ["b0000000-0000-4000-8000-000000000001"],
    categoryId: "a0000000-0000-4000-8000-000000000001",
    unitPriceMinor: fromRupees(priceMinorUnits / 100),
    quantity: 1,
    promotionEligible: true,
  };
}

describe("seeded promotion rows drive the engine", () => {
  it("reads the Standard Offer as a Rs 5,000 two-trouser bundle", () => {
    const promotion = toPromotion(SEEDED_STANDARD_OFFER);
    expect(promotion.rule).toEqual({
      kind: "BUNDLE_FIXED_PRICE",
      quantity: 2,
      bundlePriceMinor: fromRupees(5000),
    });
  });

  it("prices the seeded Golf Chino + Pure Linen pair at exactly Rs 5,000", () => {
    // 275000 and 295000 minor units, straight from 0003_seed.sql.
    const totals = evaluateCart(
      [line("golf-chino", 275000), line("pure-linen", 295000)],
      [toPromotion(SEEDED_STANDARD_OFFER)],
    );
    expect(formatMoney(totals.subtotalMinor)).toBe("Rs 5,700");
    expect(formatMoney(totals.totalMinor)).toBe("Rs 5,000");
  });

  it("reaches the seeded free-delivery threshold at Rs 7,500", () => {
    const promotions = [toPromotion(SEEDED_FREE_DELIVERY)];
    expect(evaluateCart([line("a", 700000)], promotions).freeShipping).toBe(false);
    expect(evaluateCart([line("a", 750000)], promotions).freeShipping).toBe(true);
  });

  it("rejects a malformed rule rather than mispricing silently", () => {
    expect(() => parseRule("BUNDLE_FIXED_PRICE", { quantity: 1, bundlePriceMinor: 500000 })).toThrow();
    expect(() => parseRule("BUNDLE_FIXED_PRICE", { bundlePriceMinor: -5 })).toThrow();
    expect(() => parseRule("PERCENT_OFF", { percent: 250 })).toThrow();
    expect(() => parseRule("NOT_A_RULE", {})).toThrow(/Unknown promotion rule kind/);
  });
});
