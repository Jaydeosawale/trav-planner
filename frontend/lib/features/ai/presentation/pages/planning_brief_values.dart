/// Transfers known brief values without guessing natural-language dates/currency.
class PlanningBriefValues {
  static DateTime? _exactDate(String raw) {
    final value = DateTime.tryParse(raw);
    if (value == null ||
        raw.length < 10 ||
        value.toIso8601String().substring(0, 10) != raw.substring(0, 10)) {
      return null;
    }
    return DateTime(value.year, value.month, value.day);
  }

  PlanningBriefValues(Map brief) {
    final dates = brief['dates']?.toString() ?? '';
    final matches = RegExp(r'\d{4}-\d{2}-\d{2}')
        .allMatches(dates)
        .map((m) => _exactDate(m.group(0)!))
        .whereType<DateTime>()
        .toList();
    start =
        _exactDate(brief['start_date']?.toString() ?? '') ??
        (matches.isEmpty ? null : matches.first);
    end =
        _exactDate(brief['end_date']?.toString() ?? '') ??
        (matches.length < 2 ? start : matches[1]);
    final raw = brief['budget']?.toString() ?? '';
    final found = RegExp(
      r'\b(INR|USD|EUR|GBP|JPY|AUD|CAD)\b',
      caseSensitive: false,
    ).firstMatch(raw);
    currency =
        brief['currency']?.toString().toUpperCase() ??
        found?.group(0)?.toUpperCase();
    amount = brief['budget_amount']?.toString();
    if (amount == null && found != null) {
      final code = found.group(0)!;
      final prefix = RegExp(
        '$code\\s*([0-9][0-9,]*(?:\\.[0-9]+)?)(?![\\w.,])',
        caseSensitive: false,
      ).firstMatch(raw);
      final suffix = RegExp(
        '([0-9][0-9,]*(?:\\.[0-9]+)?)\\s*$code\\b',
        caseSensitive: false,
      ).firstMatch(raw);
      final number = prefix?.group(1) ?? suffix?.group(1);
      if (number != null) amount = number.replaceAll(',', '');
    }
    context = [
      for (final key in [
        'origin',
        'dates',
        'budget',
        'transport',
        'interests',
        'food',
        'pace',
      ])
        if (brief[key]?.toString().trim().isNotEmpty == true)
          '$key: ${brief[key]}',
    ].join('; ');
    travelers = brief['travelers']?.toString() ?? '1';
  }
  DateTime? start, end;
  String? currency, amount;
  late String context, travelers;
}
