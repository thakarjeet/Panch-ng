import 'package:flutter_test/flutter_test.dart';
import 'package:panchang/engine/festival_engine.dart';
import 'package:panchang/engine/panchang_engine.dart';

void main() {
  const festivals = FestivalEngine();

  test('derives Bestu Varas from Kartika Shukla Pratipada', () {
    final observances = festivals.forDay(_day(
      date: DateTime.utc(2026, 11, 10),
      month: 'Kartika',
      tithi: 'Shukla Pratipada',
    ));

    final bestuVaras = observances.singleWhere(
      (festival) => festival.name == 'Bestu Varas / Gujarati New Year',
    );
    expect(bestuVaras.reason, 'Kartika + Shukla Pratipada at local sunrise');
  });

  test('adds recurring Ekadashi vrat in any lunar month', () {
    final observances = festivals.forDay(_day(
      date: DateTime.utc(2026, 4, 2),
      month: 'Chaitra',
      tithi: 'Krishna Ekadashi',
    ));

    expect(
      observances.map((festival) => festival.name),
      contains('Ekadashi Vrat'),
    );
  });

  test('includes fixed-date Uttarayan', () {
    final observances = festivals.forDay(_day(
      date: DateTime.utc(2026, 1, 14),
      month: 'Pausha',
      tithi: 'Krishna Ekadashi',
    ));

    expect(
      observances.map((festival) => festival.name),
      contains('Uttarayan / Makar Sankranti'),
    );
  });
}

PanchangDay _day({
  required DateTime date,
  required String month,
  required String tithi,
}) =>
    PanchangDay(
      date: date,
      location: PanchangLocation.ahmedabad,
      sunrise: null,
      sunset: null,
      moonrise: null,
      moonset: null,
      tithi: tithi,
      tithiStart: date,
      tithiEnd: date.add(const Duration(hours: 12)),
      nakshatra: 'Ashwini',
      nakshatraPada: 1,
      nakshatraStart: date,
      nakshatraEnd: date.add(const Duration(hours: 12)),
      yoga: 'Siddha',
      yogaStart: date,
      yogaEnd: date.add(const Duration(hours: 12)),
      karana: 'Bava',
      karanaStart: date,
      karanaEnd: date.add(const Duration(hours: 6)),
      vara: 'Somavara',
      rahuKaal: null,
      gulikaKaal: null,
      yamaganda: null,
      abhijit: null,
      lunarMonth: month,
      vikramSamvat: date.year + 57,
      shakaSamvat: date.year - 78,
    );
