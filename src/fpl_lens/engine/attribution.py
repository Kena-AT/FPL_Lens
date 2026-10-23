"""
Attribution Template Engine per Backend Design §6.6, Spec §3 & §4, and Frontend Plan §P11.

Produces deterministic explanations strictly citing stored projection fields.
Never invokes AI, never invents missing numbers, and omits any line whose field is absent.
"""

from typing import Any


class AttributionEngine:
    """
    Deterministic attribution template engine.
    Cites only stored projection fields; omits any line when its source field is missing or None.
    """

    @staticmethod
    def generate_attributions(projection: dict[str, Any]) -> list[str]:
        """
        Generates attribution lines from stored player projection data.

        Accepts either flattened player projection dicts or nested structures with
        'components' sub-dictionaries.
        """
        lines: list[str] = []

        # Extract components if nested
        components = projection.get("components")
        if not isinstance(components, dict):
            components = projection

        # 1. Availability (α)
        if "availability" in projection and projection["availability"] is not None:
            avail = projection["availability"]
            pct = round(avail * 100) if avail <= 1.0 else round(avail)
            lines.append(f"Availability (α): {pct}% (Share of expected availability)")

        # 2. Start probability
        if "p_start" in projection and projection["p_start"] is not None:
            p_start = projection["p_start"]
            pct = round(p_start * 100) if p_start <= 1.0 else round(p_start)
            lines.append(f"Start probability: {pct}%")

        # 3. Expected minutes
        if "expected_minutes" in projection and projection["expected_minutes"] is not None:
            mins = projection["expected_minutes"]
            lines.append(f"Expected minutes: {mins:.1f}" if isinstance(mins, float) and mins % 1 != 0 else f"Expected minutes: {int(mins)}")

        # 4. Expected goals (xG)
        xg = components.get("exp_goals") if "exp_goals" in components else projection.get("exp_goals")
        if xg is None and "xg" in projection:
            xg = projection["xg"]
        if xg is not None:
            lines.append(f"Expected goals (xG): {float(xg):.2f}")

        # 5. Expected assists (xA)
        xa = components.get("exp_assists") if "exp_assists" in components else projection.get("exp_assists")
        if xa is None and "xa" in projection:
            xa = projection["xa"]
        if xa is not None:
            lines.append(f"Expected assists (xA): {float(xa):.2f}")

        # 6. Clean sheet probability
        cs = components.get("exp_clean_sheet") if "exp_clean_sheet" in components else projection.get("exp_clean_sheet")
        if cs is not None:
            val = float(cs)
            pct = round(val * 100) if val <= 1.0 else round(val)
            lines.append(f"Clean sheet probability: {pct}%")

        # 7. Goals-conceded penalty
        gc = components.get("exp_goals_conceded") if "exp_goals_conceded" in components else projection.get("exp_goals_conceded")
        if gc is not None:
            lines.append(f"Goals-conceded penalty: {float(gc):.2f}")

        # 8. Defensive contributions
        dc = components.get("exp_dc") if "exp_dc" in components else projection.get("exp_dc")
        if dc is not None:
            val = float(dc)
            pct = round(val * 100) if val <= 1.0 else round(val)
            lines.append(f"Defensive contributions: {pct}% chance of threshold")

        # 9. Expected bonus
        bonus = components.get("exp_bonus") if "exp_bonus" in components else projection.get("exp_bonus")
        if bonus is not None:
            lines.append(f"Expected bonus: {float(bonus):.2f}")

        # 10. Card penalty
        card = components.get("exp_card_penalty") if "exp_card_penalty" in components else projection.get("exp_card_penalty")
        if card is not None:
            lines.append(f"Card penalty: {float(card):.2f}")

        return lines
