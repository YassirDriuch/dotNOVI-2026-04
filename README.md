[![codecov](https://codecov.io/gh/YassirDriuch/dotNOVI-2026-04/branch/main/graph/badge.svg)](https://codecov.io/gh/YassirDriuch/dotNOVI-2026-04)
# dotNOVI Application

Een eenvoudige Node.js applicatie voor het NOVI Hogeschool DevOps cursus. Deze applicatie dient als basis voor het leren van DevOps-praktijken, inclusief containerisatie, CI/CD, en deployment.

## Wat is dotNOVI?

dotNOVI is een **student version** - een werkende applicatie zonder DevOps-configuratie. Studenten voegen containerisatie, CI/CD pipelines, en Kubernetes deployment zelf toe in de lessen.

## Functies

- **REST API** voor notitiemanagement (CRUD)
- **Web Interface** met EJS templates
- **PostgreSQL database** integratie
- **Health Check** endpoint voor monitoring
- **Gestructureerde tests** met Jest en Supertest
- **Code quality** tools (ESLint)

## Technologie Stack

- **Backend**: Node.js 20+ + Express
- **Database**: PostgreSQL
- **Frontend**: EJS templates (geen build step nodig)
- **Testing**: Jest + Supertest
- **Linting**: ESLint

## Installatie

### Lokaal Setup (zonder database)

```bash
# 1. Clone of download de applicatie
cd dotNOVI-2026-04

# 2. Installeer dependencies
npm install

# 3. Start de applicatie
npm run dev
```

De app draait op `http://localhost:3000`

### Met PostgreSQL Database

```bash
# 1. Installeer dependencies
npm install

# 2. Maak een .env bestand
cp .env.example .env

# 3. Update DATABASE_URL in .env
# Voorbeeld:
# DATABASE_URL=postgresql://user:password@localhost:5432/dotnovi

# 4. Maak de database aan
psql -U postgres -c "CREATE DATABASE dotnovi;"

# 5. Laad het schema
psql -U postgres -d dotnovi -f src/db/init.sql

# 6. Start de applicatie
npm run dev
```

## Beschikbare Scripts

```bash
# Development (met auto-reload)
npm run dev

# Production
npm start

# Tests
npm test

# Tests met watch mode
npm run test:watch

# Code quality check
npm run lint

# Fix linting issues
npm run lint:fix
```

## API Endpoints

### Notities Management

```bash
# Alle notities ophalen
GET /api/notes

# Specifieke notitie ophalen
GET /api/notes/:id

# Nieuwe notitie maken
POST /api/notes
Content-Type: application/json
{
  "title": "Mijn notitie",
  "content": "Dit is de inhoud"
}

# Notitie bijwerken
PUT /api/notes/:id
Content-Type: application/json
{
  "title": "Bijgewerkte titel",
  "content": "Bijgewerkte inhoud"
}

# Notitie verwijderen
DELETE /api/notes/:id
```

### Health Check

```bash
# Health status
GET /health
```

Respons:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00.000Z",
  "uptime": 123.456,
  "database": "connected"
}
```

## Environment Variabelen

| Variabele | Beschrijving | Default |
|-----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Development/production | development |
| `DATABASE_URL` | PostgreSQL connection string | (optioneel) |

## Database Schema

```sql
CREATE TABLE notes (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Testing

De applicatie bevat uitgebreide tests met Jest en Supertest.

```bash
# Run alle tests
npm test

# Tests met coverage rapportage
npm test -- --coverage

# Watch mode
npm run test:watch
```

## Structuur

```
dotNOVI-app/
├── src/
│   ├── index.js           # Main Express app
│   ├── db.js              # Database connection
│   ├── routes/
│   │   ├── health.js      # Health check route
│   │   └── notes.js       # Notes CRUD routes
│   ├── views/
│   │   ├── layout.ejs     # Base template
│   │   └── index.ejs      # Homepage
│   ├── public/
│   │   └── style.css      # Styling
│   └── db/
│       └── init.sql       # Database schema
├── tests/
│   ├── health.test.js
│   └── notes.test.js
├── package.json
├── .env.example
├── .gitignore
├── .eslintrc.json
└── jest.config.js
```

## Development Workflow

1. **Maak een notitie**:
   ```bash
   curl -X POST http://localhost:3000/api/notes \
     -H "Content-Type: application/json" \
     -d '{"title":"Test","content":"Dit is een test"}'
   ```

2. **Bekijk notities**:
   ```bash
   curl http://localhost:3000/api/notes
   ```

3. **Check health**:
   ```bash
   curl http://localhost:3000/health
   ```
