import uvicorn

from fpl_lens.api.app import app
from fpl_lens.config import settings
from fpl_lens.logging import logger

__all__ = ["app"]

if __name__ == "__main__":
    logger.info("Starting FPL Lens backend on port %d...", settings.PORT)
    uvicorn.run(
        "fpl_lens.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=(settings.ENV == "development"),
    )
