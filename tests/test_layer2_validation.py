from fpl_lens.engine.layer1_v2.layer2_validation import evaluate_layer2_backtest


def test_layer2_backtest_computes_regret_and_block_bootstrap_ci():
    # 8 GWs where engine consistently beats prev-GW baseline by +4 pts, with 3 pts oracle regret
    scores = [(gw, 58.0, 56.5, 54.0, 61.0) for gw in range(1, 9)]
    report = evaluate_layer2_backtest(scores)
    assert report.gameweeks_evaluated == 8
    assert report.mean_regret_vs_oracle == 3.0
    assert report.gain_over_prev_gw_ci[0] > 0.0
