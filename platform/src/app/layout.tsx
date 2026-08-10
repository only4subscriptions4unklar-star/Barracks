import type { Metadata } from "next";
import { Cormorant_Garamond, Jost } from "next/font/google";
import "./globals.css";

/**
 * The two Barracks voices, carried over from the approved art direction:
 * a refined serif for editorial moments, a quiet sans for commerce and UI.
 */
const serif = Cormorant_Garamond({
  variable: "--font-serif",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
  style: ["normal", "italic"],
  display: "swap",
});

const sans = Jost({
  variable: "--font-sans",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600"],
  display: "swap",
});

export const metadata: Metadata = {
  title: {
    default: "Barracks — Fine Menswear of Kohuwala & Dehiwala",
    template: "%s — Barracks",
  },
  description:
    "Trousers, shirting and essentials cut for the island — Kohuwala & Dehiwala, delivered across Sri Lanka.",
  // Per-product pages override these, so a shared product link previews that
  // product rather than the homepage (brief §59).
  openGraph: {
    type: "website",
    siteName: "Barracks",
    locale: "en_LK",
  },
  twitter: { card: "summary_large_image" },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${serif.variable} ${sans.variable}`}>
      <body className="min-h-dvh bg-paper text-ink antialiased">{children}</body>
    </html>
  );
}
