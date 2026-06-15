# Les 1: DevOps Fundamentals

## Doelstellingen

In deze les leer je:
- Wat DevOps is en waarom het bestaat
- De DevOps lifecycle en tooling
- CALMS-framework en The Three Ways
- Branching strategieën voor DevOps (GitHub Flow, Git Flow, Trunk-Based)
- Conventionele commits

## Branching Strategieën

### GitHub Flow

De eenvoudigste strategie, perfect voor continuous deployment:

```
main ──●──────●──────●──────●──── (altijd deploybaar)
        \          /
         ●──●──●──  feature/add-about-page
```

**Werkwijze:**
1. Branch van main
2. Maak je wijzigingen
3. Open een Pull Request
4. Review en merge naar main

```bash
# Creëer feature branch
git checkout -b feature/add-about-page

# Maak wijzigingen en commit met conventionele commits
git add .
git commit -m "feat: add about endpoint"
git push origin feature/add-about-page

# Open PR op GitHub → review → merge
```

### Git Flow

Gestructureerder, voor teams met geplande releases:

**Branches:**
- `main` - Production ready code
- `develop` - Integration branch
- `feature/*` - Feature development
- `release/*` - Release preparation
- `hotfix/*` - Production fixes

```bash
# Feature branch van develop
git checkout develop
git checkout -b feature/add-categories

# Na voltooiing: PR naar develop
# Later: develop → release branch → main
```

### Trunk-Based Development

Voor teams met sterke CI/CD en test coverage:
- Iedereen werkt op `main`
- Zeer korte feature branches (max 1-2 dagen)
- Feature flags i.p.v. lange branches
- Vereist: goede tests en CI pipeline

## Conventionele Commits

```bash
# Format: <type>(<scope>): <description>

git commit -m "feat(notes): add priority field to notes table"
git commit -m "fix(api): handle null values in title"
git commit -m "docs(readme): add installation steps"
git commit -m "test(notes): add tests for priority filtering"
git commit -m "chore(deps): upgrade express to 4.19.0"
```

**Types:**
- `feat` — nieuwe feature
- `fix` — bugfix
- `docs` — documentatie
- `test` — tests toevoegen/wijzigen
- `chore` — onderhoud (dependencies, config)
- `refactor` — code verbeteren zonder gedragswijziging

## Branch Naming

```
feature/short-description     # Nieuwe feature
bugfix/description-of-fix     # Bug fix
docs/update-readme            # Documentatie
refactor/improve-performance  # Code improvements
test/add-integration-tests    # Tests
```

## Opdrachten

### Opdracht 1: dotNOVI installeren & verkennen

```bash
# Fork de repo op GitHub, dan:
git clone <jouw-fork-url>
cd dotnovi-student
npm install
npm start

# App draait op http://localhost:3000
# Verken de endpoints en check health:
curl http://localhost:3000/health
```

Verkenningsvraag: wat ontbreekt er qua DevOps?

### Opdracht 2: GitHub Flow in de praktijk

```bash
# Feature branch aanmaken
git checkout -b feature/add-about-page

# Voeg een /about route toe aan de app
# (bijv. in src/index.js)

# Commit met conventionele commit message
git add .
git commit -m "feat: add about endpoint"

# Push en open PR op GitHub
git push origin feature/add-about-page
```

Op GitHub:
1. Open een Pull Request (feature → main)
2. Schrijf een duidelijke beschrijving: wat, waarom, hoe te testen
3. Merge de PR

### Opdracht 3: DevOps-plan schetsen

Schets een eerste DevOps-plan voor dotNOVI:
- Kies per lifecycle-fase een tool
- Beschrijf in 1-2 zinnen per fase wat je daar gaat doen
- Kies een branching strategie en beschrijf waarom
- Dit wordt de basis voor je eindopdracht (deelopdracht 1)

### Opdracht 4: Security awareness

```bash
# Controleer .gitignore
cat .gitignore
# Staan node_modules/, .env en .DS_Store erin?

# Maak een dummy .env
echo "DATABASE_PASSWORD=geheim123" > .env

# Wat gebeurt er als je dit probeert te committen?
git add .env
# (Hint: .gitignore blokkeert dit als het goed staat)
```

Zoek op: hoe kun je een per ongeluk gecommit secret ongedaan maken?

## Pull Request Template

```markdown
## Beschrijving
Wat heb je veranderd en waarom?

## Type wijziging
- [ ] Feature
- [ ] Bug fix
- [ ] Documentatie

## Hoe te testen
Stappen om de wijziging te testen

## Checklist
- [ ] Code volgt de style guidelines
- [ ] Conventionele commit message gebruikt
- [ ] Geen nieuwe warnings
```

## Volgende Les

In les 2 gaan we:
- Docker introduceren
- Containerisatie begrijpen
- Een Dockerfile schrijven voor dotNOVI

## Resources

- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Git Flow Cheatsheet](https://danielkummer.github.io/git-flow-cheatsheet/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [State of DevOps Report](https://dora.dev/research/)
