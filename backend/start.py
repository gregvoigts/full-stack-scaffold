import uvicorn
import os
from src import config


# uvicorn general settings
UVICORN_CONFIG = dict(
    host=config.API_HOST,
    port=int(os.environ.get('PORT', config.API_PORT)),
    log_level=config.API_LOG_LEVEL,
    proxy_headers=True,
    forwarded_allow_ips="*"
)

if config.DEVELOPMENT:
    # development uses reload without workers
    UVICORN_CONFIG['reload'] = True
else:
    # production uses workers without reload
    UVICORN_CONFIG['workers'] = int(os.environ.get('WORKERS', config.WORKERS))


def main():

    uvicorn.run(
        "src.main:app",
        **UVICORN_CONFIG
    )


if __name__ == "__main__":
    main()
