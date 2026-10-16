// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
// Original: TradingView's "TechnicalRating" Pine Script library v3
// (2024-11-29), functions `calcRatingAll()` and `ratingStatus()`.
// © TradingView
//
// This file is a port of those conditions to Dart, made for the Obrii app
// (2026). Modifications: translated from Pine Script to Dart; each
// indicator's condition is a separate function over plain numbers (the
// caller computes the indicators and supplies current/previous values);
// `ta.crossover`/`ta.crossunder` are written out as explicit comparisons;
// results are returned as ints (+1 buy, 0 neutral, -1 sell) as Pine's
// `calcRating()` does. Modifications © 2026 the Obrii authors, under the
// same licence.
//
// Kept free of imports and of anything not derived from that library, so
// it can be published on its own (docs/03-decisions-adr.md, ADR-090).

/// Bar-to-bar trend used by the Stochastic RSI and Bull Bear Power rules:
/// `close > ema(close, 50)` is up, `close < ema(close, 50)` is down.
enum Trend { up, down, flat }

/// The EMA length of [Trend]'s filter.
const int kTrendFilterPeriod = 50;

/// How many bars back the Ichimoku rule reads the leading spans
/// (`lead1[26]`, `lead2[26]`).
const int kIchimokuDisplacement = 26;

/// `ratingStatus()`'s weak bound: `|rating| <= 0.1` is Neutral.
const double kTvWeakBound = 0.1;

/// `ratingStatus()`'s strong bound: `|rating| > 0.5` is Strong.
const double kTvStrongBound = 0.5;

/// [Trend] from the close and its EMA(50).
Trend tvTrend(double close, double ema50) {
  if (close > ema50) return Trend.up;
  if (close < ema50) return Trend.down;
  return Trend.flat;
}

/// Every moving average: `math.sign(src - ma)`.
int tvMovingAverageRule(double price, double ma) {
  if (price > ma) return 1;
  if (price < ma) return -1;
  return 0;
}

/// Ichimoku: buy `lead1[26] > lead2[26] and base > lead1[26] and con > base
/// and close > con`; sell mirrored. [lead1] and [lead2] are the spans
/// computed [kIchimokuDisplacement] bars ago.
int tvIchimokuRule({
  required double close,
  required double conversion,
  required double base,
  required double lead1,
  required double lead2,
}) {
  if (lead1 > lead2 &&
      base > lead1 &&
      conversion > base &&
      close > conversion) {
    return 1;
  }
  if (lead1 < lead2 &&
      base < lead1 &&
      conversion < base &&
      close < conversion) {
    return -1;
  }
  return 0;
}

/// RSI(14): buy `rsi < 30 and rsi[1] < rsi`; sell `rsi > 70 and rsi[1] > rsi`.
int tvRsiRule(double rsi, double rsiPrev) {
  if (rsi < 30 && rsiPrev < rsi) return 1;
  if (rsi > 70 && rsiPrev > rsi) return -1;
  return 0;
}

/// Stochastic(14, 3, 3): buy `k < 20 and d < 20 and k > d`; sell `k > 80
/// and d > 80 and k < d`.
int tvStochasticRule(double k, double d) {
  if (k < 20 && d < 20 && k > d) return 1;
  if (k > 80 && d > 80 && k < d) return -1;
  return 0;
}

/// CCI(20): buy `cci < -100 and cci > cci[1]`; sell `cci > 100 and
/// cci < cci[1]`.
int tvCciRule(double cci, double cciPrev) {
  if (cci < -100 && cci > cciPrev) return 1;
  if (cci > 100 && cci < cciPrev) return -1;
  return 0;
}

/// ADX(14, 14): buy `adx > 20 and adx > adx[1] and diP > diN`; sell
/// `adx > 20 and adx > adx[1] and diP < diN`.
int tvAdxRule({
  required double adx,
  required double adxPrev,
  required double plusDi,
  required double minusDi,
}) {
  if (adx > 20 && adx > adxPrev && plusDi > minusDi) return 1;
  if (adx > 20 && adx > adxPrev && plusDi < minusDi) return -1;
  return 0;
}

