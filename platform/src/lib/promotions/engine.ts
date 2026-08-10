import {
  ZERO,
  add,
  allocateProportionally,
  clamp,
  minor,
  multiply,
  percentOf,
  subtract,
  type Minor,
} from "@/lib/money";
import type {
  AppliedPromotion,
  CartLine,
  CartTotals,
  Promotion,
  PromotionEligibility,
} from "./types";

/**
 * The single source of truth for what a Barracks cart costs.
 *
 * This module is deliberately pure: no database, no network, no clock of its
 * own. The server calls it during checkout with a trusted `now` and trusted
 * prices read from the database; the browser calls it with the same inputs
 * purely to render an instant preview. Because both sides run identical code,
 * the preview matches the charge — but only the server's result is ever
 * authoritative (brief §79).
 */

export interface EvaluateOptions {
  /** Evaluation time — injected so scheduling is testable and server-controlled. */
  now?: Date;
  /** Coupon the customer supplied, if any. */
  couponCode?: string | null;
}

/** A single promotable unit. Bundles reason about units, not lines. */
interface Unit {
  lineId: string;
  priceMinor: Minor;
}

export function evaluateCart(
  lines: readonly CartLine[],
  promotions: readonly Promotion[],
  options: EvaluateOptions = {},
): CartTotals {
  const now = options.now ?? new Date();
  const coupon = options.couponCode?.trim().toUpperCase() || null;

  const subtotalMinor = lines.reduce<Minor>(
    (sum, line) => add(sum, multiply(line.unitPriceMinor, line.quantity)),
    ZERO,
  );

  const lineDiscounts = new Map<string, number>();
  const applied: AppliedPromotion[] = [];
  /** Lines claimed by a non-stackable promotion; no later rule may touch them. */
  const claimedLines = new Set<string>();
  let freeShipping = false;

  const live = promotions
    .filter((promotion) => isLive(promotion, now, coupon))
    .sort((a, b) => a.priority - b.priority || a.id.localeCompare(b.id));

  for (const promotion of live) {
    const eligible = lines.filter(
      (line) =>
        line.promotionEligible &&
        line.quantity > 0 &&
        !claimedLines.has(line.id) &&
        matchesEligibility(line, promotion.eligibility),
    );

    if (eligible.length === 0 && promotion.rule.kind !== "FREE_SHIPPING") continue;

    const eligibleQuantity = eligible.reduce((sum, line) => sum + line.quantity, 0);
    const eligibleSubtotal = eligible.reduce<Minor>(
      (sum, line) => add(sum, multiply(line.unitPriceMinor, line.quantity)),
      ZERO,
    );

    if (promotion.minQuantity !== null && eligibleQuantity < promotion.minQuantity) continue;
    if (promotion.minCartValueMinor !== null && subtotalMinor < promotion.minCartValueMinor) continue;

    const outcome = applyRule(promotion, eligible, eligibleSubtotal, subtotalMinor);
    if (!outcome) continue;

    if (outcome.freeShipping) freeShipping = true;

    if (outcome.discountMinor > 0) {
      for (const [lineId, amount] of outcome.perLine) {
        lineDiscounts.set(lineId, (lineDiscounts.get(lineId) ?? 0) + amount);
      }
    }

    if (outcome.discountMinor > 0 || outcome.freeShipping) {
      applied.push({
        promotionId: promotion.id,
        name: promotion.name,
        customerMessage: promotion.customerMessage,
        discountMinor: outcome.discountMinor,
        timesApplied: outcome.timesApplied,
        freeShipping: outcome.freeShipping,
      });

      if (!promotion.stackable) {
        for (const line of eligible) claimedLines.add(line.id);
      }
    }
  }

  const discountMinor = clamp(
    minor([...lineDiscounts.values()].reduce((sum, v) => sum + v, 0)),
    ZERO,
    subtotalMinor,
  );

  const lineDiscountsMinor: Record<string, Minor> = {};
  for (const [lineId, amount] of lineDiscounts) lineDiscountsMinor[lineId] = minor(amount);

  return {
    subtotalMinor,
    discountMinor,
    totalMinor: subtract(subtotalMinor, discountMinor),
    lineDiscountsMinor,
    appliedPromotions: applied,
    freeShipping,
  };
}

/** Status, schedule window and coupon gate. */
function isLive(promotion: Promotion, now: Date, coupon: string | null): boolean {
  if (promotion.status !== "ACTIVE") return false;
  if (promotion.startsAt && now < promotion.startsAt) return false;
  if (promotion.endsAt && now > promotion.endsAt) return false;
  if (promotion.couponCode) {
    return coupon !== null && coupon === promotion.couponCode.trim().toUpperCase();
  }
  return true;
}

function matchesEligibility(line: CartLine, eligibility: PromotionEligibility): boolean {
  const { productIds, collectionIds, categoryIds } = eligibility;
  const unscoped =
    !productIds?.length && !collectionIds?.length && !categoryIds?.length;
  if (unscoped) return true;

  if (productIds?.includes(line.productId)) return true;
  if (categoryIds?.length && line.categoryId && categoryIds.includes(line.categoryId)) return true;
  if (collectionIds?.some((id) => line.collectionIds.includes(id))) return true;
  return false;
}

interface RuleOutcome {
  discountMinor: Minor;
  perLine: ReadonlyArray<readonly [string, number]>;
  timesApplied: number;
  freeShipping: boolean;
}

