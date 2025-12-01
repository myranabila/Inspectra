@echo off
echo ============================================================
echo INSPECTRA SYSTEM SETUP
echo ============================================================

cd /d C:\workshop2\Inspectra\backend

echo.
echo [1/4] Recreating database tables...
python -c "from db import engine; import models; models.Base.metadata.drop_all(bind=engine); models.Base.metadata.create_all(bind=engine); print('Tables created')"

echo.
echo [2/4] Creating sample data...
python create_sample_data.py

echo.
echo [3/4] Testing messaging...
python test_messaging.py

echo.
echo [4/4] Starting backend server...
echo Backend will run on http://127.0.0.1:8000
echo Press Ctrl+C to stop
python -m uvicorn main:app --reload --port 8000
