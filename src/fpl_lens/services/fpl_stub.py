from fpl_lens.logging import logger
from fpl_lens.services.fpl_client import UpstreamUnavailableError, fpl_client


async def check_fpl_team_exists(team_id: int) -> bool:
    """
    Validates that an FPL team ID exists by querying the FPL proxy client.
    Replaces the Sprint 3 stub with the real upstream check.
    Returns True if the team exists, False if 404.
    Fails open (returns True) with a logged warning if upstream is unreachable.
    """
    if team_id <= 0 or team_id > 20_000_000:
        return False

    try:
        entry = await fpl_client.get_entry(team_id)
        return entry is not None
    except UpstreamUnavailableError as exc:
        logger.warning(
            "FPL upstream unavailable during registration check for team %d: %s. Failing open.",
            team_id,
            exc,
        )
        return True
