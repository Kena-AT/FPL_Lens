"""
Versioned Rules Table per Engine Design §3 & §13.2.
Every rule has: key, value, season, source, state, date_checked.
States: VERIFIED-OFFICIAL | VERIFIED-2ND | VERIFY | DECIDED.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

RULES_TABLE_VERSION = "2026-27.1"
VALID_RULE_STATES = frozenset({"VERIFIED-OFFICIAL", "VERIFIED-2ND", "VERIFY", "DECIDED"})


@dataclass(frozen=True)
class RuleRow:
    key: str
    value: Any
    season: str
    source: str
    state: str
    date_checked: str

    def __post_init__(self) -> None:
        if self.state not in VALID_RULE_STATES:
            raise ValueError(f"Invalid rule state '{self.state}' for '{self.key}'")


RULES_TABLE: tuple[RuleRow, ...] = (
    # §3.1 Squad & Formation
    RuleRow("squad_size", 15, "2026/27", "PL 'FPL basics: Managing your team'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("xi_size", 11, "2026/27", "PL 'FPL basics: Managing your team'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("xi_min_gk", 1, "2026/27", "PL 'FPL basics: Managing your team'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("xi_max_gk", 1, "2026/27", "PL 'FPL basics: Managing your team'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("xi_min_def", 3, "2026/27", "PL 'FPL basics: Managing your team'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("xi_min_mid", 2, "2026/27", "PL 'FPL basics: Managing your team'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("xi_min_fwd", 1, "2026/27", "PL 'FPL basics: Managing your team'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("squad_gk_count", 2, "2026/27", "Frontend & Core App docs", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("squad_def_count", 5, "2026/27", "Frontend & Core App docs", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("squad_mid_count", 5, "2026/27", "Frontend & Core App docs", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("squad_fwd_count", 3, "2026/27", "Frontend & Core App docs", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("max_players_per_club", 3, "2026/27", "onsidearena.com 2026/27", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("initial_budget_tenths", 1000, "2026/27", "onsidearena.com 2026/27", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("total_gameweeks", 38, "2026/27", "PL", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("free_transfers_per_gw", 1, "2026/27", "onsidearena", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("max_banked_free_transfers", 5, "2026/27", "PL 4679873", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("extra_transfer_hit_cost", 4, "2026/27", "onsidearena; Fantasy Football Scout", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("one_chip_per_gw", True, "2026/27", "PL 4679879", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("free_hit_allowed_gw1", False, "2026/27", "PL 4679879", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("selling_price_rise_share", 0.5, "2026/27", "OneFPL", "VERIFIED-2ND", "2026-11-22"),
    RuleRow("banked_ft_kept_through_wc_fh", True, "2026/27", "onsidearena", "VERIFIED-2ND", "2026-11-22"),
    # §3.2 Scoring
    RuleRow("pts_sub_60", 1, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_60_plus", 2, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_goal_gk", 10, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_goal_def", 6, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_goal_mid", 5, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_goal_fwd", 4, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_assist", 3, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_cs_gk_def", 4, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_cs_mid", 1, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_cs_fwd", 0, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_save_per_3", 1, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_penalty_save", 5, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_penalty_miss", -2, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_yellow_card", -1, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_red_card", -3, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_own_goal", -2, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    RuleRow("pts_dc_cap", 2, "2026/27", "PL 'FPL basics: Scoring points'", "VERIFIED-OFFICIAL", "2026-11-22"),
    # §3.6 Open VERIFY rules
    RuleRow("hit_waived_during_wc_fh", True, "2026/27", "Pending official rules check", "VERIFY", "2026-11-22"),
    RuleRow("wildcard_available_gw1", True, "2026/27", "Conflicting PL vs onsidearena", "VERIFY", "2026-11-22"),
    RuleRow("gw19_deadline_from_api", True, "2026/27", "Read deadline_time from API", "VERIFY", "2026-11-22"),
    RuleRow("vice_captain_sub_activation", True, "2026/27", "Pending past-GW test", "VERIFY", "2026-11-22"),
    RuleRow("yellow_card_ban_thresholds", "5/10/15", "2026/27", "Pending PL rules verification", "VERIFY", "2026-11-22"),
    RuleRow("dgw_chip_captain_handling", "both_fixtures", "2026/27", "Pending live DGW observation", "VERIFY", "2026-11-22"),
)

_RULES_BY_KEY: dict[str, RuleRow] = {row.key: row for row in RULES_TABLE}


def get_rule(key: str) -> RuleRow:
    if key not in _RULES_BY_KEY:
        raise KeyError(f"Unknown rule key '{key}' (not in Rules Table {RULES_TABLE_VERSION})")
    return _RULES_BY_KEY[key]


def get_verify_rules() -> list[RuleRow]:
    return [row for row in RULES_TABLE if row.state == "VERIFY"]
