/**
 * Money is stored and calculated exclusively in integer minor units (cents).
 *
 * Rationale: floating-point arithmetic cannot represent decimal currency exactly
 * (0.1 + 0.2 !== 0.3), and rounding drift in a cart or promotion calculation
 * becomes a real accounting discrepancy. Every price in the database is
 * `integer` minor units; formatting to a human-readable string happens only at
 * the presentation boundary.
 */

/** Sri Lankan Rupee, the only currency Barracks trades in today. */
export const CURRENCY = "LKR" as const;
const MINOR_UNITS_PER_MAJOR = 100;

/** Branded type so a raw number cannot be mistaken for a money value. */
export type Minor = number & { readonly __brand: "MinorUnits" };

export function minor(value: number): Minor {
  if (!Number.isFinite(value)) throw new RangeError(`Money must be finite, received ${value}`);
  if (!Number.isInteger(value)) throw new RangeError(`Money must be an integer in minor units, received ${value}`);
  return value as Minor;
}

/** Convert whole rupees (e.g. 2750) to minor units (275000). */
export function fromRupees(rupees: number): Minor {
  return minor(Math.round(rupees * MINOR_UNITS_PER_MAJOR));
}

export function add(...values: Minor[]): Minor {
  return minor(values.reduce<number>((sum, v) => sum + v, 0));
}

export function subtract(a: Minor, b: Minor): Minor {
  return minor(a - b);
}

export function multiply(value: Minor, quantity: number): Minor {
  if (!Number.isInteger(quantity) || quantity < 0) {
    throw new RangeError(`Quantity must be a non-negative integer, received ${quantity}`);
  }
  return minor(value * quantity);
}

/**
 * Percentage of a money value, rounded half-up to the nearest minor unit.
 * Half-up (rather than JS's banker-ish default on .5 for negatives) keeps
 * discounts predictable and reproducible between client preview and server.
 */
export function percentOf(value: Minor, percent: number): Minor {
  if (percent < 0 || percent > 100) {
    throw new RangeError(`Percent must be between 0 and 100, received ${percent}`);
  }
  return minor(Math.round((value * percent) / 100));
}

/** Never let a discount exceed the amount it applies to, or go negative. */
export function clamp(value: Minor, min: Minor, max: Minor): Minor {
  return minor(Math.min(Math.max(value, min), max));
}

export const ZERO = minor(0);

/**
 * Format for display, e.g. `Rs 2,750`.
 * Sub-rupee amounts are not part of Barracks pricing, so whole rupees are shown
 * unless the value genuinely carries cents.
 */
export function formatMoney(value: Minor, options: { withCents?: boolean } = {}): string {
  const major = value / MINOR_UNITS_PER_MAJOR;
  const hasCents = value % MINOR_UNITS_PER_MAJOR !== 0;
  const showCents = options.withCents ?? hasCents;
  return `Rs ${major.toLocaleString("en-LK", {
    minimumFractionDigits: showCents ? 2 : 0,
    maximumFractionDigits: showCents ? 2 : 0,
  })}`;
}

/** Split a discount across lines proportionally, distributing rounding remainder. */
export function allocateProportionally(total: Minor, weights: readonly Minor[]): Minor[] {
  const weightSum = weights.reduce<number>((sum, w) => sum + w, 0);
  if (weightSum <= 0 || total === 0) return weights.map(() => ZERO);

  const raw = weights.map((w) => Math.floor((total * w) / weightSum));
  let remainder = total - raw.reduce((sum, v) => sum + v, 0);

  // Hand the rounding remainder to the largest weights first, deterministically.
  const order = weights
    .map((w, index) => ({ w, index }))
    .sort((a, b) => b.w - a.w || a.index - b.index);

  const allocated = [...raw];
  for (const { index } of order) {
    if (remainder <= 0) break;
    allocated[index] += 1;
    remainder -= 1;
  }
  return allocated.map(minor);
}
