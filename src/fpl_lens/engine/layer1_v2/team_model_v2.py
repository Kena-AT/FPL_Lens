"""
Regularized Poisson Team Strength Model per Engine Design §5.3.
Replaces ordinal FPL strengths with attack a_T, defence d_T, and home advantage h
fitted from completed match results with time decay and ridge shrinkage.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field


@dataclass(frozen=True)
class CompletedMatch:
    gameweek: int
    home_team_id: int
    away_team_id: int
    home_goals: int
    away_goals: int
    home_xg: float | None = None
    away_xg: float | None = None


@dataclass(frozen=True)
class PoissonTeamModel:
    mu: float
    home_advantage: float
    attack: dict[int, float] = field(default_factory=dict)
    defence: dict[int, float] = field(default_factory=dict)
    matches_per_team: dict[int, int] = field(default_factory=dict)
    xg_blend: float = 0.3

    @classmethod
    def fit(
        cls,
        matches: list[CompletedMatch],
        *,
        current_gameweek: int,
        half_life_gws: float = 12.0,
        ridge_lambda: float = 1.5,
        xg_blend: float = 0.3,
        max_iter: int = 40,
    ) -> PoissonTeamModel:
        if not matches:
            return cls(mu=1.35, home_advantage=0.12, xg_blend=xg_blend)

        team_ids = sorted({m.home_team_id for m in matches} | {m.away_team_id for m in matches})
        counts: dict[int, int] = {t: 0 for t in team_ids}
        att: dict[int, float] = {t: 0.0 for t in team_ids}
        defn: dict[int, float] = {t: 0.0 for t in team_ids}

        weighted_goals = 0.0
        total_w = 0.0
        obs: list[tuple[int, int, bool, float, float]] = []

        for m in matches:
            w = 0.5 ** (max(0, current_gameweek - m.gameweek) / max(1.0, half_life_gws))
            counts[m.home_team_id] += 1
            counts[m.away_team_id] += 1

            hg = float(m.home_goals)
            ag = float(m.away_goals)
            if m.home_xg is not None and m.away_xg is not None:
                hg = (1.0 - xg_blend) * hg + xg_blend * float(m.home_xg)
                ag = (1.0 - xg_blend) * ag + xg_blend * float(m.away_xg)

            obs.append((m.home_team_id, m.away_team_id, True, hg, w))
            obs.append((m.away_team_id, m.home_team_id, False, ag, w))
            weighted_goals += w * (hg + ag)
            total_w += 2.0 * w

        mu = max(0.4, weighted_goals / max(1e-6, total_w))
        h = 0.12
        lr = 0.03

        # Coordinate gradient ascent on regularized Poisson log-likelihood
        for _ in range(max_iter):
            grad_a = {t: -ridge_lambda * att[t] for t in team_ids}
            grad_d = {t: -ridge_lambda * defn[t] for t in team_ids}
            grad_h = -0.5 * ridge_lambda * h

            for t, o, is_home, y, w in obs:
                eta = att[t] - defn[o] + (h if is_home else 0.0)
                eta = max(-2.5, min(2.5, eta))
                lam = mu * math.exp(eta)
                diff = w * (y - lam)
                grad_a[t] += diff
                grad_d[o] -= diff
                if is_home:
                    grad_h += diff

            for t in team_ids:
                att[t] = max(-1.5, min(1.5, att[t] + lr * grad_a[t] / max(1.0, counts[t])))
                defn[t] = max(-1.5, min(1.5, defn[t] + lr * grad_d[t] / max(1.0, counts[t])))
            h = max(-0.5, min(0.6, h + lr * grad_h / max(1.0, len(matches))))

            # Center attack and defence for identifiability
            mean_a = sum(att.values()) / len(team_ids)
            mean_d = sum(defn.values()) / len(team_ids)
            for t in team_ids:
                att[t] -= mean_a
                defn[t] -= mean_d

        return cls(
            mu=mu,
            home_advantage=h,
            attack=att,
            defence=defn,
            matches_per_team=counts,
            xg_blend=xg_blend,
        )

    def predict_intensities(
        self,
        team_id: int,
        opponent_id: int,
        is_home: bool,
    ) -> tuple[float, float, bool]:
        """Returns (lambda_for, lambda_against, low_sample_flag)."""
        a_t = self.attack.get(team_id, 0.0)
        d_t = self.defence.get(team_id, 0.0)
        a_o = self.attack.get(opponent_id, 0.0)
        d_o = self.defence.get(opponent_id, 0.0)

        lam_for = self.mu * math.exp(a_t - d_o + (self.home_advantage if is_home else 0.0))
        lam_against = self.mu * math.exp(a_o - d_t + (0.0 if is_home else self.home_advantage))

        low_sample = (
            self.matches_per_team.get(team_id, 0) < 4
            or self.matches_per_team.get(opponent_id, 0) < 4
        )
        return max(0.05, lam_for), max(0.05, lam_against), low_sample
