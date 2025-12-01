# Inspectra System Setup Script
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "INSPECTRA DATABASE FIX & BACKEND STARTUP" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Set-Location C:\workshop2\Inspectra\backend

Write-Host "`n[Step 1/3] Recreating database tables..." -ForegroundColor Yellow
python -c "from db import engine; import models; models.Base.metadata.drop_all(bind=engine); models.Base.metadata.create_all(bind=engine); print('Tables created successfully')"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Database tables recreated" -ForegroundColor Green
} else {
    Write-Host "Failed to recreate tables" -ForegroundColor Red
    exit 1
}

Write-Host "`n[Step 2/3] Creating sample data..." -ForegroundColor Yellow
python create_sample_data.py

if ($LASTEXITCODE -eq 0) {
    Write-Host "Sample data created" -ForegroundColor Green
} else {
    Write-Host "Failed to create sample data" -ForegroundColor Red
    exit 1
}

Write-Host "`n[Step 3/3] Starting backend server..." -ForegroundColor Yellow
Write-Host "Backend URL: http://127.0.0.1:8000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server`n" -ForegroundColor Gray

python -m uvicorn main:app --reload --port 8000
