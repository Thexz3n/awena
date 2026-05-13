# Signslator Backend (FastAPI + MySQL)

Production-ready REST API for the Signslator Flutter app.

## Features

- **JWT auth** — short-lived access tokens + rotating refresh tokens (stored hashed, revocable)
- **bcrypt** password hashing with strength rules (length + letter + digit)
- **MySQL** via SQLAlchemy 2.0 (utf8mb4 — full Unicode incl. Kurdish)
- **Rate limiting** on auth endpoints (SlowAPI)
- **CORS** configured per-environment
- **Strict validation** via Pydantic v2 (incl. email validator)
- **Auto-creates DB & tables** on first run — no manual SQL
- **Localization-ready** — users have a `language` field (`en` / `ckb`)
- **Translation history** — full CRUD + stats endpoint

## Requirements

- Python 3.10+
- MySQL 5.7+ / 8.0+ running locally (or remote)

## Quick start

```bash
cd backend

# 1. Create a virtual environment
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env
# Open .env and set DB_USER / DB_PASSWORD / SECRET_KEY

# Generate a strong SECRET_KEY:
python -c "import secrets; print(secrets.token_urlsafe(64))"

# 4. Run
python run.py
# or:  uvicorn app.main:app --reload
```

Backend now listens on `http://localhost:8000`.
Interactive docs: **http://localhost:8000/docs**

The database `signslator` and all tables are created automatically on first request.

## Endpoints (all prefixed with `/api/v1`)

### Auth
| Method | Path                       | Description                          |
| ------ | -------------------------- | ------------------------------------ |
| POST   | `/auth/signup`             | Register a new account               |
| POST   | `/auth/login`              | Login → access + refresh tokens      |
| POST   | `/auth/refresh`            | Rotate tokens                        |
| POST   | `/auth/logout`             | Revoke refresh tokens                |
| POST   | `/auth/forgot-password`    | Request reset token                  |
| POST   | `/auth/reset-password`     | Set new password using token         |

### Users
| Method | Path                  | Description                    |
| ------ | --------------------- | ------------------------------ |
| GET    | `/users/me`           | Get current user               |
| PATCH  | `/users/me`           | Update name / avatar / language|
| PATCH  | `/users/me/password`  | Change password                |
| DELETE | `/users/me`           | Delete account                 |

### History
| Method | Path                | Description                              |
| ------ | ------------------- | ---------------------------------------- |
| GET    | `/history`          | List (paginated, filterable, searchable) |
| POST   | `/history`          | Save an entry                            |
| GET    | `/history/stats`    | Aggregate stats                          |
| GET    | `/history/{id}`     | Get one entry                            |
| DELETE | `/history/{id}`     | Delete one entry                         |
| DELETE | `/history`          | Clear all                                |

All endpoints except `signup`, `login`, `refresh`, `forgot-password`, `reset-password` require a Bearer token:

```
Authorization: Bearer <access_token>
```

## Connecting from Flutter

In `lib/services/auth_service.dart`, use:

- **Android Emulator:** `http://10.0.2.2:8000/api/v1`
- **iOS Simulator:** `http://127.0.0.1:8000/api/v1`
- **Physical device on same Wi-Fi:** `http://<your-PC-LAN-IP>:8000/api/v1`

(Already configured in the updated `auth_service.dart` and `api_service.dart`.)

## Project structure

```
backend/
├── app/
│   ├── main.py              # FastAPI factory + lifespan
│   ├── config.py            # pydantic-settings
│   ├── database.py          # engine, session, init_db
│   ├── core/
│   │   ├── security.py      # bcrypt + JWT + token hashing
│   │   ├── dependencies.py  # get_current_user
│   │   └── limiter.py       # SlowAPI
│   ├── models/              # SQLAlchemy ORM
│   │   ├── user.py
│   │   ├── history.py
│   │   ├── password_reset.py
│   │   └── refresh_token.py
│   ├── schemas/             # Pydantic v2
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── history.py
│   │   └── common.py
│   ├── services/            # Business logic
│   │   ├── auth_service.py
│   │   ├── user_service.py
│   │   └── history_service.py
│   └── routers/             # HTTP routes
│       ├── auth.py
│       ├── users.py
│       └── history.py
├── .env / .env.example
├── requirements.txt
├── run.py
└── README.md
```

## Security checklist for production

- [ ] Replace `SECRET_KEY` with a long random value (≥ 64 chars)
- [ ] Set `DEBUG=False` and remove `reset_token` from forgot-password response
- [ ] Set `CORS_ORIGINS` to explicit domains, not `*`
- [ ] Run behind HTTPS (nginx / Caddy / a managed PaaS)
- [ ] Restrict the MySQL user's privileges
- [ ] Wire `forgot-password` to a real email provider (Mailgun / SendGrid / SES)
- [ ] Add monitoring & log aggregation
