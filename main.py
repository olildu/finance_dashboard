from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

# Import all of your existing API routers
from routers.debit_router import router as debit_router
from routers.credit_router import router as credit_router
from routers.get_data_router import router as get_data_router
from routers.delete_data_router import router as delete_data_router
from routers.mf_transaction_router import router as mf_transaction_router
from routers.auth_router import router as auth_router

# Initialize the FastAPI app
app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- API Routers ---
# Your API routers should be included BEFORE the static file mount.
app.include_router(auth_router)
app.include_router(debit_router)
app.include_router(credit_router)
app.include_router(get_data_router)
app.include_router(delete_data_router)
app.include_router(mf_transaction_router)

# --- Flutter Frontend Hosting ---
# This single command must be the LAST app definition.
# It serves all files from the 'static' directory.
# The `html=True` argument tells FastAPI to automatically serve `index.html`
# for paths that don't match a file, which is exactly what a SPA needs.
app.mount("/", StaticFiles(directory="static", html=True), name="static")
