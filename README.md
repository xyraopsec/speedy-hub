<p align="center">
  <img src="https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/logo.png" width="120" alt="Speedy Hub logo" />
</p>

<h1 align="center">SPEEDY HUB</h1>

<p align="center">
  <b>Car & motorcycle script hub for Roblox — loader, backend dashboard, and a shared UI library.</b><br />
  One look everywhere: red bars, frosted glass, live execution tracking.
</p>

<p align="center">
  <a href="https://dashboard-ten-peach-19.vercel.app"><img src="https://img.shields.io/badge/dashboard-live-ff1a1a?style=flat-square" alt="dashboard" /></a>
  <img src="https://img.shields.io/badge/Luau-2C2D34?style=flat-square&logo=lua" alt="Luau" />
  <img src="https://img.shields.io/badge/Next.js_15-black?style=flat-square&logo=next.js" alt="Next.js" />
  <img src="https://img.shields.io/badge/Prisma_Postgres-2D3748?style=flat-square&logo=prisma" alt="Prisma" />
  <img src="https://img.shields.io/badge/license-MIT-999?style=flat-square" alt="MIT" />
</p>

---

## Run it

**1. Loader** — game picker + auto-updates, powered by the dashboard backend:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/Loader.lua"))()
```

**2. Production UI library** — macOS glass, traffic lights, toggles/sliders/dropdowns/keybinds, notifications:

```lua
local SpeedyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/xyraopsec/speedy-hub/master/SpeedyUI.lua"))()
local Window = SpeedyUI:CreateWindow({ Title = "Speedy Hub", SubTitle = "Driving Empire" })
local Tab = Window:AddTab("Home")
Tab:AddToggle({ Title = "Auto Farm", Callback = function(v) print(v) end })
```

**3. Dashboard** — deploy payloads, watch executions roll in: [dashboard-ten-peach-19.vercel.app](https://dashboard-ten-peach-19.vercel.app)

---

## What's inside

| Piece | What it does |
|---|---|
| `Loader.lua` | Animated logo intro → loading bar → backend-driven game grid. Fetches games from `/api/games`, logs every run to `/api/executions`, then loads that game's payload from `/api/scripts`. |
| `dashboard/` | Next.js 15 + Prisma Postgres ops console. Deploy Lua payloads per universe, browse the execution log with Roblox avatars + game thumbnails, 7-day volume chart, per-game distribution. |
| `SpeedyUI.lua` | Single-file interface library every game script shares: frosted window, sidebar tabs, button / toggle / slider / dropdown / input / keybind, toasts, RightShift hide, mobile + touch support. |
| `SpeedyUI_Example.lua` | Copy-paste starter showing every element. |
| `Main.lua` | Legacy per-game template (Fluent-based, kept for reference). |

Check the **`test` branch** for experiments: `veryud` / `veryudfix` glass redesigns, `MacGlass` dark-glass lib, `MacLibLight` white-mode MacLib conversion, and the Speedy-branded SerhiiUI showcase — each with its own `_Test.lua` loadstring.

---

## Dashboard

```
Overview    → total / today / active scripts / games · 7-day volume · top games
Scripts     → deploy payload (universe ID + Lua) · edit · version · activate/archive · delete
Executions  → live log: game icon · user avatar · version · executor · IP
```

Stack: Next.js App Router, Tailwind, Recharts, Prisma + Postgres (Prisma Data Platform), deployed on Vercel. Design tokens are locked in [`dashboard/DESIGN.md`](dashboard/DESIGN.md) — one accent red, Space Grotesk display type, hairlines instead of shadows, zero AI-slop gradients.

Local dev:

```bash
cd dashboard
npm install
npx prisma db push
npm run dev
```

---

## UI library API (production)

```lua
local Window = SpeedyUI:CreateWindow({
  Title = "Speedy Hub", SubTitle = "Greenville",
  Size = UDim2.fromOffset(560, 420),
  ToggleKey = Enum.KeyCode.RightShift,
})

local Tab = Window:AddTab("Farm")
Tab:AddSection("Performance")
Tab:AddToggle({ Title = "Auto Drive", Description = "...", Callback = function(v) end })  -- :Set(bool)
Tab:AddSlider({ Title = "Speed", Min = 50, Max = 300, Default = 150, Callback = function(v) end })  -- :Set(n)
Tab:AddDropdown({ Title = "Engine", Options = { "Stock", "Sport" }, Callback = function(v) end })  -- :Set(v) :Refresh(t)
Tab:AddInput({ Title = "Waypoint", Placeholder = "...", Callback = function(text, enter) end })
Tab:AddKeybind({ Title = "Panic", Default = Enum.KeyCode.F, Callback = function() end })
Tab:AddButton({ Title = "Unload", Callback = function() Window:Destroy() end })

SpeedyUI:Notify({ Title = "Speedy", Content = "Loaded!", Duration = 4 })
Window:SelectTab(1)  Window:Toggle()  Window:Destroy()
```

---

## Structure

```
speedy-hub/
├── Loader.lua            # game picker + backend handoff (production)
├── SpeedyUI.lua          # shared interface library (production)
├── SpeedyUI_Example.lua  # starter template
├── Main.lua              # legacy template (reference)
├── dashboard/            # Next.js ops console (deploys to Vercel)
├── icon.png logo.png     # brand assets
├── deploy.ps1 / push.ps1 # one-key deploy helpers
└── vercel.json
```

`master` = production. `test` = UI experiments (never merge blindly).

---

## Contributing

1. Build on `test`, demo with a `_Test.lua` loadstring, screenshot it in-game.
2. Keep the look: frosted dark glass, Speedy red `#FF1A1A` accents only, Gotham type, Back-ease motion.
3. PR to `master` with the screenshot attached.

Discord: **discord.gg/speedy** · License: MIT
