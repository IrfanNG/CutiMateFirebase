import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/destination_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';

class RecommendationService {
  // Use Nager.Date API for Malaysia Public Holidays
  // https://date.nager.at/Api
  static const String _baseUrl = 'https://date.nager.at/api/v3/PublicHolidays';

  // Cache holidays to minimize API calls
  static List<PublicHoliday> _cachedHolidays = [];

  /// Fetch public holidays for Key Malaysia (MY) for current & next year
  static Future<List<PublicHoliday>> fetchHolidays() async {
    if (_cachedHolidays.isNotEmpty) return _cachedHolidays;

    final now = DateTime.now();
    final year = now.year;

    // Fetch for current year and next year to handle year-end transitions
    var holidaysCurrent = await _fetchYear(year);
    if (holidaysCurrent.isEmpty) {
      if (kDebugMode) print("API failed for $year, using fallback.");
      holidaysCurrent = _generateFallbackHolidays(year);
    }

    var holidaysNext = await _fetchYear(year + 1);
    if (holidaysNext.isEmpty) {
      if (kDebugMode) print("API failed for ${year + 1}, using fallback.");
      holidaysNext = _generateFallbackHolidays(year + 1);
    }

    _cachedHolidays = [...holidaysCurrent, ...holidaysNext];
    return _cachedHolidays;
  }

