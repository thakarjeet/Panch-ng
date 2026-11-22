import 'dart:math' as math;

const double degreesToRadians = math.pi / 180.0;
const double radiansToDegrees = 180.0 / math.pi;

double normalizeDegrees(double angle) => (angle % 360.0 + 360.0) % 360.0;

double sinDegrees(double angle) => math.sin(angle * degreesToRadians);

double cosDegrees(double angle) => math.cos(angle * degreesToRadians);

double atan2Degrees(double y, double x) =>
    math.atan2(y, x) * radiansToDegrees;

double julianDay(DateTime utc) =>
    utc.toUtc().millisecondsSinceEpoch / Duration.millisecondsPerDay +
    2440587.5;

double centuriesSinceJ2000(DateTime utc) =>
    (julianDay(utc) - 2451545.0) / 36525.0;

double angularDistance(double from, double to) =>
    normalizeDegrees(to - from);

double interpolateCrossing(
  double low,
  double high,
  double Function(double) progress,
  double target,
) {
  for (var i = 0; i < 32; i++) {
    final middle = (low + high) / 2;
    if (progress(middle) < target) {
      low = middle;
    } else {
      high = middle;
    }
  }
  return (low + high) / 2;
}
