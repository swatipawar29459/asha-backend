import 'package:flutter/material.dart';

import '../theme/asha_theme.dart';
import '../services/health_profile_store.dart';

class CalendarScreen
    extends StatefulWidget {
  const CalendarScreen({
    super.key,
  });

  @override
  State<CalendarScreen> createState() =>
      _CalendarScreenState();
}

class _CalendarScreenState
    extends State<CalendarScreen> {

  DateTime _month =
      DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await HealthProfileStore.load();

    if (!mounted) return;

    setState(() {});
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  DateTime _dateOnly(DateTime d) {
    return DateTime(
      d.year,
      d.month,
      d.day,
    );
  }

  bool _sameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool _isPeriodDay(
    DateTime date,
  ) {
    final last =
        HealthProfileStore
            .lastPeriodDate;

    if (last == null) {
      return false;
    }

    final periodLength =
        HealthProfileStore
                .periodLength ??
            5;

    final start =
        _dateOnly(last);

    final end = start.add(
      Duration(
        days: periodLength - 1,
      ),
    );

    final current =
        _dateOnly(date);

    return !current.isBefore(start) &&
        !current.isAfter(end);
  }

  bool _isFertileDay(
    DateTime date,
  ) {
    final window =
        HealthProfileStore
            .fertileWindow;

    if (window == null) {
      return false;
    }

    final current =
        _dateOnly(date);

    final start =
        _dateOnly(window.start);

    final end =
        _dateOnly(window.end);

    return !current.isBefore(start) &&
        !current.isAfter(end);
  }

  void _previousMonth() {
    setState(() {
      _month = DateTime(
        _month.year,
        _month.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _month = DateTime(
        _month.year,
        _month.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final firstDay =
        DateTime(
      _month.year,
      _month.month,
      1,
    );

    final daysInMonth =
        DateTime(
      _month.year,
      _month.month + 1,
      0,
    ).day;

    final firstWeekday =
        firstDay.weekday;

    final today =
        _dateOnly(
      DateTime.now(),
    );

    return SafeArea(
      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [

            // MONTH HEADER

            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                IconButton(
                  onPressed:
                      _previousMonth,
                  icon: const Icon(
                    Icons
                        .chevron_left,
                  ),
                ),

                Text(
                  '${_monthName(_month.month)} ${_month.year}',
                  style:
                      Theme.of(
                    context,
                  )
                          .textTheme
                          .titleLarge,
                ),

                IconButton(
                  onPressed:
                      _nextMonth,
                  icon: const Icon(
                    Icons
                        .chevron_right,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // WEEKDAYS

            Row(
              children: const [
                'M',
                'T',
                'W',
                'T',
                'F',
                'S',
                'S',
              ]
                  .map(
                    (day) =>
                        Expanded(
                      child:
                          Center(
                        child: Text(
                          day,
                          style:
                              TextStyle(
                            fontSize:
                                11,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(
              height: 8,
            ),

            // CALENDAR

            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount:
                  firstWeekday -
                      1 +
                      daysInMonth,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    7,
              ),
              itemBuilder:
                  (_, index) {

                if (index <
                    firstWeekday -
                        1) {
                  return const SizedBox();
                }

                final day =
                    index -
                        (firstWeekday -
                            1) +
                        1;

                final date =
                    DateTime(
                  _month.year,
                  _month.month,
                  day,
                );

                Color? bg;
                Color fg =
                    AshaColors.ink;

                if (_isPeriodDay(
                  date,
                )) {
                  bg =
                      AshaColors.coral;
                  fg =
                      Colors.white;
                } else if (_isFertileDay(
                  date,
                )) {
                  bg =
                      AshaColors.sky;
                }

                final isToday =
                    _sameDay(
                  date,
                  today,
                );

                return Container(
                  margin:
                      const EdgeInsets.all(
                    2,
                  ),
                  decoration:
                      BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color: bg,
                    border: isToday
                        ? Border.all(
                            color:
                                AshaColors
                                    .ink,
                            width: 2,
                          )
                        : null,
                  ),
                  child:
                      Center(
                    child:
                        Text(
                      '$day',
                      style:
                          TextStyle(
                        fontSize:
                            11,
                        color: fg,
                        fontWeight:
                            FontWeight
                                .w600,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(
              height: 16,
            ),

            // NEXT PERIOD + FERTILE

            Row(
              children: [
                Expanded(
                  child: AshaCard(
                    tint:
                        AshaColors.mint,
                    child: Text(
                      'NEXT PERIOD\n'
                      '${HealthProfileStore.nextPeriodDisplay}',
                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: AshaCard(
                    tint:
                        AshaColors.sky,
                    child: Text(
                      'FERTILE WINDOW\n'
                      '${HealthProfileStore.fertileWindowLabel}',
                      style:
                          const TextStyle(
                        fontSize:
                            12,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            if (HealthProfileStore
                    .lastPeriodDate !=
                null)
              Text(
                'Last period: '
                '${HealthProfileStore.lastPeriodDate!.day.toString().padLeft(2, '0')}/'
                '${HealthProfileStore.lastPeriodDate!.month.toString().padLeft(2, '0')}/'
                '${HealthProfileStore.lastPeriodDate!.year}',
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      AshaColors.slate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}