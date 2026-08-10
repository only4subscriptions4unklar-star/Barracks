import { describe, expect, it } from "vitest";
import { ZERO, formatMoney, fromRupees, minor } from "@/lib/money";
import { evaluateCart } from "./engine";
import type { CartLine, Promotion } from "./types";

/**
 * These tests cover the money that customers are actually charged. Per brief
 * §99, this is where testing effort belongs — not on static markup.
 */

const STANDARD_OFFER: Promotion = {
  id: "promo-standard-offer",
  name: "The Standard Offer",
  customerMessage: "Any two trousers · Rs 5,000",
  rule: { kind: "BUNDLE_FIXED_PRICE", quantity: 2, bundlePriceMinor: fromRupees(5000) },
  eligibility: { categoryIds: ["trousers"] },
  status: "ACTIVE",
  startsAt: null,
  endsAt: null,
  couponCode: null,
  minQuantity: null,
  minCartValueMinor: null,
  priority: 10,
  stackable: false,
};

function trouser(id: string, rupees: number, quantity = 1): CartLine {
  return {
    id,
    productId: `product-${id}`,
    collectionIds: ["ss26"],
    categoryId: "trousers",
    unitPriceMinor: fromRupees(rupees),
    quantity,
    promotionEligible: true,
  };
}

function tee(id: string, rupees: number, quantity = 1): CartLine {
  return {
    id,
    productId: `product-${id}`,
    collectionIds: ["ss26"],
    categoryId: "tees",
    unitPriceMinor: fromRupees(rupees),
    quantity,
    promotionEligible: true,
  };
}

describe("The Standard Offer — two trousers for Rs 5,000", () => {
  it("charges full price for a single trouser", () => {
    const totals = evaluateCart([trouser("a", 2750)], [STANDARD_OFFER]);
    expect(totals.discountMinor).toBe(ZERO);
    expect(formatMoney(totals.totalMinor)).toBe("Rs 2,750");
    expect(totals.appliedPromotions).toHaveLength(0);
  });

  it("prices exactly two eligible trousers at the bundle price", () => {
    const totals = evaluateCart([trouser("a", 2750), trouser("b", 2950)], [STANDARD_OFFER]);
    expect(formatMoney(totals.subtotalMinor)).toBe("Rs 5,700");
    expect(formatMoney(totals.totalMinor)).toBe("Rs 5,000");
    expect(formatMoney(totals.discountMinor)).toBe("Rs 700");
    expect(totals.appliedPromotions[0].timesApplied).toBe(1);
  });

  it("pairs the two most expensive trousers, maximising the customer's saving", () => {
    // 3,200 + 2,950 bundled (saving 1,150) beats any cheaper pairing.
    const totals = evaluateCart(
      [trouser("a", 2750), trouser("b", 2950), trouser("c", 3200)],
      [STANDARD_OFFER],
    );
    expect(formatMoney(totals.discountMinor)).toBe("Rs 1,150");
    expect(formatMoney(totals.totalMinor)).toBe("Rs 7,750");
  });

  it("applies the bundle twice for four trousers", () => {
    const totals = evaluateCart(
      [trouser("a", 3200), trouser("b", 2950), trouser("c", 2750), trouser("d", 2400)],
      [STANDARD_OFFER],
    );
    expect(totals.appliedPromotions[0].timesApplied).toBe(2);
    // (3200+2950 → 5000) + (2750+2400 → 5000)
    expect(formatMoney(totals.totalMinor)).toBe("Rs 10,000");
  });

  it("leaves the odd trouser at full price with five in the bag", () => {
    const totals = evaluateCart(
      [
        trouser("a", 3200),
        trouser("b", 2950),
        trouser("c", 2750),
        trouser("d", 2400),
        trouser("e", 2400),
      ],
      [STANDARD_OFFER],
    );
    expect(totals.appliedPromotions[0].timesApplied).toBe(2);
    expect(formatMoney(totals.totalMinor)).toBe("Rs 12,400");
  });

  it("handles quantity greater than one on a single line", () => {
    const totals = evaluateCart([trouser("a", 2950, 2)], [STANDARD_OFFER]);
    expect(formatMoney(totals.totalMinor)).toBe("Rs 5,000");
    expect(totals.lineDiscountsMinor["a"]).toBe(fromRupees(900));
  });

  it("never raises the price when the pair is already cheaper than the bundle", () => {
    // Two Rs 2,000 trousers must stay Rs 4,000 — not be "upgraded" to Rs 5,000.
    const totals = evaluateCart([trouser("a", 2000), trouser("b", 2000)], [STANDARD_OFFER]);
    expect(totals.discountMinor).toBe(ZERO);
    expect(formatMoney(totals.totalMinor)).toBe("Rs 4,000");
  });

  it("ignores items outside the eligible category", () => {
    const totals = evaluateCart([trouser("a", 2750), tee("t", 1950)], [STANDARD_OFFER]);
    expect(totals.discountMinor).toBe(ZERO);
    expect(formatMoney(totals.totalMinor)).toBe("Rs 4,700");
  });

  it("ignores products the owner has excluded from promotions", () => {
    const excluded = { ...trouser("b", 2950), promotionEligible: false };
    const totals = evaluateCart([trouser("a", 2750), excluded], [STANDARD_OFFER]);
    expect(totals.discountMinor).toBe(ZERO);
  });

  it("splits the discount across the lines that earned it", () => {
    const totals = evaluateCart([trouser("a", 2750), trouser("b", 2950)], [STANDARD_OFFER]);
    const allocated =
      totals.lineDiscountsMinor["a"] + totals.lineDiscountsMinor["b"];
    expect(allocated).toBe(totals.discountMinor);
  });
});

