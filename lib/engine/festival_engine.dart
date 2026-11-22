import 'panchang_engine.dart';

class Festival {
  const Festival(this.name, this.reason);

  final String name;
  final String reason;
}

class FestivalEngine {
  const FestivalEngine();

  static const _rules = <(String, String, String)>[
    ('Magha', 'Shukla Panchami', 'Vasant Panchami'),
    ('Magha', 'Shukla Saptami', 'Ratha Saptami'),
    ('Magha', 'Krishna Chaturdashi', 'Maha Shivaratri'),
    ('Phalguna', 'Purnima', 'Holi / Holika Dahan'),
    ('Chaitra', 'Shukla Pratipada', 'Chaitra Navratri begins'),
    ('Chaitra', 'Shukla Navami', 'Rama Navami'),
    ('Chaitra', 'Purnima', 'Hanuman Jayanti'),
    ('Vaishakha', 'Shukla Tritiya', 'Akshaya Tritiya'),
    ('Vaishakha', 'Purnima', 'Buddha Purnima'),
    ('Jyeshtha', 'Shukla Dashami', 'Ganga Dussehra'),
    ('Jyeshtha', 'Amavasya', 'Vat Savitri Amavasya'),
    ('Ashadha', 'Shukla Dwitiya', 'Jagannath Ratha Yatra'),
    ('Ashadha', 'Purnima', 'Guru Purnima'),
    ('Shravana', 'Shukla Panchami', 'Nag Panchami'),
    ('Shravana', 'Purnima', 'Raksha Bandhan'),
    ('Bhadrapada', 'Shukla Chaturthi', 'Ganesh Chaturthi'),
    ('Bhadrapada', 'Krishna Ashtami', 'Janmashtami'),
    ('Bhadrapada', 'Shukla Chaturdashi', 'Anant Chaturdashi'),
    ('Ashwin', 'Shukla Pratipada', 'Sharad Navratri begins'),
    ('Ashwin', 'Shukla Dashami', 'Dussehra / Vijayadashami'),
    ('Ashwin', 'Purnima', 'Sharad Purnima'),
    ('Kartika', 'Krishna Trayodashi', 'Dhanteras'),
    ('Kartika', 'Krishna Chaturdashi', 'Naraka Chaturdashi'),
    ('Kartika', 'Amavasya', 'Diwali / Lakshmi Puja'),
    ('Kartika', 'Shukla Pratipada', 'Bestu Varas / Gujarati New Year'),
    ('Kartika', 'Shukla Dwitiya', 'Bhai Beej'),
    ('Kartika', 'Shukla Ekadashi', 'Dev Uthani Ekadashi / Tulsi Vivah'),
    ('Kartika', 'Shukla Shashthi', 'Chhath Puja'),
    ('Margashirsha', 'Shukla Ekadashi', 'Gita Jayanti / Mokshada Ekadashi'),
    ('Margashirsha', 'Purnima', 'Dattatreya Jayanti'),
    ('Pausha', 'Shukla Ekadashi', 'Putrada Ekadashi'),
    ('Phalguna', 'Shukla Ekadashi', 'Amalaki Ekadashi'),
    ('Ashadha', 'Shukla Ekadashi', 'Devshayani Ekadashi'),
  ];

  List<Festival> forDay(PanchangDay day) {
    final result = <Festival>[];
    final tithi = day.tithi;
    final pakshaTithi = tithi.replaceFirst('Shukla ', '').replaceFirst('Krishna ', '');
    for (final (month, ruleTithi, name) in _rules) {
      if (day.lunarMonth == month && tithi == ruleTithi) {
        result.add(Festival(
          name,
          '$month + $ruleTithi at local sunrise',
        ));
      }
    }

    if (tithi.endsWith('Ekadashi')) {
      result.add(Festival('Ekadashi Vrat', '$tithi at local sunrise'));
    }
    if (pakshaTithi == 'Purnima') {
      result.add(Festival('Purnima Vrat', 'Full-moon tithi at local sunrise'));
    } else if (pakshaTithi == 'Amavasya') {
      result.add(Festival('Amavasya Vrat', 'New-moon tithi at local sunrise'));
    } else if (pakshaTithi.endsWith('Chaturthi')) {
      result.add(Festival('Sankashti / Vinayaka Chaturthi', '$tithi at local sunrise'));
    }

    if (day.date.month == 1 && day.date.day == 14) {
      result.add(const Festival(
        'Uttarayan / Makar Sankranti',
        'Traditional fixed-date observance on 14 January',
      ));
    }
    return result;
  }
}
