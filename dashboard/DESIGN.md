# Speedy Hub Dashboard — Design Direction (locked)

One direction: **ops console, not marketing page.**
References: Linear issue list density, Vercel deployment log restraint,
Stripe dashboard typography discipline. Nothing glows. Nothing floats.

## Tokens
- `--bg: #09090B` — page
- `--panel: #101014` — panels
- `--inset: #0C0C0F` — inputs, code blocks, table head
- `--line: #202027` — hairlines (grouping is spacing + hairlines, never shadows)
- `--text: #F4F4F5`, `--text-2: #A7A7B0`, `--text-3: #62626C`
- `--accent: #E5484D` — signal red. Actions and active states only.
  Never backgrounds, gradients, text fills, glows.
- `--ok: #46A758` — status text/dot only.

## Type
- Display/titles/stat numerals: **Space Grotesk**, 600, tracking -0.02em.
- Body/UI: **Inter**, 400/500/600 only.
- Data (IDs, timestamps, versions, code): **JetBrains Mono**, tabular.
- Page title 28px left-aligned. Section titles 13px semibold.
  Labels are 12px medium, normal case. No wide-tracked uppercase spam
  (one eyebrow per panel max, and only where it aids scanning).

## Shape & elevation
- Panel radius 10px, controls 8px, chips 6px, thumbnails 8px.
- No shadows. No glow. No glassmorphism. No gradients (except the
  chart area fill at 8% white, which is data ink, not decoration).
- Cards are borderless-separated by default: one 1px hairline panel,
  internal dividers `#1B1B21`. Hover = background `#141419` only.

## Motion
- No entrance animations. No fade-in-up. No shimmer. No pulse.
- Only transition: `background-color 120ms ease` on interactive rows.
- The status dot is static. It reports state; it does not decorate.

## Rules (anti-slop)
1. No purple/blue gradients, no gradient text, no orbs, no glow.
2. No `rounded-2xl shadow-lg` on everything; no glass panels.
3. No centered hero inside the tool. Every page: left title row,
   one primary action max, then the work surface.
4. No three-identical-icon-card row. Stats live in one divided strip.
5. No icon-in-a-rounded-square by reflex. Icons are 14–16px inline,
   `currentColor`, no containers.
6. No fake "Live / Monitoring / Secure / Systems Online" pills.
   Status lines state facts: "Updated just now · 5 executions today".
7. No `animate-pulse`, no shimmer, no hover lift/scale.
8. Accent red appears ≤3 times per viewport.
9. Empty states name the concrete next action with a button.
10. Numbers are tabular, units lighter than values.
