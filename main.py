from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from routers.debit_router import router as debit_router
from routers.credit_router import router as credit_router
from routers.get_data_router import router as get_data_router
from routers.delete_data_router import router as delete_data_router
from routers.mf_transaction_router import router as mf_transaction_router
from routers.auth_router import router as auth_router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"], 
)

app.include_router(auth_router)
app.include_router(debit_router)
app.include_router(credit_router)
app.include_router(get_data_router)
app.include_router(delete_data_router)
app.include_router(mf_transaction_router)
app.include_router(auth_router)