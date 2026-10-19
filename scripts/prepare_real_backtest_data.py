"""
Script to extract real 2023-24 FPL season player history from vaastav/Fantasy-Premier-League
and save to tests/fixtures/fpl_2023_24_real_history.json
"""

import csv
import io
import json
import urllib.request

URL = "https://raw.githubusercontent.com/vaastav/Fantasy-Premier-League/master/data/2023-24/gws/merged_gw.csv"


def main():
    print("Fetching merged_gw.csv from vaastav...")
    req = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req) as resp:
        content = resp.read().decode("utf-8")

    reader = csv.DictReader(io.StringIO(content))
    rows = list(reader)
    print(f"Loaded {len(rows)} rows.")

    # Group by player element id
    players: dict[str, dict] = {}
    for r in rows:
        elem = r["element"]
        pos = r.get("position", "")
        if not pos:
            continue
        if elem not in players:
            players[elem] = {
                "element": int(elem),
                "name": r.get("name", f"Player_{elem}"),
                "position": pos,
                "team": r.get("team", ""),
                "matches": [],
            }

        mins = int(r.get("minutes", 0) or 0)
        starts = int(r.get("starts", 0) or 0) == 1
        goals = int(r.get("goals_scored", 0) or 0)
        assists = int(r.get("assists", 0) or 0)
        cs = int(r.get("clean_sheets", 0) or 0)
        gc = int(r.get("goals_conceded", 0) or 0)
        yc = int(r.get("yellow_cards", 0) or 0)
        rc = int(r.get("red_cards", 0) or 0)
        bonus = int(r.get("bonus", 0) or 0)
        pts = int(r.get("total_points", 0) or 0)
        gw = int(r.get("GW", 0) or 0)
        xg = float(r.get("expected_goals", 0.0) or 0.0)
        xa = float(r.get("expected_assists", 0.0) or 0.0)
        was_home = r.get("was_home", "").lower() in ("true", "1")
        opp = int(r.get("opponent_team", 0) or 0)

        # Defensive contribution proxy: for defenders/mids, bps > 20 with cs or > 12 recoveries
        dc = (
            1
            if (pos in ("DEF", "GK") and cs == 1 and mins >= 60)
            or (bonus >= 1 and goals == 0 and assists == 0)
            else 0
        )

        players[elem]["matches"].append(
            {
                "gameweek": gw,
                "minutes": mins,
                "was_starter": starts,
                "goals_scored": goals,
                "assists": assists,
                "clean_sheets": cs,
                "goals_conceded": gc,
                "yellow_cards": yc,
                "red_cards": rc,
                "bonus": bonus,
                "total_points": pts,
                "expected_goals": xg,
                "expected_assists": xa,
                "defensive_contributions": dc,
                "was_home": was_home,
                "opponent_team": opp,
            }
        )

    # Filter to players who played at least 600 total minutes in the season to get reliable cohorts
    filtered = []
    for p in players.values():
        total_mins = sum(m["minutes"] for m in p["matches"])
        if total_mins >= 600 and len(p["matches"]) >= 25:
            # Sort matches by gameweek
            p["matches"].sort(key=lambda m: m["gameweek"])
            filtered.append(p)

    print(f"Total qualified players: {len(filtered)}")
    # Count by position
    by_pos: dict[str, int] = {}
    for p in filtered:
        by_pos[p["position"]] = by_pos.get(p["position"], 0) + 1
    print(f"Position breakdown: {by_pos}")

    output_path = "tests/fixtures/fpl_2023_24_real_history.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(filtered, f, indent=2)
    print(f"Saved {len(filtered)} players to {output_path}")


if __name__ == "__main__":
    main()
