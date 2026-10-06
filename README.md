# obrii-tv-rules

The technical-rating conditions used by the Obrii app, ported from
TradingView's **TechnicalRating** Pine Script library. Published as the
Source Code Form of these files under the Mozilla Public License 2.0.

## What these files are

| File | Contents |
|---|---|
| `dart/tv_rules.dart` | The Dart port, used by the Obrii mobile app |
| `python/tv_rules.py` | The same conditions in Python, used by Obrii's alert monitor |

Each file contains only conditions taken from the original library:

- the buy/sell condition for every constituent indicator — 14 moving
  averages and Ichimoku Cloud; RSI, Stochastic, CCI, ADX, Awesome
  Oscillator, Momentum, MACD, Stochastic RSI, Williams %R, Bull Bear Power,
  Ultimate Oscillator — including the EMA(50) trend filter;
- the group averaging (`array.avg`) and the overall rating
  (`(ratingMA + ratingOther) / 2`);
- the five rating levels with their bounds (`ratingStatus()`, 0.1 and 0.5).

Computing the indicators themselves (SMA, EMA, RSI, ADX, …), the rest of the
app and the alert service are not derived from the library and are not
part of this repository.

## Origin

- Original: TradingView's `TechnicalRating` library v3 (2024-11-29),
  functions `calcRatingAll()` and `ratingStatus()`, © TradingView, published
  under the Mozilla Public License 2.0:
  <https://www.tradingview.com/script/jDWyb5PG-TechnicalRating/>
- TradingView's built-in "Technical Ratings" indicator imports that library.
  Its own documentation:
  <https://www.tradingview.com/support/solutions/43000614331-technical-ratings/>

## Modifications

Translated from Pine Script to Dart and Python. Each indicator's condition
is a separate function over plain numbers (the caller computes the
indicators and passes current and previous values). `ta.crossover` /
`ta.crossunder` are written out as explicit comparisons. Results are
returned as integers (+1 buy, 0 neutral, −1 sell), as Pine's `calcRating()`
does. Modifications © 2026 the Obrii authors.

## License

Mozilla Public License 2.0 — see [`LICENSE`](LICENSE). Every file carries
the MPL 2.0 notice in its header.

Ratings are a description of current indicator readings, not investment
advice.
