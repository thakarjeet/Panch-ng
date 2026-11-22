import 'dart:math' as math;

import 'angles.dart';
import 'solar_lunar.dart';

class PanchangLocation {
  const PanchangLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.utcOffset,
  });

  final String name;
  final double latitude;
  final double longitude;
  final Duration utcOffset;

  static const ahmedabad = PanchangLocation(
    name: 'Ahmedabad',
    latitude: 23.0225,
    longitude: 72.5714,
    utcOffset: Duration(hours: 5, minutes: 30),
  );
}

class TimeWindow {
  const TimeWindow(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

enum LunarMonthSystem { amanta, purnimanta }

class PanchangDay {
  const PanchangDay({
    required this.date,
    required this.location,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.tithi,
    required this.tithiStart,
    required this.tithiEnd,
    required this.nakshatra,
    required this.nakshatraPada,
    required this.nakshatraStart,
    required this.nakshatraEnd,
    required this.yoga,
    required this.yogaStart,
    required this.yogaEnd,
    required this.karana,
    required this.karanaStart,
    required this.karanaEnd,
    required this.vara,
    required this.rahuKaal,
    required this.gulikaKaal,
    required this.yamaganda,
    required this.abhijit,
    required this.lunarMonth,
    required this.vikramSamvat,
    required this.shakaSamvat,
  });

  final DateTime date;
  final PanchangLocation location;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? moonrise;
  final DateTime? moonset;
  final String tithi;
  final DateTime tithiStart;
  final DateTime tithiEnd;
  final String nakshatra;
  final int nakshatraPada;
  final DateTime nakshatraStart;
  final DateTime nakshatraEnd;
  final String yoga;
  final DateTime yogaStart;
  final DateTime yogaEnd;
  final String karana;
  final DateTime karanaStart;
  final DateTime karanaEnd;
  final String vara;
  final TimeWindow? rahuKaal;
  final TimeWindow? gulikaKaal;
  final TimeWindow? yamaganda;
  final TimeWindow? abhijit;
  final String lunarMonth;
  final int vikramSamvat;
  final int shakaSamvat;
}

class PanchangEngine {
  const PanchangEngine({this.astronomy = const SolarLunar()});

  final SolarLunar astronomy;

  static const _tithis = [
    'Shukla Pratipada',
    'Shukla Dwitiya',
    'Shukla Tritiya',
    'Shukla Chaturthi',
    'Shukla Panchami',
    'Shukla Shashthi',
    'Shukla Saptami',
    'Shukla Ashtami',
    'Shukla Navami',
    'Shukla Dashami',
    'Shukla Ekadashi',
    'Shukla Dwadashi',
    'Shukla Trayodashi',
    'Shukla Chaturdashi',
    'Purnima',
    'Krishna Pratipada',
    'Krishna Dwitiya',
    'Krishna Tritiya',
    'Krishna Chaturthi',
    'Krishna Panchami',
    'Krishna Shashthi',
    'Krishna Saptami',
    'Krishna Ashtami',
    'Krishna Navami',
    'Krishna Dashami',
    'Krishna Ekadashi',
    'Krishna Dwadashi',
    'Krishna Trayodashi',
    'Krishna Chaturdashi',
    'Amavasya',
  ];

  static const _nakshatras = [
    'Ashwini',
    'Bharani',
    'Krittika',
    'Rohini',
    'Mrigashirsha',
    'Ardra',
    'Punarvasu',
    'Pushya',
    'Ashlesha',
    'Magha',
    'Purva Phalguni',
    'Uttara Phalguni',
    'Hasta',
    'Chitra',
    'Swati',
    'Vishakha',
    'Anuradha',
    'Jyeshtha',
    'Mula',
    'Purva Ashadha',
    'Uttara Ashadha',
    'Shravana',
    'Dhanishta',
    'Shatabhisha',
    'Purva Bhadrapada',
    'Uttara Bhadrapada',
    'Revati',
  ];

  static const _yogas = [
    'Vishkambha',
    'Priti',
    'Ayushman',
    'Saubhagya',
    'Shobhana',
    'Atiganda',
    'Sukarma',
    'Dhriti',
    'Shula',
    'Ganda',
    'Vriddhi',
    'Dhruva',
    'Vyaghata',
    'Harshana',
    'Vajra',
    'Siddhi',
    'Vyatipata',
    'Variyana',
    'Parigha',
    'Shiva',
    'Siddha',
    'Sadhya',
    'Shubha',
    'Shukla',
    'Brahma',
    'Indra',
    'Vaidhriti',
  ];

  static const _karanas = [
    'Bava',
    'Balava',
    'Kaulava',
    'Taitila',
    'Garaja',
    'Vanija',
    'Vishti',
  ];

  static const _lunarMonths = [
    'Chaitra',
    'Vaishakha',
    'Jyeshtha',
    'Ashadha',
    'Shravana',
    'Bhadrapada',
    'Ashwin',
    'Kartika',
    'Margashirsha',
    'Pausha',
    'Magha',
    'Phalguna',
  ];

  double _elongation(DateTime utc) => normalizeDegrees(
        astronomy.lunarLongitude(utc) - astronomy.solarLongitude(utc),
      );

  DateTime _nextCrossing(
    DateTime from,
    double Function(DateTime) angle,
    double stepDegrees,
  ) {
    final start = angle(from);
    final target = stepDegrees - (start % stepDegrees);
    double progress(DateTime date) => angularDistance(start, angle(date));
    var low = from.millisecondsSinceEpoch.toDouble();
    var high = low;
    for (var i = 0; i < 96; i++) {
      high += const Duration(minutes: 30).inMilliseconds;
      if (progress(DateTime.fromMillisecondsSinceEpoch(high.round(), isUtc: true)) >=
          target) {
        final root = interpolateCrossing(
          low,
          high,
          (millis) => progress(
            DateTime.fromMillisecondsSinceEpoch(millis.round(), isUtc: true),
          ),
          target,
        );
        return DateTime.fromMillisecondsSinceEpoch(root.round(), isUtc: true);
      }
      low = high;
    }
    throw StateError('Could not find the next celestial boundary.');
  }

  DateTime _previousCrossing(
    DateTime from,
    double Function(DateTime) angle,
    double stepDegrees,
  ) {
    var high = from.millisecondsSinceEpoch.toDouble();
    var low = high;
    for (var i = 0; i < 96; i++) {
      low -= const Duration(minutes: 30).inMilliseconds;
      final earlierAngle = angle(
        DateTime.fromMillisecondsSinceEpoch(low.round(), isUtc: true),
      );
      final target = stepDegrees - (earlierAngle % stepDegrees);
      double progress(double millis) => angularDistance(
            earlierAngle,
            angle(DateTime.fromMillisecondsSinceEpoch(millis.round(), isUtc: true)),
          );
      if (progress(high) >= target) {
        final root = interpolateCrossing(low, high, progress, target);
        return DateTime.fromMillisecondsSinceEpoch(root.round(), isUtc: true);
      }
      high = low;
    }
    throw StateError('Could not find the preceding celestial boundary.');
  }

  DateTime? _solarEvent(DateTime localDate, PanchangLocation location, bool rise) {
    final utcDate = DateTime.utc(localDate.year, localDate.month, localDate.day);
    final noon = utcDate.add(const Duration(hours: 12));
    final t = centuriesSinceJ2000(noon);
    final l0 = normalizeDegrees(280.46646 + t * (36000.76983 + 0.0003032 * t));
    final m = normalizeDegrees(357.52911 + t * (35999.05029 - 0.0001537 * t));
    final eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final y = math.tan((23.439291 - 0.0130042 * t) * degreesToRadians / 2);
    final y2 = y * y;
    final equationTime = 4 * radiansToDegrees *
        (y2 * sinDegrees(2 * l0) -
            2 * eccentricity * sinDegrees(m) +
            4 * eccentricity * y2 * sinDegrees(m) * cosDegrees(2 * l0) -
            0.5 * y2 * y2 * sinDegrees(4 * l0) -
            1.25 * eccentricity * eccentricity * sinDegrees(2 * m));
    final latitude = location.latitude * degreesToRadians;
    final declination = math.asin(
      sinDegrees(23.439291 - 0.0130042 * t) *
          sinDegrees(l0 + 1.9146 * sinDegrees(m)),
    );
    const zenith = 90.833 * degreesToRadians;
    final cosineHourAngle =
        (math.cos(zenith) - math.sin(latitude) * math.sin(declination)) /
            (math.cos(latitude) * math.cos(declination));
    if (cosineHourAngle.abs() > 1) return null;
    final hourAngle = math.acos(cosineHourAngle) * radiansToDegrees;
    final minutesUtc = 720 -
        4 * (location.longitude + (rise ? hourAngle : -hourAngle)) -
        equationTime;
    return utcDate.add(Duration(minutes: minutesUtc.round()));
  }

  DateTime? _moonEvent(
    DateTime localDate,
    PanchangLocation location,
    bool rise,
  ) {
    final startLocal = DateTime.utc(localDate.year, localDate.month, localDate.day);
    final startUtc = startLocal.subtract(location.utcOffset).toUtc();
    double altitude(DateTime utc) {
      final moon = astronomy.moon(utc);
      final d = julianDay(utc) - 2451545.0;
      final t = d / 36525;
      final sidereal = normalizeDegrees(
        280.46061837 +
            360.98564736629 * d +
            0.000387933 * t * t -
            t * t * t / 38710000 +
            location.longitude,
      );
      final hourAngle = (sidereal - moon.rightAscension) * degreesToRadians;
      final latitude = location.latitude * degreesToRadians;
      final declination = moon.declination * degreesToRadians;
      final value = math.asin(
        math.sin(latitude) * math.sin(declination) +
            math.cos(latitude) * math.cos(declination) * math.cos(hourAngle),
      ) * radiansToDegrees;
      return value + 0.125;
    }

    var previousTime = startUtc;
    var previous = altitude(previousTime);
    for (var minute = 5; minute <= 24 * 60; minute += 5) {
      final time = startUtc.add(Duration(minutes: minute));
      final current = altitude(time);
      final crossed = rise
          ? previous < 0 && current >= 0
          : previous >= 0 && current < 0;
      if (crossed) {
        var low = previousTime;
        var high = time;
        for (var i = 0; i < 20; i++) {
          final middle = low.add(
            Duration(milliseconds: high.difference(low).inMilliseconds ~/ 2),
          );
          if ((altitude(middle) >= 0) == rise) {
            high = middle;
          } else {
            low = middle;
          }
        }
        return high;
      }
      previous = current;
      previousTime = time;
    }
    return null;
  }

  String _karana(int halfTithi) {
    if (halfTithi == 0) return 'Kimstughna';
    if (halfTithi >= 57) return ['Shakuni', 'Chatushpada', 'Naga'][halfTithi - 57];
    return _karanas[(halfTithi - 1) % _karanas.length];
  }

  int _lunarMonthIndex(
    DateTime utc,
    int tithiIndex,
    LunarMonthSystem monthSystem,
  ) {
    var later = utc;
    var laterAngle = _elongation(later);
    for (var hours = 6; hours <= 24 * 32; hours += 6) {
      final earlier = utc.subtract(Duration(hours: hours));
      final earlierAngle = _elongation(earlier);
      if (earlierAngle > 300 && laterAngle < 60) {
        final target = 360 - earlierAngle;
        final root = interpolateCrossing(
          earlier.millisecondsSinceEpoch.toDouble(),
          later.millisecondsSinceEpoch.toDouble(),
          (millis) => angularDistance(
            earlierAngle,
            _elongation(
              DateTime.fromMillisecondsSinceEpoch(millis.round(), isUtc: true),
            ),
          ),
          target,
        );
        final newMoon = DateTime.fromMillisecondsSinceEpoch(
          root.round(),
          isUtc: true,
        );
        final solarLongitude = normalizeDegrees(
          astronomy.solarLongitude(newMoon) -
              astronomy.lahiriAyanamsa(newMoon),
        );
        final month = ((solarLongitude / 30).floor() + 1) % 12;
        return monthSystem == LunarMonthSystem.purnimanta && tithiIndex >= 15
            ? (month + 1) % 12
            : month;
      }
      later = earlier;
      laterAngle = earlierAngle;
    }
    throw StateError('Could not find the preceding new moon.');
  }

  String lunarMonth(
    DateTime utc,
    int tithiIndex, {
    LunarMonthSystem system = LunarMonthSystem.amanta,
  }) {
    final monthIndex = _lunarMonthIndex(utc, tithiIndex, system);
    return _lunarMonths[monthIndex];
  }

  /* Kept separate from display strings so Gujarati-year calculation follows
     the amanta month even when the displayed month is purnimanta. */
  int _amantaMonthIndex(DateTime utc, int tithiIndex) =>
      _lunarMonthIndex(utc, tithiIndex, LunarMonthSystem.amanta);

  TimeWindow? _dayPart(DateTime? sunrise, DateTime? sunset, int weekdayIndex,
      int partIndex) {
    if (sunrise == null || sunset == null) return null;
    const rahu = [1, 6, 4, 5, 3, 2, 7];
    const gulika = [5, 4, 3, 2, 1, 0, 6];
    const yama = [3, 2, 1, 0, 6, 5, 4];
    final selected = switch (partIndex) {
      0 => rahu[weekdayIndex],
      1 => gulika[weekdayIndex],
      _ => yama[weekdayIndex],
    };
    final dayLength = sunset.difference(sunrise);
    final start = sunrise.add(Duration(
      milliseconds: dayLength.inMilliseconds * selected ~/ 8,
    ));
    final end = sunrise.add(Duration(
      milliseconds: dayLength.inMilliseconds * (selected + 1) ~/ 8,
    ));
    return TimeWindow(start, end);
  }

  PanchangDay calculate(
    DateTime localDate,
    PanchangLocation location, {
    LunarMonthSystem monthSystem = LunarMonthSystem.amanta,
    bool includeMoonEvents = true,
  }) {
    final date = DateTime.utc(localDate.year, localDate.month, localDate.day);
    final sunriseUtc = _solarEvent(date, location, true);
    final sunsetUtc = _solarEvent(date, location, false);
    final sunrise = sunriseUtc?.add(location.utcOffset);
    final sunset = sunsetUtc?.add(location.utcOffset);
    final moonrise = includeMoonEvents
        ? _moonEvent(date, location, true)?.add(location.utcOffset)
        : null;
    final moonset = includeMoonEvents
        ? _moonEvent(date, location, false)?.add(location.utcOffset)
        : null;
    final calculationInstant = (sunrise ?? date.add(const Duration(hours: 12)))
        .subtract(location.utcOffset)
        .toUtc();
    final elongation = _elongation(calculationInstant);
    final tithiIndex = (elongation / 12).floor();
    final tithiStartUtc = _previousCrossing(calculationInstant, _elongation, 12);
    final tithiEndUtc = _nextCrossing(calculationInstant, _elongation, 12);
    final siderealLongitude = (DateTime utc) => normalizeDegrees(
          astronomy.lunarLongitude(utc) - astronomy.lahiriAyanamsa(utc),
        );
    final siderealMoon = normalizeDegrees(
      siderealLongitude(calculationInstant),
    );
    final nakshatraSize = 360 / 27;
    final nakshatraIndex = (siderealMoon / nakshatraSize).floor();
    final pada = ((siderealMoon % nakshatraSize) / (nakshatraSize / 4)).floor() + 1;
    final nakshatraStartUtc =
        _previousCrossing(calculationInstant, siderealLongitude, nakshatraSize);
    final nakshatraEndUtc =
        _nextCrossing(calculationInstant, siderealLongitude, nakshatraSize);
    final yogaLongitude = (DateTime utc) => normalizeDegrees(
          astronomy.lunarLongitude(utc) -
              astronomy.lahiriAyanamsa(utc) +
              astronomy.solarLongitude(utc) -
              astronomy.lahiriAyanamsa(utc),
        );
    final sum = normalizeDegrees(
      yogaLongitude(calculationInstant),
    );
    final yogaStartUtc =
        _previousCrossing(calculationInstant, yogaLongitude, nakshatraSize);
    final yogaEndUtc = _nextCrossing(calculationInstant, yogaLongitude, nakshatraSize);
    final karanaStartUtc = _previousCrossing(calculationInstant, _elongation, 6);
    final karanaEndUtc = _nextCrossing(calculationInstant, _elongation, 6);
    final localWeekday = date.weekday;
    final weekdayNames = [
      'Somavara',
      'Mangalavara',
      'Budhavara',
      'Guruvara',
      'Shukravara',
      'Shanivara',
      'Ravivara',
    ];
    final weekdayIndex = (localWeekday + 6) % 7;
    final dayLength = sunrise != null && sunset != null
        ? sunset.difference(sunrise)
        : Duration.zero;
    final abhijit = sunrise == null || sunset == null
        ? null
        : TimeWindow(
            sunrise.add(Duration(
              milliseconds: dayLength.inMilliseconds * 7 ~/ 15,
            )),
            sunrise.add(Duration(
              milliseconds: dayLength.inMilliseconds * 8 ~/ 15,
            )),
          );
    final amantaMonthIndex = _amantaMonthIndex(calculationInstant, tithiIndex);
    final displayMonthIndex =
        monthSystem == LunarMonthSystem.purnimanta && tithiIndex >= 15
            ? (amantaMonthIndex + 1) % _lunarMonths.length
            : amantaMonthIndex;
    final vikramYear = date.year + (amantaMonthIndex >= 7 ? 57 : 56);
    final shakaYear = date.year - (amantaMonthIndex >= 9 ? 79 : 78);
    return PanchangDay(
      date: date,
      location: location,
      sunrise: sunrise,
      sunset: sunset,
      moonrise: moonrise,
      moonset: moonset,
      tithi: _tithis[tithiIndex],
      tithiStart: tithiStartUtc.add(location.utcOffset),
      tithiEnd: tithiEndUtc.add(location.utcOffset),
      nakshatra: _nakshatras[nakshatraIndex],
      nakshatraPada: pada,
      nakshatraStart: nakshatraStartUtc.add(location.utcOffset),
      nakshatraEnd: nakshatraEndUtc.add(location.utcOffset),
      yoga: _yogas[(sum / nakshatraSize).floor()],
      yogaStart: yogaStartUtc.add(location.utcOffset),
      yogaEnd: yogaEndUtc.add(location.utcOffset),
      karana: _karana(tithiIndex * 2 + (elongation % 12 >= 6 ? 1 : 0)),
      karanaStart: karanaStartUtc.add(location.utcOffset),
      karanaEnd: karanaEndUtc.add(location.utcOffset),
      vara: weekdayNames[weekdayIndex],
      rahuKaal: _dayPart(sunrise, sunset, weekdayIndex, 0),
      gulikaKaal: _dayPart(sunrise, sunset, weekdayIndex, 1),
      yamaganda: _dayPart(sunrise, sunset, weekdayIndex, 2),
      abhijit: abhijit,
      lunarMonth: _lunarMonths[displayMonthIndex],
      vikramSamvat: vikramYear,
      shakaSamvat: shakaYear,
    );
  }
}
