# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# Original: TradingView's "TechnicalRating" Pine Script library v3
# (2024-11-29), functions `calcRatingAll()` and `ratingStatus()`.
# © TradingView
#
# This file is a port of those conditions to Python, made for the Obrii
# app (2026) as the mirror of `tv_rules.dart`. Modifications: translated
# from Pine Script to Python; each indicator's condition is a separate
# function over plain numbers (the caller computes the indicators and
# supplies current/previous values); `ta.crossover`/`ta.crossunder` are
# written out as explicit comparisons; results are returned as ints (+1
# buy, 0 neutral, -1 sell) as Pine's `calcRating()` does. Modifications
# © 2026 the Obrii authors, under the same licence.
#
# Kept free of imports beyond the standard library and of anything not
# derived from that library, so it can be published on its own (ADR-090).
"""TradingView Technical Ratings conditions, ported from Pine Script."""

from __future__ import annotations

from enum import Enum
from typing import Optional


class Trend(Enum):
    """``close > ema(close, 50)`` is up, ``close < ema(close, 50)`` is down."""

    UP = "up"
    DOWN = "down"
    FLAT = "flat"


TREND_FILTER_PERIOD = 50
ICHIMOKU_DISPLACEMENT = 26
TV_WEAK_BOUND = 0.1
TV_STRONG_BOUND = 0.5


def tv_trend(close: float, ema50: float) -> Trend:
    if close > ema50:
        return Trend.UP
    if close < ema50:
        return Trend.DOWN
    return Trend.FLAT


def tv_moving_average_rule(price: float, ma: float) -> int:
    """``math.sign(src - ma)``."""
    if price > ma:
        return 1
    if price < ma:
        return -1
    return 0


def tv_ichimoku_rule(close: float, conversion: float, base: float, lead1: float, lead2: float) -> int:
    """Buy ``lead1[26] > lead2[26] and base > lead1[26] and con > base and
    close > con``; sell mirrored. ``lead1``/``lead2`` are from 26 bars ago."""
    if lead1 > lead2 and base > lead1 and conversion > base and close > conversion:
        return 1
    if lead1 < lead2 and base < lead1 and conversion < base and close < conversion:
        return -1
    return 0


def tv_rsi_rule(rsi: float, rsi_prev: float) -> int:
    """Buy ``rsi < 30 and rsi[1] < rsi``; sell ``rsi > 70 and rsi[1] > rsi``."""
    if rsi < 30 and rsi_prev < rsi:
        return 1
    if rsi > 70 and rsi_prev > rsi:
        return -1
    return 0


def tv_stochastic_rule(k: float, d: float) -> int:
    """Buy ``k < 20 and d < 20 and k > d``; sell ``k > 80 and d > 80 and k < d``."""
    if k < 20 and d < 20 and k > d:
        return 1
    if k > 80 and d > 80 and k < d:
        return -1
    return 0


def tv_cci_rule(cci: float, cci_prev: float) -> int:
    """Buy ``cci < -100 and cci > cci[1]``; sell ``cci > 100 and cci < cci[1]``."""
    if cci < -100 and cci > cci_prev:
        return 1
    if cci > 100 and cci < cci_prev:
        return -1
    return 0


def tv_adx_rule(adx: float, adx_prev: float, plus_di: float, minus_di: float) -> int:
    """Buy ``adx > 20 and adx > adx[1] and diP > diN``; sell ``adx > 20 and
    adx > adx[1] and diP < diN``."""
    if adx > 20 and adx > adx_prev and plus_di > minus_di:
        return 1
    if adx > 20 and adx > adx_prev and plus_di < minus_di:
        return -1
    return 0


