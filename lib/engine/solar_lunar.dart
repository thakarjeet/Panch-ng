import 'dart:math' as math;

import 'angles.dart';

class CelestialPosition {
  const CelestialPosition({
    required this.longitude,
    required this.latitude,
    required this.rightAscension,
    required this.declination,
  });

  final double longitude;
  final double latitude;
  final double rightAscension;
  final double declination;
}

class SolarLunar {
  const SolarLunar();

  double solarLongitude(DateTime utc) {
    final t = centuriesSinceJ2000(utc);
    final meanLongitude = normalizeDegrees(
      280.46646 + t * (36000.76983 + t * 0.0003032),
    );
    final anomaly = normalizeDegrees(
      357.52911 + t * (35999.05029 - 0.0001537 * t),
    );
    final center = sinDegrees(anomaly) *
            (1.914602 - t * (0.004817 + 0.000014 * t)) +
        sinDegrees(2 * anomaly) * (0.019993 - 0.000101 * t) +
        sinDegrees(3 * anomaly) * 0.000289;
    final omega = 125.04 - 1934.136 * t;
    return normalizeDegrees(
      meanLongitude + center - 0.00569 - 0.00478 * sinDegrees(omega),
    );
  }

  double lunarLongitude(DateTime utc) {
    final t = centuriesSinceJ2000(utc);
    final lPrime = normalizeDegrees(
      218.3164477 + 481267.88123421 * t - 0.0015786 * t * t,
    );
    final d = normalizeDegrees(
      297.8501921 + 445267.1114034 * t - 0.0018819 * t * t,
    );
    final m = normalizeDegrees(
      357.5291092 + 35999.0502909 * t - 0.0001536 * t * t,
    );
    final mPrime = normalizeDegrees(
      134.9633964 + 477198.8675055 * t + 0.0087414 * t * t,
    );
    final f = normalizeDegrees(
      93.2720950 + 483202.0175233 * t - 0.0036539 * t * t,
    );
    final e = 1 - 0.002516 * t - 0.0000074 * t * t;

    final terms = <(int, int, int, int, double)>[
      (0, 0, 1, 0, 6.288774),
      (2, 0, -1, 0, 1.274027),
      (2, 0, 0, 0, 0.658314),
      (0, 0, 2, 0, 0.213618),
      (0, 1, 0, 0, -0.185116),
      (0, 0, 0, 2, -0.114332),
      (2, 0, -2, 0, 0.058793),
      (2, -1, -1, 0, 0.057066),
      (2, 0, 1, 0, 0.053322),
      (2, -1, 0, 0, 0.045758),
      (0, 1, -1, 0, -0.040923),
      (1, 0, 0, 0, -0.034720),
      (0, 1, 1, 0, -0.030383),
      (2, 0, 0, -2, 0.015327),
      (0, 0, 1, 2, -0.012528),
      (0, 0, 1, -2, 0.010980),
      (4, 0, -1, 0, 0.010675),
      (0, 0, 3, 0, 0.010034),
      (4, 0, -2, 0, 0.008548),
      (2, 1, -1, 0, -0.007888),
      (2, 1, 0, 0, -0.006766),
      (1, 0, -1, 0, -0.005163),
      (1, 1, 0, 0, 0.004987),
      (2, -1, 1, 0, 0.004036),
      (2, 0, 2, 0, 0.003994),
      (4, 0, 0, 0, 0.003861),
      (2, 0, -3, 0, 0.003665),
      (0, 1, -2, 0, -0.002689),
      (2, 0, -1, 2, -0.002602),
      (2, -1, -2, 0, 0.002390),
      (1, 0, 1, 0, -0.002348),
      (2, -2, 0, 0, 0.002236),
      (0, 1, 2, 0, -0.002120),
      (0, 2, 0, 0, -0.002069),
      (2, -2, -1, 0, 0.002048),
      (2, 0, 1, -2, -0.001773),
      (2, 0, 0, 2, -0.001595),
      (4, -1, -1, 0, 0.001215),
      (0, 0, 2, 2, -0.001110),
      (3, 0, -1, 0, -0.000892),
      (2, 1, 1, 0, -0.000810),
      (4, -1, -2, 0, 0.000759),
      (0, 2, -1, 0, -0.000713),
      (2, 2, -1, 0, -0.000700),
      (2, 1, -2, 0, 0.000691),
      (2, -1, 0, -2, 0.000596),
      (4, 0, 1, 0, 0.000549),
      (0, 0, 4, 0, 0.000537),
      (4, -1, 0, 0, 0.000520),
      (1, 0, -2, 0, -0.000487),
    ];

    var correction = 0.0;
    for (final (dCoeff, mCoeff, mpCoeff, fCoeff, amplitude) in terms) {
      final eccentricity = mCoeff.abs() == 1
          ? e
          : (mCoeff.abs() == 2 ? e * e : 1.0);
      correction += amplitude *
          eccentricity *
          sinDegrees(dCoeff * d + mCoeff * m + mpCoeff * mPrime + fCoeff * f);
    }
    final a1 = 119.75 + 131.849 * t;
    final a2 = 53.09 + 479264.290 * t;
    final a3 = 313.45 + 481266.484 * t;
    correction += 0.003958 * sinDegrees(a1) +
        0.001962 * sinDegrees(lPrime - f) +
        0.000318 * sinDegrees(a2);
    correction += 0.000174 * sinDegrees(a3);
    return normalizeDegrees(lPrime + correction);
  }

