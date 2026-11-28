from fpl_lens.engine.layer1_v2.layer3_validation import (
    evaluate_chips_backtest,
    evaluate_layer3_backtest,
)


def test_layer3_and_chips_backtest_acceptance():
    # 8 GWs of positive transfer moves with 19/20 shortlist recall (95%)
    moves = [(gw, 2.2, 0) for gw in range(1, 9)]
    rep = evaluate_layer3_backtest(moves, shortlist_hits=19, shortlist_total=20)
    assert rep.accepted is True
    assert rep.shortlist_recall == 0.95
    assert rep.mean_net_gain_ci[0] > 0.0

    mean_cf, mean_th, ok = evaluate_chips_backtest([11.0, 9.5], [7.0, 8.0])
    assert ok is True
    assert mean_cf > mean_th
