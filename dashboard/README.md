# Speedy Hub — Dashboard (Black & White)

Research-backed: Vercel monochrome system (AdminLTE 2026: "color = meaning") + shadcn/ui dark-first (Linear/Supabase/Vercel) + Tailwind v4 OKLCH.

## Stack (per web research)
- **Next.js 15 App Router** (Vercel native)
- **Prisma Postgres** via Vercel Marketplace (vercel.com/kb/guide/nextjs-prisma-postgres)
- **shadcn/ui + Tailwind** monochrome: bg `#08080A`, card `#111113`, border `#242428`, text white, accent red only semantic
- **Recharts** for executions

## Quick start (local)
```bash
cd dashboard
npm install
cp .env.example .env.local  # fill from Vercel Storage tab
npx prisma db push
npm run dev
```

## Deploy to Vercel + GitHub
1. Push `dashboard/` to GitHub repo root or subdir.
2. Vercel → New Project → Import GitHub repo → Framework: Next.js.
3. Storage → Connect Database → Prisma Postgres → creates `DATABASE_URL`.
4. `vercel env pull .env` locally, then `npx prisma db push`.
5. Seed 20 games:
```bash
npx prisma studio # or run seed script
# seed uses Games table from Loader.lua universeIds
```
6. Each push to `main` auto-deploys.

## Loader integration
`Loader.lua` Hit click (after Phase2 fade):
```lua
pcall(function()
  game:HttpGet("https://YOUR_VERCEL.vercel.app/api/executions", { } ) -- not needed
  -- instead POST:
  local HttpService = game:GetService("HttpService")
  request({
    Url = "https://YOUR_VERCEL.vercel.app/api/executions",
    Method = "POST",
    Headers = { ["Content-Type"]="application/json" },
    Body = HttpService:JSONEncode({ universeId=tostring(game.GameId), placeId=tostring(game.PlaceId), userId=tostring(game.Players.LocalPlayer.UserId) })
  })
  -- fetch script
  local code = game:HttpGet("https://YOUR_VERCEL.vercel.app/api/scripts?universeId="..game.GameId)
  loadstring(code)()
end)
```

## API
- `GET /api/scripts?universeId=...` → `{ game, version, code }`
- `POST /api/scripts` → create version
- `POST /api/executions` → logs + increments
- `GET /api/executions?take=50` → recent logs

## Design notes (research)
- Vercel: monochrome where hierarchy = spacing + weight, reserve green/amber/red for status.
- shadcn/ui: vendored primitives, tabular numbers `mono`, muted gridlines, one hero chart.
- Dark-first: design dark then light second.

## TODO
- Add NextAuth (Vercel Auth) to protect /scripts POST
- Add TanStack Table for executions with filters
- Add Cron to purge old executions