def tv_awesome_oscillator_rule(ao: float, ao_prev: float, ao_prev2: Optional[float]) -> int:
    """Buy ``ta.crossover(ao, 0) or (ao > 0 and ao[1] > 0 and ao > ao[1] and
    ao[2] > ao[1])``; sell mirrored. A missing ``ao_prev2`` makes the second
    clause false, as ``na`` comparisons are in Pine."""
    cross_over = ao > 0 and ao_prev <= 0
    cross_under = ao < 0 and ao_prev >= 0
    turns_up = ao_prev2 is not None and ao > 0 and ao_prev > 0 and ao > ao_prev and ao_prev2 > ao_prev
    turns_down = ao_prev2 is not None and ao < 0 and ao_prev < 0 and ao < ao_prev and ao_prev2 < ao_prev
    if cross_over or turns_up:
        return 1
    if cross_under or turns_down:
        return -1
    return 0


def tv_momentum_rule(mom: float, mom_prev: float) -> int:
    """Buy ``mom > mom[1]``; sell ``mom < mom[1]``."""
    if mom > mom_prev:
        return 1
    if mom < mom_prev:
        return -1
    return 0


def tv_macd_rule(macd: float, signal: float) -> int:
    """Buy ``macd > signal``; sell ``macd < signal``."""
    if macd > signal:
        return 1
    if macd < signal:
        return -1
    return 0


def tv_stochastic_rsi_rule(k: float, d: float, trend: Trend) -> int:
    """Buy ``downTrend and k < 20 and d < 20 and k > d``; sell ``upTrend and
    k > 80 and d > 80 and k < d``."""
    if trend is Trend.DOWN and k < 20 and d < 20 and k > d:
        return 1
    if trend is Trend.UP and k > 80 and d > 80 and k < d:
        return -1
    return 0


def tv_williams_r_rule(wr: float, wr_prev: float) -> int:
    """Buy ``wr < -80 and wr > wr[1]``; sell ``wr > -20 and wr < wr[1]``."""
    if wr < -80 and wr > wr_prev:
        return 1
    if wr > -20 and wr < wr_prev:
        return -1
    return 0


def tv_bull_bear_power_rule(
    trend: Trend,
    bear_power: Optional[float],
    bear_power_prev: Optional[float],
    bull_power: Optional[float],
    bull_power_prev: Optional[float],
) -> int:
    """Buy ``upTrend and bearPower < 0 and bearPower > bearPower[1]``; sell
    ``downTrend and bullPower > 0 and bullPower < bullPower[1]``. A missing
    value makes its clause false, as in Pine."""
    if (
        trend is Trend.UP
        and bear_power is not None
        and bear_power_prev is not None
        and bear_power < 0
        and bear_power > bear_power_prev
    ):
        return 1
    if (
        trend is Trend.DOWN
        and bull_power is not None
        and bull_power_prev is not None
        and bull_power > 0
        and bull_power < bull_power_prev
    ):
        return -1
    return 0


def tv_ultimate_oscillator_rule(uo: float) -> int:
    """Buy ``uo > 70``; sell ``uo < 30``."""
    if uo > 70:
        return 1
    if uo < 30:
        return -1
    return 0


def tv_group_rating(values: list[Optional[int]]) -> Optional[float]:
    """``array.avg`` of a group's +1/0/-1 values; a ``None`` member is
    Pine's ``na`` and is left out; ``None`` when no member is defined."""
    defined = [v for v in values if v is not None]
    if not defined:
        return None
    return sum(defined) / len(defined)


def tv_overall_rating(ma_rating: Optional[float], oscillator_rating: Optional[float]) -> Optional[float]:
    """``calcRatingAll()``'s switch: the mean of both groups when both are
    defined, the one defined group alone otherwise, ``None`` when neither."""
    if ma_rating is not None and oscillator_rating is not None:
        return (ma_rating + oscillator_rating) / 2
    return ma_rating if ma_rating is not None else oscillator_rating


def tv_rating_status(rating: float) -> int:
    """``ratingStatus()`` with default bounds: -2 Strong Sell, -1 Sell,
    0 Neutral, 1 Buy, 2 Strong Buy."""
    if rating < -TV_STRONG_BOUND:
        return -2
    if rating < -TV_WEAK_BOUND:
        return -1
    if rating > TV_STRONG_BOUND:
        return 2
    if rating > TV_WEAK_BOUND:
        return 1
    return 0
