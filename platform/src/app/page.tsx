/**
 * Placeholder root route.
 *
 * The storefront is rebuilt in Phase 8–9; this exists so the app compiles and
 * deploys from Phase 2 onward. It is intentionally not a fake homepage.
 */
export default function Home() {
  return (
    <main className="mx-auto flex min-h-dvh max-w-(--container-shell) flex-col justify-center px-(--spacing-gutter)">
      <span className="label text-olive">Barracks Commerce OS</span>
      <h1 className="mt-4 text-(length:--text-h1)">Foundations in place.</h1>
      <p className="mt-4 max-w-prose text-ink-2">
        Database schema, row-level security, seeded catalogue and the promotion
        engine are built and tested. The storefront and admin interfaces follow
        in the next phases.
      </p>
    </main>
  );
}
