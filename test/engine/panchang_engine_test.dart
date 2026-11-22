import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panchang/engine/panchang_engine.dart';

void main() {
  final fixture = jsonDecode(
    File('test/data/almanac_references.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final published = fixture['published'] as Map<String, dynamic>;

  test('matches published Ahmedabad Panchang within ten minutes', () {
    final day = const PanchangEngine().calculate(
      DateTime(2026, 3, 20),
      PanchangLocation.ahmedabad,
    );

    final comparisons = <(String, DateTime, String)>[
      ('Sunrise', day.sunrise!, published['sunrise'] as String),
      ('Sunset', day.sunset!, published['sunset'] as String),
      ('Moonrise', day.moonrise!, published['moonrise'] as String),
      ('Moonset', day.moonset!, published['moonset'] as String),
      ('Rahu start', day.rahuKaal!.start, published['rahuStart'] as String),
      ('Rahu end', day.rahuKaal!.end, published['rahuEnd'] as String),
      ('Gulika start', day.gulikaKaal!.start, published['gulikaStart'] as String),
      ('Gulika end', day.gulikaKaal!.end, published['gulikaEnd'] as String),
      ('Yamaganda start', day.yamaganda!.start, published['yamagandaStart'] as String),
      ('Yamaganda end', day.yamaganda!.end, published['yamagandaEnd'] as String),
      ('Abhijit start', day.abhijit!.start, published['abhijitStart'] as String),
      ('Abhijit end', day.abhijit!.end, published['abhijitEnd'] as String),
    ];
    print('Reference comparison (engine minus Drik Panchang, minutes)');
    print('| Quantity | Published | Engine | Difference |');
    print('| --- | ---: | ---: | ---: |');
    for (final (label, actual, expected) in comparisons) {
      final difference = _signedClockDifference(actual, expected);
      print(
        '| $label | $expected | ${_formatClock(actual)} | ${difference >= 0 ? '+' : ''}$difference |',
      );
    }
    for (final (label, actual, expected) in <(String, DateTime, String)>[
      ('Tithi end', day.tithiEnd, published['tithiEnd'] as String),
      ('Nakshatra end', day.nakshatraEnd, published['nakshatraEnd'] as String),
    ]) {
      final difference = _signedDateTimeDifference(actual, expected);
      print(
        '| $label | ${expected.replaceFirst('T', ' ')} | '
        '${actual.year}-${actual.month.toString().padLeft(2, '0')}-'
        '${actual.day.toString().padLeft(2, '0')} ${_formatClock(actual)} | '
        '${difference >= 0 ? '+' : ''}$difference |',
      );
    }

    expect(_clockDifference(day.sunrise!, published['sunrise'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.sunset!, published['sunset'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.moonrise!, published['moonrise'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.moonset!, published['moonset'] as String), lessThanOrEqualTo(10));
    expect(day.tithi, published['tithi']);
    expect(day.nakshatra, published['nakshatra']);
    expect(day.shakaSamvat, published['shakaSamvat']);
    expect(_dateTimeDifference(day.tithiEnd, published['tithiEnd'] as String), lessThanOrEqualTo(10));
    expect(_dateTimeDifference(day.nakshatraEnd, published['nakshatraEnd'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.rahuKaal!.start, published['rahuStart'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.rahuKaal!.end, published['rahuEnd'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.gulikaKaal!.start, published['gulikaStart'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.gulikaKaal!.end, published['gulikaEnd'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.yamaganda!.start, published['yamagandaStart'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.yamaganda!.end, published['yamagandaEnd'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.abhijit!.start, published['abhijitStart'] as String), lessThanOrEqualTo(10));
    expect(_clockDifference(day.abhijit!.end, published['abhijitEnd'] as String), lessThanOrEqualTo(10));
  });

  test('produces normalized celestial longitudes and a valid pada', () {
    final day = const PanchangEngine().calculate(
      DateTime(2026, 3, 20),
      PanchangLocation.ahmedabad,
      includeMoonEvents: false,
    );

    expect(day.nakshatraPada, inInclusiveRange(1, 4));
    expect(day.tithiEnd.isAfter(day.sunrise!), isTrue);
    expect(day.rahuKaal!.end.difference(day.rahuKaal!.start).inMinutes, closeTo(91, 2));
  });

  test('matches the published Gujarati Samvat and amanta month', () {
    final reference = jsonDecode(
      File('test/data/ahmedabad_2026_11_22.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final published = reference['published'] as Map<String, dynamic>;
    final day = const PanchangEngine().calculate(
      DateTime(2026, 11, 22),
      PanchangLocation.ahmedabad,
      includeMoonEvents: false,
    );

    expect(day.tithi, published['tithi']);
    expect(day.lunarMonth, published['lunarMonth']);
    expect(day.vikramSamvat, published['vikramSamvat']);
    expect(day.shakaSamvat, published['shakaSamvat']);
    expect(
      _clockDifference(day.sunrise!, published['sunrise'] as String),
      lessThanOrEqualTo(10),
    );
    expect(
      _clockDifference(day.sunset!, published['sunset'] as String),
      lessThanOrEqualTo(10),
    );
    expect(
      _dateTimeDifference(day.tithiEnd, published['tithiEnd'] as String),
      lessThanOrEqualTo(10),
    );
    expect(
      _dateTimeDifference(
        day.nakshatraEnd,
        published['nakshatraEnd'] as String,
      ),
      lessThanOrEqualTo(10),
    );
    expect(
      _clockDifference(day.rahuKaal!.start, published['rahuStart'] as String),
      lessThanOrEqualTo(10),
    );
    expect(
      _clockDifference(day.rahuKaal!.end, published['rahuEnd'] as String),
      lessThanOrEqualTo(10),
    );
    expect(
      _clockDifference(
        day.gulikaKaal!.start,
        published['gulikaStart'] as String,
      ),
      lessThanOrEqualTo(10),
    );
    expect(
      _clockDifference(
        day.gulikaKaal!.end,
        published['gulikaEnd'] as String,
      ),
      lessThanOrEqualTo(10),
    );
    expect(
      _clockDifference(
        day.yamaganda!.start,
        published['yamagandaStart'] as String,
      ),
      lessThanOrEqualTo(10),
    );
    expect(
      _clockDifference(
        day.yamaganda!.end,
        published['yamagandaEnd'] as String,
      ),
      lessThanOrEqualTo(10),
    );
  });

  test('supports dates with no sunrise or sunset at polar locations', () {
    const polarLocation = PanchangLocation(
      name: 'North Pole',
      latitude: 90,
      longitude: 0,
      utcOffset: Duration.zero,
    );
    final day = const PanchangEngine().calculate(
      DateTime(2026, 6, 21),
      polarLocation,
      includeMoonEvents: false,
    );

    expect(day.sunrise, isNull);
    expect(day.sunset, isNull);
    expect(day.rahuKaal, isNull);
  });
}

int _clockDifference(DateTime value, String clock) {
  return _signedClockDifference(value, clock).abs();
}

int _signedClockDifference(DateTime value, String clock) {
  final parts = clock.split(':').map(int.parse).toList();
  final expected = DateTime.utc(value.year, value.month, value.day, parts[0], parts[1]);
  return value.difference(expected).inMinutes;
}

int _dateTimeDifference(DateTime value, String reference) {
  return _signedDateTimeDifference(value, reference).abs();
}

int _signedDateTimeDifference(DateTime value, String reference) =>
    value.difference(DateTime.parse('${reference}Z')).inMinutes;

String _formatClock(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