  static Future<List<PublicHoliday>> _fetchYear(int year) async {
    try {
      final url = Uri.parse('$_baseUrl/$year/MY');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PublicHoliday.fromJson(json)).toList();
      } else {
        // 204 etc.
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// GENERATE FALLBACK HOLIDAYS (Algorithmic)
  static List<PublicHoliday> _generateFallbackHolidays(int year) {
    List<PublicHoliday> holidays = [];

    // 1. Fixed Holidays
    holidays.add(_fixedHoliday(year, 1, 1, "New Year's Day"));
    holidays.add(_fixedHoliday(year, 5, 1, "Labour Day"));
    holidays.add(_fixedHoliday(year, 8, 31, "Merdeka Day"));
    holidays.add(_fixedHoliday(year, 9, 16, "Malaysia Day"));
    holidays.add(_fixedHoliday(year, 12, 25, "Christmas Day"));

    // 2. Islamic Holidays (Calculated via Hijri)
    HijriCalendar.setLocal('en');

    // Check significant Hijri dates for this Gregorian year
    // We check a range of hijri years that overlap this gregorian year
    // Approx Hijri year = (GYear - 622) * 33 / 32
    int startHYear = ((year - 622) * 33 / 32).floor() - 1;

    for (int hy = startHYear; hy <= startHYear + 2; hy++) {
      // 1 Syawal (Aidilfitri)
      _checkHijriDate(year, hy, 10, 1, "Hari Raya Aidilfitri", holidays);
      _checkHijriDate(
        year,
        hy,
        10,
        2,
        "Hari Raya Aidilfitri (Day 2)",
        holidays,
      );

      // 10 Dhu al-Hijjah (Aidiladha)
      _checkHijriDate(year, hy, 12, 10, "Hari Raya Aidiladha", holidays);
    }

    // Sort by date before returning
    holidays.sort((a, b) => a.date.compareTo(b.date));
    return holidays;
  }

  static void _checkHijriDate(
    int targetGYear,
    int hYear,
    int hMonth,
    int hDay,
    String name,
    List<PublicHoliday> list,
  ) {
    try {
      final hDate = HijriCalendar();
      hDate.hYear = hYear;
      hDate.hMonth = hMonth;
      hDate.hDay = hDay;

      // hijriToGregorian returns a DateTime
      // The package syntax is hDate.hijriToGregorian(y, m, d)
      final gDate = hDate.hijriToGregorian(hYear, hMonth, hDay);

      if (gDate.year == targetGYear) {
        list.add(PublicHoliday(date: gDate, name: name, localName: name));
      }
    } catch (e) {
      // ignore invalid dates
    }
  }

  static PublicHoliday _fixedHoliday(
    int year,
    int month,
    int day,
    String name,
  ) {
    return PublicHoliday(
      date: DateTime(year, month, day),
      name: name,
      localName: name,
    );
  }

  /// Get upcoming long weekends (Friday or Monday holidays)
  static Future<List<LongWeekend>> getUpcomingLongWeekends() async {
    await fetchHolidays();
    final now = DateTime.now();

    // Sort all holidays by date
    _cachedHolidays.sort((a, b) => a.date.compareTo(b.date));

    final upcomingHolidays = _cachedHolidays
        .where((h) => h.date.isAfter(now))
        .toList();

    if (kDebugMode) {
      print("Upcoming holidays count: ${upcomingHolidays.length}");
      for (var h in upcomingHolidays.take(3)) {
        print("Holiday: ${h.name} on ${h.date}");
      }
    }

    List<LongWeekend> longWeekends = [];

    for (var holiday in upcomingHolidays) {
      // Friday (5) -> Long Weekend (Fri-Sun)
      if (holiday.date.weekday == DateTime.friday) {
        longWeekends.add(
          LongWeekend(
            holidayName: holiday.name,
            startDate: holiday.date,
            endDate: holiday.date.add(const Duration(days: 2)),
            type: LongWeekendType.fridayOff,
          ),
        );
      }
      // Monday (1) -> Long Weekend (Sat-Mon)
      else if (holiday.date.weekday == DateTime.monday) {
        longWeekends.add(
          LongWeekend(
            holidayName: holiday.name,
            startDate: holiday.date.subtract(const Duration(days: 2)),
            endDate: holiday.date,
            type: LongWeekendType.mondayOff,
          ),
        );
      }
      // Sunday (7) -> Usually replaced on Monday -> Long Weekend (Sat-Mon)
      else if (holiday.date.weekday == DateTime.sunday) {
        longWeekends.add(
          LongWeekend(
            holidayName: "${holiday.name} (Observed)",
            startDate: holiday.date.subtract(const Duration(days: 1)), // Sat
            endDate: holiday.date.add(const Duration(days: 1)), // Mon
            type: LongWeekendType.mondayOff,
          ),
        );
      }
    }

    // FALLBACK: If no "long weekends" found, just suggest the NEXT holiday
    // so the user sees something.
    if (longWeekends.isEmpty && upcomingHolidays.isNotEmpty) {
      final nextHoliday = upcomingHolidays.first;
      // Just create a dummy "trip" duration around it
      longWeekends.add(
        LongWeekend(
          holidayName: nextHoliday.name,
          startDate: nextHoliday.date,
          endDate: nextHoliday.date.add(const Duration(days: 1)),
          type: LongWeekendType.fridayOff, // default styling
        ),
      );
    }

    return longWeekends.take(3).toList();
  }

  /// Get destinations recommended for the current month/season
  static List<Destination> getSeasonalRecommendations(
    List<Destination> allDestinations,
  ) {
    final now = DateTime.now();
    final currentMonth = now.month;

    // Prioritize destinations where current month is in 'bestMonths'
    // AND prioritize those that match the "Dry Season" logic if applicable

    List<Destination> recommended = [];
    List<Destination> others = [];

    for (var dest in allDestinations) {
      if (dest.bestMonths.contains(currentMonth)) {
        recommended.add(dest);
      } else {
        others.add(dest);
      }
    }

    return [...recommended, ...others];
  }
}

class PublicHoliday {
  final DateTime date;
  final String name; // e.g., "Hari Raya Aidilfitri"
  final String localName;

  PublicHoliday({
    required this.date,
    required this.name,
    required this.localName,
  });

  factory PublicHoliday.fromJson(Map<String, dynamic> json) {
    return PublicHoliday(
      date: DateTime.parse(json['date']),
      name: json['name'] ?? '',
      localName: json['localName'] ?? '',
    );
  }
}

class LongWeekend {
  final String holidayName;
  final DateTime startDate;
  final DateTime endDate;
  final LongWeekendType type;

  LongWeekend({
    required this.holidayName,
    required this.startDate,
    required this.endDate,
    required this.type,
  });

  String get dateRangeText {
    // Simple formatter "12 Oct - 14 Oct"
    return "${startDate.day} ${_getMonth(startDate.month)} - ${endDate.day} ${_getMonth(endDate.month)}";
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

enum LongWeekendType { fridayOff, mondayOff }
