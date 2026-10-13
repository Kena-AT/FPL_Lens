async def check_fpl_team_exists(team_id: int) -> bool:
    """
    FPL proxy team check stub.
    Sprint 4 dependency: currently validates format and returns True.
    Will be replaced in Sprint 4 with live upstream proxy check.
    """
    if team_id <= 0 or team_id > 20_000_000:
        return False
    return True
