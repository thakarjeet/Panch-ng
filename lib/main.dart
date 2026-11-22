import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalMaterialLocalizations;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'app_text.dart';
import 'engine/festival_engine.dart';
import 'engine/panchang_engine.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting().then((_) => runApp(const PanchangApp()));
}

class PanchangApp extends StatefulWidget {
  const PanchangApp({super.key});

  @override
  State<PanchangApp> createState() => _PanchangAppState();
}

class _PanchangAppState extends State<PanchangApp> {
  AppLanguage _language = AppLanguage.gujarati;
  LunarMonthSystem _monthSystem = LunarMonthSystem.amanta;
  PanchangLocation _location = PanchangLocation.ahmedabad;
  int _tab = 0;
  final PageController _pageController = PageController();
  DateTime _date = DateTime.now();
  TimeOfDay _morningReminder = const TimeOfDay(hour: 6, minute: 30);
  TimeOfDay _festivalReminder = const TimeOfDay(hour: 19, minute: 0);
  final Map<String, PanchangDay> _cache = {};

  AppText get text => AppText(_language);

  @override
  void initState() {
    super.initState();
    _restoreSettings();
  }

  Future<void> _restoreSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final language = AppLanguage.values[preferences.getInt('language') ?? 0];
    final monthSystem =
        LunarMonthSystem.values[preferences.getInt('monthSystem') ?? 0];
    final latitude = preferences.getDouble('latitude');
    final longitude = preferences.getDouble('longitude');
    final offsetMinutes = preferences.getInt('utcOffsetMinutes');
    final morningMinutes = preferences.getInt('morningReminderMinutes') ?? 390;
    final festivalMinutes = preferences.getInt('festivalReminderMinutes') ?? 1140;
    if (!mounted) return;
    setState(() {
      _language = language;
      _monthSystem = monthSystem;
      _morningReminder = TimeOfDay(
        hour: morningMinutes ~/ 60,
        minute: morningMinutes % 60,
      );
      _festivalReminder = TimeOfDay(
        hour: festivalMinutes ~/ 60,
        minute: festivalMinutes % 60,
      );
      if (latitude != null && longitude != null && offsetMinutes != null) {
        _location = PanchangLocation(
          name: preferences.getString('locationName') ?? 'Saved location',
          latitude: latitude,
          longitude: longitude,
          utcOffset: Duration(minutes: offsetMinutes),
        );
      }
    });
  }

  Future<void> _savePreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt('language', _language.index);
    await preferences.setInt('monthSystem', _monthSystem.index);
    await preferences.setString('locationName', _location.name);
    await preferences.setDouble('latitude', _location.latitude);
    await preferences.setDouble('longitude', _location.longitude);
    await preferences.setInt(
      'utcOffsetMinutes',
      _location.utcOffset.inMinutes,
    );
    await preferences.setInt(
      'morningReminderMinutes',
      _morningReminder.hour * 60 + _morningReminder.minute,
    );
    await preferences.setInt(
      'festivalReminderMinutes',
      _festivalReminder.hour * 60 + _festivalReminder.minute,
    );
    _cache.clear();
  }

  PanchangDay _day(DateTime date) {
    final key =
        '${date.year}-${date.month}-${date.day}-${_location.latitude}-${_location.longitude}-${_location.utcOffset.inMinutes}-${_monthSystem.index}';
    return _cache.putIfAbsent(
      key,
      () => const PanchangEngine().calculate(
        date,
        _location,
        monthSystem: _monthSystem,
      ),
    );
  }

  void _updateLocation(PanchangLocation location) {
    setState(() {
      _location = location;
      _cache.clear();
    });
    _savePreferences();
  }

  void _updateLanguage(AppLanguage language) {
    setState(() => _language = language);
    _savePreferences();
  }

  void _updateMonthSystem(LunarMonthSystem system) {
    setState(() {
      _monthSystem = system;
      _cache.clear();
    });
    _savePreferences();
  }

  void _updateReminderTimes(TimeOfDay morning, TimeOfDay festival) {
    setState(() {
      _morningReminder = morning;
      _festivalReminder = festival;
    });
    _savePreferences();
  }

  void _goToTab(int index) {
    if (index == _tab) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (_tab != index) setState(() => _tab = index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Intl.defaultLocale = switch (_language) {
      AppLanguage.gujarati => 'gu',
      AppLanguage.hindi => 'hi',
      AppLanguage.english => 'en',
    };
    final font = switch (_language) {
      AppLanguage.gujarati => 'NotoGujarati',
      AppLanguage.hindi => 'NotoDevanagari',
      AppLanguage.english => null,
    };
    return MaterialApp(
      title: 'Panchang',
      debugShowCheckedModeBanner: false,
      locale: Locale(switch (_language) {
        AppLanguage.gujarati => 'gu',
        AppLanguage.hindi => 'hi',
        AppLanguage.english => 'en',
      }),
      supportedLocales: const [Locale('gu'), Locale('hi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xffeda83d),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xff23365e),
          secondary: const Color(0xff2e9182),
          tertiary: const Color(0xffe6a543),
          surface: const Color(0xfffffbf4),
        ),
        useMaterial3: true,
        fontFamily: font,
        scaffoldBackgroundColor: const Color(0xfff3f5f4),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.96),
          indicatorColor: const Color(0xffffe8b8),
          elevation: 8,
          shadowColor: const Color(0xff23365e).withValues(alpha: 0.12),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: _onPageChanged,
            children: [
              TodayScreen(
                day: _day(_date),
                text: text,
                onShare: () => _share(_day(_date), text),
                onChooseDate: _chooseDate,
              ),
              CalendarScreen(
                selectedDate: _date,
                location: _location,
                monthSystem: _monthSystem,
                text: text,
                dayFor: _day,
                onSelect: (date) {
                  setState(() => _date = date);
                  _goToTab(0);
                },
              ),
              MuhuratScreen(location: _location, text: text),
              SettingsScreen(
                language: _language,
                location: _location,
                monthSystem: _monthSystem,
                morningReminder: _morningReminder,
                festivalReminder: _festivalReminder,
                text: text,
                onLanguage: _updateLanguage,
                onLocation: _updateLocation,
                onMonthSystem: _updateMonthSystem,
                onReminderTimes: _updateReminderTimes,
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _goToTab,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.wb_sunny_outlined),
              selectedIcon: const Icon(Icons.wb_sunny),
              label: text['today'],
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: text['calendar'],
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome),
              label: text['muhurat'],
            ),
            NavigationDestination(
              icon: const Icon(Icons.tune),
              label: text['settings'],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _share(PanchangDay day, AppText text) async {
    final key = GlobalKey();
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (dialogContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final renderObject = key.currentContext?.findRenderObject();
          if (renderObject is! RenderRepaintBoundary) {
            Navigator.pop(dialogContext);
            return;
          }
          final image = await renderObject.toImage(pixelRatio: 2);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          if (dialogContext.mounted && byteData != null) {
            Navigator.pop(
              dialogContext,
              byteData.buffer.asUint8List(
                byteData.offsetInBytes,
                byteData.lengthInBytes,
              ),
            );
          }
        });
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: key,
              child: PanchangShareCard(day: day, text: text),
            ),
          ),
        );
      },
    );
    if (bytes == null || !mounted) return;
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/panchang-${day.date.toIso8601String()}.png');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'Today’s Panchang');
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.day,
    required this.text,
    required this.onShare,
    required this.onChooseDate,
    super.key,
  });

  final PanchangDay day;
  final AppText text;
  final VoidCallback onShare;
  final VoidCallback onChooseDate;

  @override
  Widget build(BuildContext context) {
    final festivals = const FestivalEngine().forDay(day);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          floating: true,
          surfaceTintColor: Colors.transparent,
          title: _brandTitle(text['today']),
          actions: [
            IconButton(
              tooltip: text['date'],
              onPressed: onChooseDate,
              icon: const Icon(Icons.event),
            ),
            IconButton(
              tooltip: text['share'],
              onPressed: onShare,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList.list(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 440),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.045),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: PanchangShareCard(
                  key: ValueKey(
                    '${day.date.toIso8601String()}-${day.location.latitude}-${day.location.longitude}',
                  ),
                  day: day,
                  text: text,
                ),
              ),
              const SizedBox(height: 16),
              _SunArc(day: day, text: text),
              const SizedBox(height: 16),
              _sectionTitle(context, text['festivals']),
              if (festivals.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.spa_outlined),
                    title: Text('No major observance listed'),
                  ),
                )
              else
                ...festivals.map(
                  (festival) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.local_florist_outlined),
                      title: Text(text.festival(festival.name)),
                      subtitle: Text(festival.reason),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _sectionTitle(context, text['time_windows']),
              _timeBar(
                context,
                text['rahu'],
                day.rahuKaal,
                day.sunrise,
                day.sunset,
                Colors.red.shade300,
              ),
              _timeBar(
                context,
                text['gulika'],
                day.gulikaKaal,
                day.sunrise,
                day.sunset,
                Colors.deepOrange.shade200,
              ),
              _timeBar(
                context,
                text['yamaganda'],
                day.yamaganda,
                day.sunrise,
                day.sunset,
                Colors.brown.shade300,
              ),
              _timeBar(
                context,
                text['abhijit'],
                day.abhijit,
                day.sunrise,
                day.sunset,
                Colors.green.shade300,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}