  double lunarLatitude(DateTime utc) {
    final t = centuriesSinceJ2000(utc);
    final d = normalizeDegrees(
      297.8501921 + 445267.1114034 * t - 0.0018819 * t * t,
    );
    final m = normalizeDegrees(
      357.5291092 + 35999.0502909 * t - 0.0001536 * t * t,
    );
    final mp = normalizeDegrees(
      134.9633964 + 477198.8675055 * t + 0.0087414 * t * t,
    );
    final f = normalizeDegrees(
      93.2720950 + 483202.0175233 * t - 0.0036539 * t * t,
    );
    return 5.128122 * sinDegrees(f) +
        0.280602 * sinDegrees(mp + f) +
        0.277693 * sinDegrees(mp - f) +
        0.173237 * sinDegrees(2 * d - f) +
        0.055413 * sinDegrees(2 * d + f - mp) +
        0.046272 * sinDegrees(2 * d - f - mp) +
        0.032573 * sinDegrees(2 * d + f) +
        0.017198 * sinDegrees(2 * mp + f) +
        0.009267 * sinDegrees(2 * d + mp - f) +
        0.008823 * sinDegrees(2 * mp - f) +
        0.008247 * sinDegrees(2 * d - m - mp) +
        0.004323 * sinDegrees(2 * d - f - m);
  }

  CelestialPosition moon(DateTime utc) {
    final t = centuriesSinceJ2000(utc);
    final longitude = lunarLongitude(utc);
    final latitude = lunarLatitude(utc);
    final obliquity = 23.439291 - 0.0130042 * t;
    final rightAscension = normalizeDegrees(
      atan2Degrees(
        sinDegrees(longitude) * cosDegrees(obliquity) -
            math.tan(latitude * degreesToRadians) * sinDegrees(obliquity),
        cosDegrees(longitude),
      ),
    );
    final declination = math.asin(
      sinDegrees(latitude) * cosDegrees(obliquity) +
          cosDegrees(latitude) * sinDegrees(obliquity) * sinDegrees(longitude),
    ) * radiansToDegrees;
    return CelestialPosition(
      longitude: longitude,
      latitude: latitude,
      rightAscension: rightAscension,
      declination: declination,
    );
  }

  double lahiriAyanamsa(DateTime utc) {
    const reference = 24.23946;
    final referenceDay = DateTime.utc(2026, 11, 22, 12);
    final elapsedYears =
        (julianDay(utc) - julianDay(referenceDay)) / 365.2422;
    return reference + elapsedYears * (50.290966 / 3600);
  }
}
