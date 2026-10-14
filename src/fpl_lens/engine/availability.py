"""Availability alpha(p) implementation per Technical Specification §3.1."""


def calculate_availability(status: str, chance_of_playing: int | float | None) -> float:
    """
    Computes player availability alpha(p) in [0.0, 1.0].

    alpha(p) =
      1.0 if status == 'a'
      chance_of_playing / 100 if status == 'd'
      0.0 if status in {'i', 's', 'u'}
    """
    clean_status = (status or "").strip().lower()

    if clean_status == "a":
        return 1.0

    if clean_status == "d":
        if chance_of_playing is None:
            # Fallback for doubtful players with missing percentage [PLACEHOLDER]
            return 0.5
        # Ensure within [0.0, 1.0]
        alpha = float(chance_of_playing) / 100.0
        return max(0.0, min(1.0, alpha))

    # All injured ('i'), suspended ('s'), unavailable ('u'), or unknown statuses
    return 0.0
