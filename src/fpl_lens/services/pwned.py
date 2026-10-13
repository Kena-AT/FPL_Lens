import hashlib

import httpx

from fpl_lens.logging import logger

PWNED_API_URL = "https://api.pwnedpasswords.com/range/"


async def is_password_breached(password: str) -> bool:
    """
    Checks if a password has been exposed in data breaches using HaveIBeenPwned
    k-anonymity range API.
    Fails open (returns False) with a logged warning if the provider is unreachable.
    """
    if not password:
        return False

    sha1_hash = hashlib.sha1(password.encode("utf-8")).hexdigest().upper()
    prefix = sha1_hash[:5]
    suffix = sha1_hash[5:]

    url = f"{PWNED_API_URL}{prefix}"
    headers = {"User-Agent": "FPLLens-PasswordCheck/1.0"}

    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get(url, headers=headers)
            if resp.status_code != 200:
                logger.warning(
                    "Pwned passwords provider returned status %d. Failing open.",
                    resp.status_code,
                )
                return False

            for line in resp.text.splitlines():
                parts = line.strip().split(":")
                if parts and parts[0].upper() == suffix:
                    return True

            return False
    except (httpx.HTTPError, OSError) as exc:
        logger.warning(
            "Pwned passwords provider unreachable (%s). Failing open per spec.",
            type(exc).__name__,
        )
        return False
