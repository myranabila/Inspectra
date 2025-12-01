from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from db import engine, Base
import models
from auth import router as auth_router
from dashboard import router as dashboard_router
from manager import router as manager_router
from messaging import router as messaging_router

app = FastAPI(title="Inspectra Backend API")

# Create database tables
Base.metadata.create_all(bind=engine)

# Add CORS middleware to allow requests from Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (for development)
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
)

app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(dashboard_router, prefix="/dashboard", tags=["Dashboard"])
app.include_router(manager_router, prefix="/manager", tags=["Manager"])
app.include_router(messaging_router, prefix="/messaging", tags=["Messaging & Reminders"])

@app.get("/health")
def health():
    return {"status": "ok"}
