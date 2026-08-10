import type { Minor } from "@/lib/money";

/**
 * Promotion rules are DATA, not code.
 *
 * The Barracks "Standard Offer" (any two eligible trousers for Rs 5,000) is one
 * row in the `promotions` table using the BUNDLE_FIXED_PRICE rule — not a
 * special case in a component. The owner can create, schedule and retire
 * promotions from Admin without a developer, which is requirement §12/§39 of
 * the brief.
 */
export type PromotionRule =
  /** N eligible units for one fixed price. The Standard Offer. */
  | { kind: "BUNDLE_FIXED_PRICE"; quantity: number; bundlePriceMinor: Minor }
  /** Percentage off every eligible unit. */
  | { kind: "PERCENT_OFF"; percent: number }
  /** Flat amount off the eligible subtotal. */
  | { kind: "FIXED_AMOUNT_OFF"; amountMinor: Minor }
  /** Spend at least X across eligible items, take Y off. */
  | { kind: "SPEND_GET_AMOUNT_OFF"; minSpendMinor: Minor; amountMinor: Minor }
  /** Buy X eligible units, the cheapest Y are free. */
  | { kind: "BUY_X_GET_Y_FREE"; buyQuantity: number; freeQuantity: number }
  /** Waives delivery once the cart subtotal reaches the threshold. */
  | { kind: "FREE_SHIPPING"; minSpendMinor: Minor };

export type PromotionStatus = "DRAFT" | "SCHEDULED" | "ACTIVE" | "PAUSED" | "EXPIRED" | "ARCHIVED";

/** Which lines a promotion may touch. An empty selection means "everything". */
export interface PromotionEligibility {
  productIds?: readonly string[];
  collectionIds?: readonly string[];
  categoryIds?: readonly string[];
}

export interface Promotion {
  id: string;
  name: string;
  /** Shown to the customer, e.g. "Any two trousers · Rs 5,000". */
  customerMessage: string;
  rule: PromotionRule;
  eligibility: PromotionEligibility;
  status: PromotionStatus;
  startsAt: Date | null;
  endsAt: Date | null;
  /** When set, the promotion only applies if the customer supplies this code. */
  couponCode: string | null;
  /** Minimum eligible units required before the rule engages. */
  minQuantity: number | null;
  /** Minimum cart subtotal required before the rule engages. */
  minCartValueMinor: Minor | null;
  /** Lower number wins when promotions compete for the same line. */
  priority: number;
  /** When false, this promotion claims its lines exclusively. */
  stackable: boolean;
}

/** A cart line as the engine sees it — already priced, no product lookup needed. */
export interface CartLine {
  /** Stable identifier for the line (variant/size combination). */
  id: string;
  productId: string;
  collectionIds: readonly string[];
  categoryId: string | null;
  unitPriceMinor: Minor;
  quantity: number;
  /** Products the owner has excluded from all promotions. */
  promotionEligible: boolean;
}

export interface AppliedPromotion {
  promotionId: string;
  name: string;
  customerMessage: string;
  /** Total discount this promotion contributed, in minor units. */
  discountMinor: Minor;
  /** How many times a repeatable rule (e.g. a bundle) fired. */
  timesApplied: number;
  freeShipping: boolean;
}

export interface CartTotals {
  /** Sum of every line before any discount. */
  subtotalMinor: Minor;
  /** Sum of all promotion discounts. */
  discountMinor: Minor;
  /** subtotal − discount, never below zero. */
  totalMinor: Minor;
  /** Per-line discount allocation, keyed by CartLine.id — used for display. */
  lineDiscountsMinor: Readonly<Record<string, Minor>>;
  appliedPromotions: readonly AppliedPromotion[];
  freeShipping: boolean;
}
