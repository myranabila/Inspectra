from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from db import engine, Base, get_db
import models
from auth import router as auth_router
from dashboard import router as dashboard_router
from manager import router as manager_router
from messaging import router as messaging_router
from locations import router as locations_router
from profile import router as profile_router
from report import router as report_router

app = FastAPI(title="Inspection System API")

# Create database tables
Base.metadata.create_all(bind=engine)

# Initialize default locations
def init_default_locations():
    db = next(get_db())
    try:
        # Check if locations table is empty
        count = db.query(models.Location).count()
        if count == 0:
            # Add some default locations
            default_locations = [
                {"name": "Building A - Floor 1", "description": "Ground floor of Building A"},
                {"name": "Building A - Floor 2", "description": "Second floor of Building A"},
                {"name": "Building A - Floor 3", "description": "Third floor of Building A"},
                {"name": "Building B - Floor 1", "description": "Ground floor of Building B"},
                {"name": "Building B - Floor 2", "description": "Second floor of Building B"},
                {"name": "Parking Area", "description": "Main parking lot"},
                {"name": "Roof Access", "description": "Roof and rooftop equipment"},
                {"name": "Basement", "description": "Underground basement area"},
            ]
            
            for loc_data in default_locations:
                location = models.Location(**loc_data, is_active=1)
                db.add(location)
            
            db.commit()
            print("✓ Default locations initialized")
    except Exception as e:
        print(f"Error initializing locations: {e}")
        db.rollback()
    finally:
        db.close()

# Initialize default data
init_default_locations()

# Add CORS middleware to allow requests from Flutter web app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins (for development)
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],  # Allow all headers
    expose_headers=["*"],  # Expose all headers
)

app.include_router(auth_router, prefix="/auth", tags=["Authentication"])
app.include_router(dashboard_router, prefix="/dashboard", tags=["Dashboard"])
app.include_router(manager_router, prefix="/manager", tags=["Manager"])
app.include_router(messaging_router, prefix="/messaging", tags=["Messaging & Reminders"])
app.include_router(locations_router, prefix="/api", tags=["Locations"])
app.include_router(profile_router, tags=["Profile Management"])
app.include_router(report_router, tags=["Report Management"])

@app.get("/health")
def health():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