/// Awesome Oscillator: buy `ta.crossover(ao, 0) or (ao > 0 and ao[1] > 0
/// and ao > ao[1] and ao[2] > ao[1])`; sell mirrored. A missing [aoPrev2]
/// makes the second clause false, as `na` comparisons are in Pine.
int tvAwesomeOscillatorRule(double ao, double aoPrev, double? aoPrev2) {
  final crossOver = ao > 0 && aoPrev <= 0;
  final crossUnder = ao < 0 && aoPrev >= 0;
  final turnsUp =
      aoPrev2 != null &&
      ao > 0 &&
      aoPrev > 0 &&
      ao > aoPrev &&
      aoPrev2 > aoPrev;
  final turnsDown =
      aoPrev2 != null &&
      ao < 0 &&
      aoPrev < 0 &&
      ao < aoPrev &&
      aoPrev2 < aoPrev;
  if (crossOver || turnsUp) return 1;
  if (crossUnder || turnsDown) return -1;
  return 0;
}

/// Momentum(10): buy `mom > mom[1]`; sell `mom < mom[1]`.
int tvMomentumRule(double mom, double momPrev) {
  if (mom > momPrev) return 1;
  if (mom < momPrev) return -1;
  return 0;
}

/// MACD(12, 26, 9): buy `macd > signal`; sell `macd < signal`.
int tvMacdRule(double macd, double signal) {
  if (macd > signal) return 1;
  if (macd < signal) return -1;
  return 0;
}

/// Stochastic RSI(14, 14, 3, 3): buy `downTrend and k < 20 and d < 20 and
/// k > d`; sell `upTrend and k > 80 and d > 80 and k < d`.
int tvStochasticRsiRule(double k, double d, Trend trend) {
  if (trend == Trend.down && k < 20 && d < 20 && k > d) return 1;
  if (trend == Trend.up && k > 80 && d > 80 && k < d) return -1;
  return 0;
}

/// Williams %R(14): buy `wr < -80 and wr > wr[1]`; sell `wr > -20 and
/// wr < wr[1]`.
int tvWilliamsRRule(double wr, double wrPrev) {
  if (wr < -80 && wr > wrPrev) return 1;
  if (wr > -20 && wr < wrPrev) return -1;
  return 0;
}

/// Bull Bear Power (`bullPower = high - ema(close, 13)`, `bearPower = low -
/// ema(close, 13)`): buy `upTrend and bearPower < 0 and bearPower >
/// bearPower[1]`; sell `downTrend and bullPower > 0 and bullPower <
/// bullPower[1]`. A missing value makes its clause false, as in Pine.
int tvBullBearPowerRule({
  required Trend trend,
  required double? bearPower,
  required double? bearPowerPrev,
  required double? bullPower,
  required double? bullPowerPrev,
}) {
  if (trend == Trend.up &&
      bearPower != null &&
      bearPowerPrev != null &&
      bearPower < 0 &&
      bearPower > bearPowerPrev) {
    return 1;
  }
  if (trend == Trend.down &&
      bullPower != null &&
      bullPowerPrev != null &&
      bullPower > 0 &&
      bullPower < bullPowerPrev) {
    return -1;
  }
  return 0;
}

/// Ultimate Oscillator(7, 14, 28): buy `uo > 70`; sell `uo < 30`.
int tvUltimateOscillatorRule(double uo) {
  if (uo > 70) return 1;
  if (uo < 30) return -1;
  return 0;
}

/// A group's rating: `array.avg` of its members' +1/0/-1 values, where a
/// `null` member is Pine's `na` (its gate is undefined) and is left out of
/// the mean; `null` (`na`) when no member is defined.
double? tvGroupRating(List<int?> values) {
  final defined = values.whereType<int>().toList();
  if (defined.isEmpty) return null;
  return defined.fold<int>(0, (a, b) => a + b) / defined.length;
}

/// The overall rating, as `calcRatingAll()`'s `switch`: the mean of both
/// groups when both are defined, the one defined group alone otherwise,
/// `null` (`na`) when neither is.
double? tvOverallRating(double? maRating, double? oscillatorRating) {
  if (maRating != null && oscillatorRating != null) {
    return (maRating + oscillatorRating) / 2;
  }
  return maRating ?? oscillatorRating;
}

/// `ratingStatus()` with its default bounds, as -2 (Strong Sell), -1
/// (Sell), 0 (Neutral), 1 (Buy), 2 (Strong Buy).
int tvRatingStatus(double rating) {
  if (rating < -kTvStrongBound) return -2;
  if (rating < -kTvWeakBound) return -1;
  if (rating > kTvStrongBound) return 2;
  if (rating > kTvWeakBound) return 1;
  return 0;
}
