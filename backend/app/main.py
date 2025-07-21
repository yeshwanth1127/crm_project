from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes import sales_crm
from .database import Base, engine
from .routes import onboarding, register
from .routes import login

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # ✅ Allow all origins during dev
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Create tables when app starts
Base.metadata.create_all(bind=engine)

@app.get("/")
def root():
    return {"status": "ok"}

# ✅ Register your routers
app.include_router(onboarding.router)
app.include_router(register.router)
app.include_router(login.router)
app.include_router(sales_crm.router)
