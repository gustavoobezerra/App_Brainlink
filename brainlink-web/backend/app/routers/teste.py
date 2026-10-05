from fastapi import APIRouter
from app.services.teste_service import obter_mensagem

router = APIRouter(prefix="/teste", tags=["teste"])


@router.get("/ola-mundo")
def ola_mundo() -> dict[str, str]:
    return obter_mensagem()