function applyRule(
  promotion: Promotion,
  eligible: readonly CartLine[],
  eligibleSubtotal: Minor,
  cartSubtotal: Minor,
): RuleOutcome | null {
  const rule = promotion.rule;

  switch (rule.kind) {
    case "BUNDLE_FIXED_PRICE": {
      if (rule.quantity < 2) return null;
      const units = expandUnits(eligible);
      const groups = chunk(units, rule.quantity);
      let total = 0;
      let timesApplied = 0;
      const perLine = new Map<string, number>();

      for (const group of groups) {
        if (group.length < rule.quantity) break; // partial group pays full price
        const groupSum = group.reduce<number>((sum, unit) => sum + unit.priceMinor, 0);
        // A bundle must never *raise* the price: two Rs 2,000 trousers under a
        // Rs 5,000 bundle stay at Rs 4,000.
        const discount = Math.max(0, groupSum - rule.bundlePriceMinor);
        if (discount === 0) continue;
        total += discount;
        timesApplied += 1;
        distribute(perLine, group, discount);
      }
      if (total === 0) return null;
      return { discountMinor: minor(total), perLine: [...perLine], timesApplied, freeShipping: false };
    }

    case "PERCENT_OFF": {
      const perLine = new Map<string, number>();
      let total = 0;
      for (const line of eligible) {
        const lineTotal = multiply(line.unitPriceMinor, line.quantity);
        const discount = percentOf(lineTotal, rule.percent);
        if (discount === 0) continue;
        total += discount;
        perLine.set(line.id, (perLine.get(line.id) ?? 0) + discount);
      }
      if (total === 0) return null;
      return { discountMinor: minor(total), perLine: [...perLine], timesApplied: 1, freeShipping: false };
    }

    case "FIXED_AMOUNT_OFF": {
      const discount = clamp(rule.amountMinor, ZERO, eligibleSubtotal);
      if (discount === 0) return null;
      return {
        discountMinor: discount,
        perLine: spreadAcrossLines(eligible, discount),
        timesApplied: 1,
        freeShipping: false,
      };
    }

    case "SPEND_GET_AMOUNT_OFF": {
      if (cartSubtotal < rule.minSpendMinor) return null;
      const discount = clamp(rule.amountMinor, ZERO, eligibleSubtotal);
      if (discount === 0) return null;
      return {
        discountMinor: discount,
        perLine: spreadAcrossLines(eligible, discount),
        timesApplied: 1,
        freeShipping: false,
      };
    }

    case "BUY_X_GET_Y_FREE": {
      if (rule.buyQuantity < 1 || rule.freeQuantity < 1) return null;
      const groupSize = rule.buyQuantity + rule.freeQuantity;
      const units = expandUnits(eligible);
      const groups = chunk(units, groupSize);
      let total = 0;
      let timesApplied = 0;
      const perLine = new Map<string, number>();

      for (const group of groups) {
        if (group.length < groupSize) break;
        // Cheapest units in the group are the free ones.
        const cheapest = [...group].sort((a, b) => a.priceMinor - b.priceMinor).slice(0, rule.freeQuantity);
        const discount = cheapest.reduce<number>((sum, unit) => sum + unit.priceMinor, 0);
        if (discount === 0) continue;
        total += discount;
        timesApplied += 1;
        for (const unit of cheapest) {
          perLine.set(unit.lineId, (perLine.get(unit.lineId) ?? 0) + unit.priceMinor);
        }
      }
      if (total === 0) return null;
      return { discountMinor: minor(total), perLine: [...perLine], timesApplied, freeShipping: false };
    }

    case "FREE_SHIPPING": {
      if (cartSubtotal < rule.minSpendMinor) return null;
      return { discountMinor: ZERO, perLine: [], timesApplied: 1, freeShipping: true };
    }
  }
}

/** Expand lines into individual units, most expensive first.
 *
 * Descending order is what makes the Standard Offer generous in the customer's
 * favour: with trousers at 3,200 / 2,950 / 2,750 the bundle pairs the two
 * dearest (saving 1,150) rather than any cheaper combination.
 */
function expandUnits(lines: readonly CartLine[]): Unit[] {
  const units: Unit[] = [];
  for (const line of lines) {
    for (let i = 0; i < line.quantity; i += 1) {
      units.push({ lineId: line.id, priceMinor: line.unitPriceMinor });
    }
  }
  return units.sort((a, b) => b.priceMinor - a.priceMinor || a.lineId.localeCompare(b.lineId));
}

function chunk<T>(items: readonly T[], size: number): T[][] {
  const groups: T[][] = [];
  for (let i = 0; i < items.length; i += size) groups.push(items.slice(i, i + size));
  return groups;
}

/** Attribute a group discount back to the lines those units came from. */
function distribute(target: Map<string, number>, group: readonly Unit[], discount: number): void {
  const weights = group.map((unit) => unit.priceMinor);
  const shares = allocateProportionally(minor(discount), weights);
  group.forEach((unit, index) => {
    target.set(unit.lineId, (target.get(unit.lineId) ?? 0) + shares[index]);
  });
}

function spreadAcrossLines(
  lines: readonly CartLine[],
  discount: Minor,
): ReadonlyArray<readonly [string, number]> {
  const weights = lines.map((line) => multiply(line.unitPriceMinor, line.quantity));
  const shares = allocateProportionally(discount, weights);
  return lines.map((line, index) => [line.id, shares[index]] as const);
}