class PanchangShareCard extends StatelessWidget {
  const PanchangShareCard({required this.day, required this.text, super.key});

  final PanchangDay day;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMMEEEEd().format(day.date);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffe6a543).withValues(alpha: 0.23),
            blurRadius: 28,
            spreadRadius: -10,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xff2e9182).withValues(alpha: 0.13),
            blurRadius: 34,
            spreadRadius: -12,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Card(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff192748), Color(0xff253c67), Color(0xff17635e)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/brand/panchang_logo.png',
                    width: 42,
                    height: 42,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PANCHANG',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              letterSpacing: 2.2,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xffffd477),
                            ),
                      ),
                      Text(
                        day.location.name,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                date,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                text.tithi(day.tithi),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xffffd477),
                      shadows: const [
                        Shadow(
                          color: Color(0x55ffc451),
                          blurRadius: 18,
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                '${text.nakshatra(day.nakshatra)} · Pada ${day.nakshatraPada}',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 3),
              Text(
                '${_clock(day.tithiStart)}–${_clock(day.tithiEnd)} · '
                '${_clock(day.nakshatraStart)}–${_clock(day.nakshatraEnd)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 12,
                ),
              ),
              Divider(
                height: 27,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _inlineTime(text['sunrise'], day.sunrise),
                  _inlineTime(text['sunset'], day.sunset),
                  Text(
                    '${text.month(day.lunarMonth)} · VS ${day.vikramSamvat}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Offline astronomy',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inlineTime(String label, DateTime? time) => Text(
        '$label ${_clock(time)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _SunArc extends StatelessWidget {
  const _SunArc({required this.day, required this.text});

  final PanchangDay day;
  final AppText text;

  @override
  Widget build(BuildContext context) {
    final sunrise = day.sunrise;
    final sunset = day.sunset;
    final now = DateTime.now();
    final nowWall = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    final progress = sunrise == null || sunset == null
        ? 0.0
        : day.date.year == now.year &&
                day.date.month == now.month &&
                day.date.day == now.day
            ? (nowWall.difference(sunrise).inMilliseconds /
                    sunset.difference(sunrise).inMilliseconds)
                .clamp(0.0, 1.0)
                .toDouble()
            : 0.5;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          children: [
            SizedBox(
              height: 116,
              width: double.infinity,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 900),
                builder: (context, sunProgress, child) => CustomPaint(
                  painter: _SunArcPainter(
                    color: Theme.of(context).colorScheme.primary,
                    progress: sunProgress,
                  ),
                  child: child,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${text['sunrise']}\n${_clock(day.sunrise)}'),
                Text(
                  '${text['sunset']}\n${_clock(day.sunset)}',
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${text['moonrise']} ${_clock(day.moonrise)}'),
                Text('${text['moonset']} ${_clock(day.moonset)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SunArcPainter extends CustomPainter {
  const _SunArcPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(12, size.height - 8)
      ..quadraticBezierTo(size.width / 2, -size.height * 0.75, size.width - 12,
          size.height - 8);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xffe6a543).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 13
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffe6a543), Color(0xff3d9b8a)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final start = Offset(12, size.height - 8);
    final control = Offset(size.width / 2, -size.height * 0.75);
    final end = Offset(size.width - 12, size.height - 8);
    final inverse = 1 - progress;
    final sun = Offset(
      inverse * inverse * start.dx +
          2 * inverse * progress * control.dx +
          progress * progress * end.dx,
      inverse * inverse * start.dy +
          2 * inverse * progress * control.dy +
          progress * progress * end.dy,
    );
    canvas.drawCircle(
      sun,
      18,
      Paint()
        ..color = const Color(0xffffc451).withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      sun,
      8,
      Paint()..color = const Color(0xffffc451),
    );
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.selectedDate,
    required this.location,
    required this.monthSystem,
    required this.text,
    required this.dayFor,
    required this.onSelect,
    super.key,
  });

  final DateTime selectedDate;
  final PanchangLocation location;
  final LunarMonthSystem monthSystem;
  final AppText text;
  final PanchangDay Function(DateTime) dayFor;
  final ValueChanged<DateTime> onSelect;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late Future<List<PanchangDay>> _days;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _days = _loadMonth();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    var reload = oldWidget.location != widget.location ||
        oldWidget.monthSystem != widget.monthSystem;
    if (oldWidget.selectedDate.year != widget.selectedDate.year ||
        oldWidget.selectedDate.month != widget.selectedDate.month) {
      _month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
      reload = true;
    }
    if (reload) {
      _days = _loadMonth();
    }
  }

  Future<List<PanchangDay>> _loadMonth() async {
    final first = DateTime(_month.year, _month.month);
    final firstGridDay = first.subtract(Duration(days: first.weekday - 1));
    final days = <PanchangDay>[];
    for (var index = 0; index < 42; index++) {
      days.add(const PanchangEngine().calculate(
            firstGridDay.add(Duration(days: index)),
            widget.location,
            monthSystem: widget.monthSystem,
            includeMoonEvents: false,
          ));
      if (index % 6 == 5) await Future<void>.delayed(Duration.zero);
    }
    return days;
  }

  void _shiftMonth(int amount) {
    setState(() {
      _month = DateTime(_month.year, _month.month + amount);
      _days = _loadMonth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          floating: true,
          surfaceTintColor: Colors.transparent,
          title: _brandTitle(widget.text['calendar']),
          actions: [
            IconButton(
              onPressed: () => _shiftMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              onPressed: () => _shiftMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              Text(
                DateFormat.yMMMM().format(_month),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<PanchangDay>>(
                future: _days,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final days = snapshot.data!;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: days.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.76,
                    ),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      final inMonth = day.date.month == _month.month;
                      final festivals = const FestivalEngine().forDay(day);
                      final isSelected =
                          day.date.day == widget.selectedDate.day &&
                          day.date.month == widget.selectedDate.month &&
                          day.date.year == widget.selectedDate.year;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showDay(context, day, festivals),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xffffedc9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xffe6a543)
                                  : Colors.transparent,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xffe6a543)
                                          .withValues(alpha: 0.24),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Opacity(
                            opacity: inMonth ? 1 : 0.35,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${day.date.day}'),
                                const SizedBox(height: 3),
                                Text(
                                  widget.text.tithi(
                                    day.tithi.replaceFirst(
                                      RegExp(r'^(Shukla|Krishna) '),
                                      '',
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                if (festivals.isNotEmpty)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xffd45719),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x66d45719),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.text['month_system']}: ${widget.text[widget.monthSystem == LunarMonthSystem.amanta ? 'amanta' : 'purnimanta']}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDay(
    BuildContext context,
    PanchangDay day,
    List<Festival> festivals,
  ) {
    final details = widget.dayFor(day.date);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              DateFormat.yMMMMEEEEd().format(details.date),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('${widget.text.tithi(details.tithi)} · ends ${_clock(details.tithiEnd)}'),
            Text('Tithi: ${_clock(details.tithiStart)}–${_clock(details.tithiEnd)}'),
            Text('${widget.text.nakshatra(details.nakshatra)} Pada ${details.nakshatraPada}'),
            Text('Nakshatra: ${_clock(details.nakshatraStart)}–${_clock(details.nakshatraEnd)}'),
            Text('${widget.text.month(details.lunarMonth)} · VS ${details.vikramSamvat} · Shaka ${details.shakaSamvat}'),
            Text('${widget.text['sunrise']} ${_clock(details.sunrise)} · ${widget.text['sunset']} ${_clock(details.sunset)}'),
            Text('${widget.text['moonrise']} ${_clock(details.moonrise)} · ${widget.text['moonset']} ${_clock(details.moonset)}'),
            Text('${details.vara} · ${details.yoga} · ${details.karana}'),
            Text('Yoga ${_clock(details.yogaStart)}–${_clock(details.yogaEnd)}'),
            Text('Karana ${_clock(details.karanaStart)}–${_clock(details.karanaEnd)}'),
            Text('${widget.text['rahu']} ${_clock(details.rahuKaal?.start)}–${_clock(details.rahuKaal?.end)}'),
            const SizedBox(height: 10),
            ...festivals.map(
              (festival) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(widget.text.festival(festival.name)),
                subtitle: Text(festival.reason),
                trailing: IconButton(
                  tooltip: widget.text['derived'],
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(widget.text['derived']),
                      content: Text(festival.reason),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(widget.text['save']),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.info_outline),
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSelect(day.date);
              },
              child: Text(widget.text['today']),
            ),
          ],
        ),
      ),
    );
  }
}

class MuhuratScreen extends StatefulWidget {
  const MuhuratScreen({required this.location, required this.text, super.key});

  final PanchangLocation location;
  final AppText text;

  @override
  State<MuhuratScreen> createState() => _MuhuratScreenState();
}

class _MuhuratScreenState extends State<MuhuratScreen> {
  int _activity = 0;
  late Future<List<(PanchangDay, TimeWindow)>> _windows;

  @override
  void initState() {
    super.initState();
    _windows = _findWindows();
  }

  @override
  void didUpdateWidget(covariant MuhuratScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) _windows = _findWindows();
  }

  Future<List<(PanchangDay, TimeWindow)>> _findWindows() async {
    final rules = const [
      {1, 2, 4, 5, 6},
      {1, 2, 3, 5, 6},
      {1, 2, 4, 5, 6},
      {0, 1, 2, 3, 4, 6},
    ];
    final results = <(PanchangDay, TimeWindow)>[];
    const favoredTithis = [
      {
        'Pratipada',
        'Dwitiya',
        'Tritiya',
        'Panchami',
        'Saptami',
        'Dashami',
        'Ekadashi',
        'Trayodashi',
      },
      {
        'Dwitiya',
        'Tritiya',
        'Panchami',
        'Saptami',
        'Dashami',
        'Ekadashi',
        'Trayodashi',
      },
      {
        'Dwitiya',
        'Tritiya',
        'Panchami',
        'Saptami',
        'Dashami',
        'Ekadashi',
        'Trayodashi',
      },
      {
        'Dwitiya',
        'Tritiya',
        'Panchami',
        'Saptami',
        'Dashami',
        'Ekadashi',
        'Trayodashi',
      },
    ];
    final engine = const PanchangEngine();
    final now = DateTime.now();
    for (var offset = 0; offset < 30; offset++) {
      if (offset > 0 && offset % 5 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      final date = DateTime(now.year, now.month, now.day + offset);
      final day = engine.calculate(date, widget.location, includeMoonEvents: false);
      final window = day.abhijit;
      if (window == null || !rules[_activity].contains(date.weekday % 7)) continue;
      if (day.rahuKaal != null &&
          window.start.isBefore(day.rahuKaal!.end) &&
          day.rahuKaal!.start.isBefore(window.end)) {
        continue;
      }
      final tithiName = day.tithi.replaceFirst(RegExp(r'^(Shukla|Krishna) '), '');
      if (!favoredTithis[_activity].contains(tithiName)) continue;
      results.add((day, window));
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    const reasons = [
      'Uses an auspicious tithi set and Monday, Tuesday, Thursday, Friday or Saturday.',
      'Uses an auspicious tithi set and Monday, Tuesday, Wednesday, Friday or Saturday.',
      'Uses an auspicious tithi set and Monday, Tuesday, Thursday, Friday or Saturday.',
      'Uses an auspicious tithi set and Sunday, Monday, Tuesday, Wednesday, Thursday or Saturday.',
    ];
    final activities = [
      widget.text['business'],
      widget.text['vehicle'],
      widget.text['house'],
      widget.text['travel'],
    ];
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          floating: true,
          surfaceTintColor: Colors.transparent,
          title: _brandTitle(widget.text['muhurat']),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              Text(
                widget.text['traditional'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _activity,
                decoration: InputDecoration(labelText: widget.text['activity']),
                items: List.generate(
                  activities.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(activities[index]),
                  ),
                ),
                onChanged: (value) => setState(() {
                  _activity = value ?? 0;
                  _windows = _findWindows();
                }),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<(PanchangDay, TimeWindow)>>(
                future: _windows,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.isEmpty) {
                    return Text(widget.text['no_window']);
                  }
                  return Column(
                    children: snapshot.data!
                        .map(
                          (entry) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.auto_awesome),
                              title: Text(DateFormat.yMMMMEEEEd().format(entry.$1.date)),
                              subtitle: Text(
                                '${_clock(entry.$2.start)}–${_clock(entry.$2.end)} · '
                                '${entry.$1.tithi}; avoids Rahu Kaal',
                              ),
                              trailing: const Icon(Icons.info_outline),
                              onTap: () => showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(activities[_activity]),
                                  content: Text(
                                    '${reasons[_activity]} Uses the calculated Abhijit interval and excludes Rahu Kaal. These are traditional guidelines only.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(widget.text['save']),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.language,
    required this.location,
    required this.monthSystem,
    required this.morningReminder,
    required this.festivalReminder,
    required this.text,
    required this.onLanguage,
    required this.onLocation,
    required this.onMonthSystem,
    required this.onReminderTimes,
    super.key,
  });

  final AppLanguage language;
  final PanchangLocation location;
  final LunarMonthSystem monthSystem;
  final TimeOfDay morningReminder;
  final TimeOfDay festivalReminder;
  final AppText text;
  final ValueChanged<AppLanguage> onLanguage;
  final ValueChanged<PanchangLocation> onLocation;
  final ValueChanged<LunarMonthSystem> onMonthSystem;
  final void Function(TimeOfDay morning, TimeOfDay festival) onReminderTimes;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Image.asset('assets/brand/panchang_logo.png', width: 44, height: 44),
            const SizedBox(width: 10),
            Text(
              text['settings'],
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text(text['language']),
                trailing: DropdownButton<AppLanguage>(
                  value: language,
                  items: const [
                    DropdownMenuItem(
                      value: AppLanguage.gujarati,
                      child: Text('ગુજરાતી'),
                    ),
                    DropdownMenuItem(value: AppLanguage.hindi, child: Text('हिन्दी')),
                    DropdownMenuItem(value: AppLanguage.english, child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value != null) onLanguage(value);
                  },
                ),
              ),
              ListTile(
                title: Text(text['month_system']),
                trailing: DropdownButton<LunarMonthSystem>(
                  value: monthSystem,
                  items: [
                    DropdownMenuItem(
                      value: LunarMonthSystem.amanta,
                      child: Text(text['amanta']),
                    ),
                    DropdownMenuItem(
                      value: LunarMonthSystem.purnimanta,
                      child: Text(text['purnimanta']),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onMonthSystem(value);
                  },
                ),
              ),
              ListTile(
                title: Text(text['location']),
                subtitle: Text(
                  '${location.name} · ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)} · UTC${location.utcOffset.isNegative ? '' : '+'}${location.utcOffset.inHours}:${(location.utcOffset.inMinutes.abs() % 60).toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.edit_location_alt_outlined),
                onTap: () => _editLocation(context),
              ),
              ListTile(
                title: Text(text['gps']),
                leading: const Icon(Icons.my_location),
                onTap: () => _useGps(context),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(text['notifications']),
                subtitle: const Text(
                  'Morning summary and local vrat/festival reminders',
                ),
                leading: const Icon(Icons.notifications_outlined),
              ),
              ListTile(
                title: Text(text['morning_time']),
                trailing: Text(morningReminder.format(context)),
                onTap: () => _pickReminderTime(context, true),
              ),
              ListTile(
                title: Text(text['festival_time']),
                trailing: Text(festivalReminder.format(context)),
                onTap: () => _pickReminderTime(context, false),
              ),
              ListTile(
                title: Text(text['schedule']),
                trailing: FilledButton(
                  onPressed: () => _enableNotifications(
                    context,
                    location,
                    text,
                    morningReminder,
                    festivalReminder,
                  ),
                  child: Text(text['enable']),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Calculations run on this device. Panchang timings depend on location, '
          'astronomical model, and regional tradition; verify important observances '
          'with a trusted local almanac.',
        ),
      ],
    );
  }

  Future<void> _pickReminderTime(BuildContext context, bool morning) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: morning ? morningReminder : festivalReminder,
    );
    if (selected == null) return;
    onReminderTimes(
      morning ? selected : morningReminder,
      morning ? festivalReminder : selected,
    );
  }

  Future<void> _useGps(BuildContext context) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on location services and try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      onLocation(PanchangLocation(
        name: 'Current location',
        latitude: position.latitude,
        longitude: position.longitude,
        utcOffset: DateTime.now().timeZoneOffset,
      ));
    } on Object catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get GPS location: $error')),
        );
      }
    }
  }

  Future<void> _editLocation(BuildContext context) async {
    final name = TextEditingController(text: location.name);
    final latitude = TextEditingController(text: location.latitude.toString());
    final longitude = TextEditingController(text: location.longitude.toString());
    final offset = TextEditingController(
      text: (location.utcOffset.inMinutes / 60).toStringAsFixed(2),
    );
    final result = await showDialog<PanchangLocation>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(text['location']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: InputDecoration(labelText: text['location'])),
              TextField(
                controller: latitude,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: text['lat']),
              ),
              TextField(
                controller: longitude,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(labelText: text['lon']),
              ),
              TextField(
                controller: offset,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: const InputDecoration(labelText: 'UTC offset (hours)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lat = double.tryParse(latitude.text);
              final lon = double.tryParse(longitude.text);
              final hours = double.tryParse(offset.text);
              if (lat == null ||
                  lon == null ||
                  hours == null ||
                  lat < -90 ||
                  lat > 90 ||
                  lon < -180 ||
                  lon > 180 ||
                  hours.abs() > 14) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid coordinates and UTC offset.')),
                );
                return;
              }
              Navigator.pop(
                context,
                PanchangLocation(
                  name: name.text.trim().isEmpty ? 'Manual location' : name.text.trim(),
                  latitude: lat,
                  longitude: lon,
                  utcOffset: Duration(minutes: (hours * 60).round()),
                ),
              );
            },
            child: Text(text['save']),
          ),
        ],
      ),
    );
    if (result != null) onLocation(result);
  }
}

