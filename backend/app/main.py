from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import Base, engine
from .routes import onboarding

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # ✅ Allow all origins during dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

@app.get("/")
def root():
    return {"status": "ok"}

app.include_router(onboarding.router)
