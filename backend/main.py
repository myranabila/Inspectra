from db import engine, Base
import models
from auth import router as auth_router

Base.metadata.create_all(bind=engine)

from fastapi import FastAPI

app = FastAPI(title="Inspectra Backend API")

app.include_router(auth_router, prefix="/auth", tags=["Authentication"])

@app.get("/health")
def health():
    return {"status": "ok"}