Future<void> _enableNotifications(
  BuildContext context,
  PanchangLocation location,
  AppText text,
  TimeOfDay morningReminder,
  TimeOfDay festivalReminder,
) async {
  try {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    final plugin = FlutterLocalNotificationsPlugin();
    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await plugin.initialize(initialization);
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final allowed = await android?.requestNotificationsPermission() ?? true;
    if (!allowed) throw StateError('Notification permission was not granted.');

    final engine = const PanchangEngine();
    final festivals = const FestivalEngine();
    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    for (var offset = 0; offset < 30; offset++) {
      await plugin.cancel(1 + offset);
      await plugin.cancel(100 + offset);
      await plugin.cancel(200 + offset);
      final date = today.add(Duration(days: offset));
      final day = engine.calculate(
        date,
        location,
        includeMoonEvents: false,
      );
      final morningTime = _scheduleTime(date, morningReminder);
      if (morningTime.isAfter(now)) {
        await plugin.zonedSchedule(
          1 + offset,
          'Your morning Panchang',
          '${text.tithi(day.tithi)} · ${text.nakshatra(day.nakshatra)}. '
              '${text['sunrise']} ${_clock(day.sunrise)}, ${text['sunset']} ${_clock(day.sunset)}.',
          morningTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'morning_panchang',
              'Morning Panchang',
              channelDescription: 'Daily offline Panchang summary',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      final observances = festivals.forDay(day);
      final vrat = day.tithi.endsWith('Ekadashi') ||
          day.tithi.endsWith('Purnima') ||
          day.tithi.endsWith('Amavasya');
      final names = observances.map((item) => item.name).join(', ');
      if (observances.isNotEmpty) {
        final previousEvening = _scheduleTime(
          date.subtract(const Duration(days: 1)),
          festivalReminder,
        );
        if (previousEvening.isAfter(now)) {
          await plugin.zonedSchedule(
            100 + offset,
            'Festival tomorrow',
            names,
            previousEvening,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'festival_vrat',
                'Festivals and Vrat',
                channelDescription: 'Offline festival and vrat reminders',
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
      if (vrat && morningTime.isAfter(now)) {
        await plugin.zonedSchedule(
          200 + offset,
          'Vrat reminder',
          text.tithi(day.tithi),
          morningTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'festival_vrat',
              'Festivals and Vrat',
              channelDescription: 'Offline vrat-day reminders',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline reminders scheduled for 30 days.')),
      );
    }
  } on Object catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not schedule reminders: $error')),
      );
    }
  }
}

tz.TZDateTime _scheduleTime(DateTime date, TimeOfDay time) => tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

Widget _brandTitle(String title) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/brand/panchang_logo.png',
          width: 34,
          height: 34,
        ),
        const SizedBox(width: 8),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );

Widget _sectionTitle(BuildContext context, String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );

Widget _timeBar(
  BuildContext context,
  String label,
  TimeWindow? window,
  DateTime? sunrise,
  DateTime? sunset,
  Color color,
) {
  if (window == null || sunrise == null || sunset == null) {
    return const SizedBox.shrink();
  }
  final dayLength = sunset.difference(sunrise).inMilliseconds;
  final start = (window.start.difference(sunrise).inMilliseconds / dayLength)
      .clamp(0.0, 1.0)
      .toDouble();
  final end = (window.end.difference(sunrise).inMilliseconds / dayLength)
      .clamp(0.0, 1.0)
      .toDouble();
  return Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 35,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label)),
                    Text('${_clock(window.start)}–${_clock(window.end)}'),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Positioned(
                        left: constraints.maxWidth * start,
                        width: constraints.maxWidth * (end - start),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

String _clock(DateTime? date) =>
    date == null ? '—' : DateFormat.jm().format(date);

