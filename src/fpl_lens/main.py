import uvicorn
from src.fpl_lens.api.app import app
from src.fpl_lens.config import settings
from src.fpl_lens.logging import logger

__all__ = ["app"]

if __name__ == "__main__":
    logger.info("Starting FPL Lens backend on port %d...", settings.PORT)
    uvicorn.run(
        "src.fpl_lens.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=(settings.ENV == "development"),
    )
