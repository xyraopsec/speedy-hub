# Speedy Hub

Roblox script hub with hardware‑bound licensing and an automated Linkvertise key system.

**Live demo:**  
- Key site: [speedy-keys-eight.vercel.app](https://speedy-keys-eight.vercel.app)  
- Backend API: [dashboard-ten-peach-19.vercel.app](https://dashboard-ten-peach-19.vercel.app)

---

## Table of Contents

- [Architecture](#architecture)
- [Key System Flow](#key-system-flow)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Environment Variables](#environment-variables)
- [Deployment](#deployment)
- [Database](#database)
- [Roblox Loader](#roblox-loader)
- [License](#license)

---

## Architecture



---

## Key System Flow

1. **User opens key‑site** → fetches `GET /api/checkpoint` from backend.
2. **Backend generates a session** and builds a Linkvertise dynamic URL with a signed callback target:
   - `https://link-to.net/9061250/dynamic?r=<base64(https://dashboard/.../callback?token=...&sig=...)>`
3. **User completes the Linkvertise task** → Linkvertise automatically redirects to the callback endpoint.
4. **Callback validates the HMAC signature**, issues a 24‑hour key (64‑bit hex, e.g. `SPEEDY-XXXX-XXXX-XXXX-XXXX`), stores it in the database, and redirects back to key‑site with `?key=...`.
5. **Key‑site displays the key** and saves it to `localStorage` for persistence.
6. **Roblox Loader** calls `POST /api/keys/validate` with the key and HWID:
   - On first valid use, the key is bound to that HWID.
   - Subsequent checks require the same HWID.
   - Keys can have an execution limit (`maxExecutions`).
7. **Protected scripts** are served only after a valid key is presented.

---

## Project Structure



Generated directories (`.next`, `out`, `dist`) are ignored by Git.

---

## Setup & Installation

### Prerequisites

- Node.js ≥ 20
- npm or yarn
- PostgreSQL database (e.g., Neon, Supabase, or local)
- Vercel CLI (optional, for deployment)

### Steps

1. **Clone the repository**
   

2. **Install dependencies for both projects**
   

3. **Set up environment variables** (see [Environment Variables](#environment-variables))

4. **Set up the database**
   

5. **Run the development servers**
   

6. **Test the flow**  
   Visit `http://localhost:3001` – you should see the key redemption UI.

---

## Environment Variables

### Dashboard (`.env` in `dashboard/`)

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | PostgreSQL connection string |
| `NEXTAUTH_SECRET` | Used for HMAC signing (at least 32 chars) |
| `NEXT_PUBLIC_API_URL` | Optional, but used by key-site to point to the backend |

### Key‑site (`.env.local` in `key-site/`)

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_API_URL` | Backend URL (e.g., `https://dashboard-ten-peach-19.vercel.app`) |

---

## Deployment

Both projects are designed for Vercel. You can deploy them independently.

### Dashboard (API)



### Key‑site (Frontend)



### Monorepo Hint

If you deploy from the root, configure `vercel.json` to point each project to its own build directory.

---

## Database

Prisma is used with PostgreSQL. The schema defines:

- `LicenseKey` – stored keys with HWID, expiration, usage count, and activity flag.
- `KeySession` – tracks checkpoint sessions (IP, token, completion, issued key).

### Common commands



---

## Roblox Loader

`Loader.lua` is the entry point for the Roblox executor. It:

- Detects HWID via various executor APIs.
- Reads a saved key from `speedy_hub_key.txt` (using `readfile`/`writefile`).
- Validates the key with the backend (`POST /api/keys/validate`).
- If valid, loads the appropriate game script (from `GameTemplate.lua`) and renders the UI.

Key persistence across sessions is handled by file I/O (where supported).

---

## License

This project is proprietary and intended for internal use only.  
All rights reserved.

---

## Contributing

Internal contributions are welcome. Please open an issue or pull request on the repository. Ensure you follow the existing code style and update tests where applicable.

---

## Support

- Discord: [discord.gg/speedy](https://discord.gg/speedy)
- GitHub Issues: [xyraopsec/speedy-hub/issues](https://github.com/xyraopsec/speedy-hub/issues)

---

**Built with ❤️ for the Speedy Hub community.**