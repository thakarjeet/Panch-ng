# Panchang

An offline Gujarati Hindu calendar application. Solar/lunar positions, sunrise and
sunset, Panchang elements, day periods, festivals, and muhurat candidates are
calculated on-device in Dart; the app does not use a network API.

![Panchang app logo](./assets/brand/panchang_logo.png)

## Run and build

- Install Flutter (stable) and run `flutter pub get`.
- Run tests with `flutter test`.
- Build locally with `flutter build apk --release`.
- GitHub Actions builds an APK on pushes to `main`, pull requests, or manual
  dispatch. Download `panchang-android-apk` from the workflow run's Artifacts.
  No paid service, signing key, or secret is required. Keep the GitHub
  repository public to avoid consuming private-repository Actions minutes. The
  artifact is suitable for direct sideloading, but is not configured for Play
  Store publishing.

## Reference comparison

The fixtures under `test/data/` record values published by Drik Panchang for
Ahmedabad on [20 March 2026](https://www.drikpanchang.com/panchang/day-panchang.html?date=20/03/2026&time-format=12-hour&geoname-id=1279233)
and [22 November 2026](https://www.drikpanchang.com/panchang/day-panchang.html?date=22/11/2026&time-format=12-hour&geoname-id=1279233).
They are comparison sources, not runtime dependencies. The March reference reports:

| Quantity | Published |
| --- | --- |
| Sunrise / sunset | 06:44 / 18:51 |
| Moonrise / moonset | 07:23 / 20:12 |
| Tithi / end | Shukla Dwitiya / 21 Mar 02:30 |
| Nakshatra / end | Revati / 21 Mar 02:27 |
| Rahu Kaal | 11:16–12:47 |
| Gulika Kaal | 08:15–09:46 |
| Yamaganda | 15:49–17:20 |
| Abhijit Muhurat | 12:23–13:11 |

The corresponding unit test enforces a ten-minute maximum for event times. A
source's regional conventions, rounding, chosen coordinates, and sunrise
definition may differ; compare like-for-like locations before treating a
disagreement as an engine defect.

## Calculation notes

The engine uses low-precision Meeus-style solar and lunar series, a Lahiri
ayanamsa reference calibrated to the cited almanac page, iterative angular
boundary searches, and a standard sunrise zenith. These are intentionally
transparent approximations rather than a high-precision ephemeris. Muhurat
windows are labeled traditional guidelines, not advice or guarantees. Festival
rules are explicit and simplified; local almanac conventions can differ.

Gujarati and Devanagari Noto Sans font files are bundled under the SIL Open
Font License in `assets/fonts`, so the supported scripts work offline.
