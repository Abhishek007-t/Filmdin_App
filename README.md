# Filmdin Project

Monorepo with a clean separation between frontend and backend code.

## Project Structure

```text
Filmdin_App/
	frontend/
		filmdin/          # Flutter application
	backend/            # Node.js + Express API
	design/             # Design assets
	docs/               # Documentation
```

## Run Frontend (Flutter)

```bash
cd frontend/filmdin
flutter pub get
flutter run
```

## Run Backend (Node.js)

```bash
cd backend
npm install
npm run dev
```

## Notes

- Backend deployment config is under `backend/nixpacks.toml` and `backend/railway.toml`.
- Root-level duplicate backend files were removed to avoid split sources of truth.