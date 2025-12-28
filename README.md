# Inspectra

A Flutter application with a Python/FastAPI backend for inspection reporting.

## Getting Started

### Prerequisites
- Python 3.x
- Flutter SDK

### 1. Start the Backend
The backend handles the database and API.

1. Open a terminal (PowerShell recommended).
2. Navigate to the `backend` directory:
   ```powershell
   cd backend
   ```
3. Run the startup script:
   ```powershell
   .\start.ps1
   ```
   This script will:
   - Create the database and tables.
   - Seed sample data (users, inspections, reports).
   - Start the server at `http://127.0.0.1:8000`.

**Note:** The valid users created are:
- Manager: `manager` (password: `manager123`)
- Inspectors: `adam`, `ali`, `abu` (password: `[username]123`)

### 2. Run the Mobile/Desktop App
Once the backend is running:

1. Open a **new** terminal window.
2. Navigate to the project root.
3. Run the Flutter app:
   ```bash
   flutter run
   ```
   Or targeting Windows specifically:
   ```bash
   flutter run -d windows
   ```

## Project Structure
- `backend/`: Python FastAPI backend.
- `lib/`: Flutter application code.