describe("scheduling and coupons", () => {
  const scheduled: Promotion = {
    ...STANDARD_OFFER,
    startsAt: new Date("2026-08-01T00:00:00Z"),
    endsAt: new Date("2026-08-31T23:59:59Z"),
  };

  it("does not apply before the start date", () => {
    const totals = evaluateCart([trouser("a", 2750), trouser("b", 2950)], [scheduled], {
      now: new Date("2026-07-31T12:00:00Z"),
    });
    expect(totals.discountMinor).toBe(ZERO);
  });

  it("applies inside the window", () => {
    const totals = evaluateCart([trouser("a", 2750), trouser("b", 2950)], [scheduled], {
      now: new Date("2026-08-15T12:00:00Z"),
    });
    expect(formatMoney(totals.totalMinor)).toBe("Rs 5,000");
  });

  it("stops applying after the end date — no developer required", () => {
    const totals = evaluateCart([trouser("a", 2750), trouser("b", 2950)], [scheduled], {
      now: new Date("2026-09-01T00:00:01Z"),
    });
    expect(totals.discountMinor).toBe(ZERO);
  });

  it("ignores a draft or paused promotion", () => {
    for (const status of ["DRAFT", "PAUSED", "EXPIRED", "ARCHIVED"] as const) {
      const totals = evaluateCart(
        [trouser("a", 2750), trouser("b", 2950)],
        [{ ...STANDARD_OFFER, status }],
      );
      expect(totals.discountMinor).toBe(ZERO);
    }
  });

  it("requires the coupon code when one is configured", () => {
    const coded: Promotion = { ...STANDARD_OFFER, couponCode: "BARRACKS26" };
    const lines = [trouser("a", 2750), trouser("b", 2950)];

    expect(evaluateCart(lines, [coded]).discountMinor).toBe(ZERO);
    expect(
      formatMoney(evaluateCart(lines, [coded], { couponCode: "barracks26" }).totalMinor),
    ).toBe("Rs 5,000");
  });
});

