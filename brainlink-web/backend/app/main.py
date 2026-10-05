from fastapi import FastAPI

from app.routers.teste import router as teste_router

app = FastAPI()

app.include_router(teste_router)