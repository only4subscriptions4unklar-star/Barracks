import { z } from "zod";
import { minor } from "@/lib/money";
import type { Promotion, PromotionRule } from "./types";

/**
 * Bridge between the `promotions` table and the pricing engine.
 *
 * `rule_config` is jsonb because each rule kind has a genuinely different shape.
 * That flexibility stops at this boundary: nothing reaches the engine without
 * passing the schema for its kind, so a malformed row written by a future admin
 * form fails loudly here instead of silently mispricing a cart.
 */

const minorUnits = z.number().int().nonnegative();

const ruleSchemas = {
  BUNDLE_FIXED_PRICE: z.object({
    quantity: z.number().int().min(2),
    bundlePriceMinor: minorUnits,
  }),
  PERCENT_OFF: z.object({ percent: z.number().min(0).max(100) }),
  FIXED_AMOUNT_OFF: z.object({ amountMinor: minorUnits }),
  SPEND_GET_AMOUNT_OFF: z.object({ minSpendMinor: minorUnits, amountMinor: minorUnits }),
  BUY_X_GET_Y_FREE: z.object({
    buyQuantity: z.number().int().min(1),
    freeQuantity: z.number().int().min(1),
  }),
  FREE_SHIPPING: z.object({ minSpendMinor: minorUnits }),
} as const;

export type PromotionRuleKind = keyof typeof ruleSchemas;

export function parseRule(kind: string, config: unknown): PromotionRule {
  const schema = ruleSchemas[kind as PromotionRuleKind];
  if (!schema) throw new Error(`Unknown promotion rule kind: ${kind}`);

  switch (kind as PromotionRuleKind) {
    case "BUNDLE_FIXED_PRICE": {
      const { quantity, bundlePriceMinor } = ruleSchemas.BUNDLE_FIXED_PRICE.parse(config);
      return { kind: "BUNDLE_FIXED_PRICE", quantity, bundlePriceMinor: minor(bundlePriceMinor) };
    }
    case "PERCENT_OFF":
      return { kind: "PERCENT_OFF", percent: ruleSchemas.PERCENT_OFF.parse(config).percent };
    case "FIXED_AMOUNT_OFF":
      return { kind: "FIXED_AMOUNT_OFF", amountMinor: minor(ruleSchemas.FIXED_AMOUNT_OFF.parse(config).amountMinor) };
    case "SPEND_GET_AMOUNT_OFF": {
      const parsed = ruleSchemas.SPEND_GET_AMOUNT_OFF.parse(config);
      return {
        kind: "SPEND_GET_AMOUNT_OFF",
        minSpendMinor: minor(parsed.minSpendMinor),
        amountMinor: minor(parsed.amountMinor),
      };
    }
    case "BUY_X_GET_Y_FREE": {
      const parsed = ruleSchemas.BUY_X_GET_Y_FREE.parse(config);
      return { kind: "BUY_X_GET_Y_FREE", ...parsed };
    }
    case "FREE_SHIPPING":
      return { kind: "FREE_SHIPPING", minSpendMinor: minor(ruleSchemas.FREE_SHIPPING.parse(config).minSpendMinor) };
  }
}

/** Shape of a `promotions` row joined with its eligibility tables. */
export interface PromotionRow {
  id: string;
  name: string;
  customer_message: string;
  rule_kind: string;
  rule_config: unknown;
  status: Promotion["status"];
  starts_at: string | null;
  ends_at: string | null;
  coupon_code: string | null;
  min_quantity: number | null;
  min_cart_value_minor: number | null;
  priority: number;
  stackable: boolean;
  product_ids?: string[] | null;
  collection_ids?: string[] | null;
  category_ids?: string[] | null;
}

export function toPromotion(row: PromotionRow): Promotion {
  return {
    id: row.id,
    name: row.name,
    customerMessage: row.customer_message,
    rule: parseRule(row.rule_kind, row.rule_config),
    eligibility: {
      productIds: row.product_ids ?? undefined,
      collectionIds: row.collection_ids ?? undefined,
      categoryIds: row.category_ids ?? undefined,
    },
    status: row.status,
    startsAt: row.starts_at ? new Date(row.starts_at) : null,
    endsAt: row.ends_at ? new Date(row.ends_at) : null,
    couponCode: row.coupon_code,
    minQuantity: row.min_quantity,
    minCartValueMinor: row.min_cart_value_minor === null ? null : minor(row.min_cart_value_minor),
    priority: row.priority,
    stackable: row.stackable,
  };
}