describe("thresholds and other rule types", () => {
  it("waives delivery above the threshold only", () => {
    const freeDelivery: Promotion = {
      ...STANDARD_OFFER,
      id: "promo-delivery",
      name: "Complimentary delivery",
      customerMessage: "Complimentary island-wide delivery above Rs 7,500",
      rule: { kind: "FREE_SHIPPING", minSpendMinor: fromRupees(7500) },
      eligibility: {},
      priority: 100,
      stackable: true,
    };

    expect(evaluateCart([trouser("a", 2750)], [freeDelivery]).freeShipping).toBe(false);
    expect(evaluateCart([trouser("a", 8000)], [freeDelivery]).freeShipping).toBe(true);
  });

  it("takes a percentage off an eligible collection", () => {
    const fifteenOff: Promotion = {
      ...STANDARD_OFFER,
      id: "promo-15",
      rule: { kind: "PERCENT_OFF", percent: 15 },
      eligibility: { collectionIds: ["ss26"] },
      stackable: true,
    };
    const totals = evaluateCart([tee("t", 2000)], [fifteenOff]);
    expect(formatMoney(totals.discountMinor)).toBe("Rs 300");
  });

  it("honours a minimum cart value", () => {
    const spendAndSave: Promotion = {
      ...STANDARD_OFFER,
      id: "promo-spend",
      rule: { kind: "SPEND_GET_AMOUNT_OFF", minSpendMinor: fromRupees(10000), amountMinor: fromRupees(1000) },
      eligibility: {},
    };
    expect(evaluateCart([tee("t", 5000)], [spendAndSave]).discountMinor).toBe(ZERO);
    expect(formatMoney(evaluateCart([tee("t", 12000)], [spendAndSave]).discountMinor)).toBe("Rs 1,000");
  });

  it("makes the cheapest unit free on buy-2-get-1", () => {
    const bogo: Promotion = {
      ...STANDARD_OFFER,
      id: "promo-bogo",
      rule: { kind: "BUY_X_GET_Y_FREE", buyQuantity: 2, freeQuantity: 1 },
      eligibility: { categoryIds: ["tees"] },
    };
    const totals = evaluateCart([tee("a", 1950), tee("b", 1950), tee("c", 1450)], [bogo]);
    expect(formatMoney(totals.discountMinor)).toBe("Rs 1,450");
  });

  it("never discounts below zero", () => {
    const absurd: Promotion = {
      ...STANDARD_OFFER,
      id: "promo-absurd",
      rule: { kind: "FIXED_AMOUNT_OFF", amountMinor: fromRupees(999_999) },
      eligibility: {},
    };
    const totals = evaluateCart([tee("t", 1950)], [absurd]);
    expect(totals.totalMinor).toBe(ZERO);
    expect(totals.discountMinor).toBe(fromRupees(1950));
  });
});

describe("promotion precedence", () => {
  it("gives a non-stackable promotion exclusive claim on its lines", () => {
    const extra: Promotion = {
      ...STANDARD_OFFER,
      id: "promo-extra-10",
      name: "Extra 10%",
      rule: { kind: "PERCENT_OFF", percent: 10 },
      priority: 50,
      stackable: true,
    };
    const totals = evaluateCart([trouser("a", 2750), trouser("b", 2950)], [STANDARD_OFFER, extra]);
    // The Standard Offer runs first (priority 10) and is non-stackable, so the
    // 10% never compounds on the same trousers.
    expect(formatMoney(totals.totalMinor)).toBe("Rs 5,000");
    expect(totals.appliedPromotions).toHaveLength(1);
  });

  it("allows a stackable shipping promotion alongside a bundle", () => {
    const freeDelivery: Promotion = {
      ...STANDARD_OFFER,
      id: "promo-delivery",
      rule: { kind: "FREE_SHIPPING", minSpendMinor: fromRupees(5000) },
      eligibility: {},
      priority: 100,
      stackable: true,
    };
    const totals = evaluateCart(
      [trouser("a", 2750), trouser("b", 2950)],
      [STANDARD_OFFER, freeDelivery],
    );
    expect(formatMoney(totals.totalMinor)).toBe("Rs 5,000");
    expect(totals.freeShipping).toBe(true);
    expect(totals.appliedPromotions).toHaveLength(2);
  });
});

describe("empty and degenerate carts", () => {
  it("returns zeroes for an empty cart", () => {
    const totals = evaluateCart([], [STANDARD_OFFER]);
    expect(totals.subtotalMinor).toBe(ZERO);
    expect(totals.totalMinor).toBe(ZERO);
    expect(totals.freeShipping).toBe(false);
  });

  it("ignores zero-quantity lines", () => {
    const totals = evaluateCart([trouser("a", 2750, 0)], [STANDARD_OFFER]);
    expect(totals.subtotalMinor).toBe(ZERO);
  });

  it("rejects non-integer money at construction", () => {
    expect(() => minor(12.5)).toThrow(RangeError);
  });
});
