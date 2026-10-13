from typing import Any

from fpl_lens.config import settings
from fpl_lens.logging import logger


def verify_google_id_token(token: str) -> dict[str, Any]:
    """
    Verifies a Google ID token's signature, issuer, audience, and expiry.
    Rejects tokens with mismatched audience or expired timestamps.
    Returns the token claims dict with 'sub', 'email', etc.
    """
    from google.auth.transport import requests
    from google.oauth2 import id_token

    request = requests.Request()

    # Audiences to accept: Android client ID and/or Web client ID
    accepted_audiences = []
    if settings.GOOGLE_ANDROID_CLIENT_ID:
        accepted_audiences.append(settings.GOOGLE_ANDROID_CLIENT_ID)
    if settings.GOOGLE_WEB_CLIENT_ID:
        accepted_audiences.append(settings.GOOGLE_WEB_CLIENT_ID)

    try:
        # If no audience configured in settings (dev mode), verify signature and issuer without aud check
        if not accepted_audiences:
            claims = id_token.verify_oauth2_token(token, request)
        else:
            # Check against allowlisted audience(s)
            claims = None
            last_err = None
            for aud in accepted_audiences:
                try:
                    claims = id_token.verify_oauth2_token(token, request, audience=aud)
                    break
                except ValueError as e:
                    last_err = e

            if not claims:
                raise last_err or ValueError("Google token audience mismatch")

        # Issuer check
        if claims.get("iss") not in ["accounts.google.com", "https://accounts.google.com"]:
            raise ValueError(f"Invalid Google token issuer: {claims.get('iss')}")

        return claims

    except Exception as exc:
        logger.warning("Google ID token validation failed: %s", type(exc).__name__)
        raise ValueError(f"Invalid Google ID token: {exc}") from exc
