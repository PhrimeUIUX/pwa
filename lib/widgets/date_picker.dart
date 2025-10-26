// ignore_for_file: depend_on_referenced_packages

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class DatePickerWidget extends StatefulWidget {
  const DatePickerWidget({
    required this.selectedDate,
    required this.onDateTimeChanged,
    this.itemExtent = 30.0,
    this.diameterRatio = 3,
    this.perspective = 0.01,
    this.isLoop = true,
    this.minYear = 2024,
    this.maxYear = 2034,
    this.showDay = true,
    this.showMonth = true,
    this.showYear = true,
    this.order = const ["day", "month", "year"],
    super.key,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateTimeChanged;
  final double itemExtent;
  final double diameterRatio;
  final double perspective;
  final bool isLoop;
  final int minYear;
  final int maxYear;
  final bool showDay;
  final bool showMonth;
  final bool showYear;
  final List<String> order;

  @override
  DatePickerWidgetState createState() => DatePickerWidgetState();
}

class DatePickerWidgetState extends State<DatePickerWidget> {
  late int selectedDay;
  late int selectedMonth;
  late int selectedYear;
  late FixedExtentScrollController dayController;
  late FixedExtentScrollController monthController;
  late FixedExtentScrollController yearController;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.selectedDate.day;
    selectedMonth = widget.selectedDate.month;
    selectedYear = widget.selectedDate.year;
    dayController = FixedExtentScrollController(
      initialItem: selectedDay - 1,
    );
    monthController = FixedExtentScrollController(
      initialItem: selectedMonth - 1,
    );
    yearController = FixedExtentScrollController(
      initialItem: selectedYear - widget.minYear,
    );
  }

  Widget buildDatePicker(String type) {
    switch (type) {
      case "day":
        return Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: dayController,
            itemExtent: widget.itemExtent,
            diameterRatio: widget.diameterRatio,
            perspective: widget.perspective,
            physics: widget.isLoop
                ? const FixedExtentScrollPhysics()
                : const ClampingScrollPhysics(),
            onSelectedItemChanged: (int index) {
              setState(
                () {
                  selectedDay = index + 1;
                  widget.onDateTimeChanged(
                    DateTime(
                      selectedYear,
                      selectedMonth,
                      selectedDay,
                    ),
                  );
                },
              );
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                return Center(
                  child: Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      fontSize: selectedDay == index + 1 ? 14 : 12,
                      fontWeight: selectedDay == index + 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedDay == index + 1
                          ? Colors.white
                          : const Color(0xFF030744),
                    ),
                  ),
                );
              },
              childCount: 31,
            ),
          ),
        );
      case "month":
        return Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: monthController,
            itemExtent: widget.itemExtent,
            diameterRatio: widget.diameterRatio,
            perspective: widget.perspective,
            physics: widget.isLoop
                ? const FixedExtentScrollPhysics()
                : const ClampingScrollPhysics(),
            onSelectedItemChanged: (int index) {
              setState(
                () {
                  selectedMonth = index + 1;
                  widget.onDateTimeChanged(
                    DateTime(
                      selectedYear,
                      selectedMonth,
                      selectedDay,
                    ),
                  );
                },
              );
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                return Center(
                  child: Text(
                    DateFormat.MMMM().format(DateTime(0, index + 1)),
                    style: TextStyle(
                      fontSize: selectedMonth == index + 1 ? 14 : 12,
                      fontWeight: selectedMonth == index + 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedMonth == index + 1
                          ? Colors.white
                          : const Color(0xFF030744),
                    ),
                  ),
                );
              },
              childCount: 12,
            ),
          ),
        );
      case "year":
        return Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: yearController,
            itemExtent: widget.itemExtent,
            diameterRatio: widget.diameterRatio,
            perspective: widget.perspective,
            physics: widget.isLoop
                ? const FixedExtentScrollPhysics()
                : const ClampingScrollPhysics(),
            onSelectedItemChanged: (int index) {
              setState(
                () {
                  selectedYear = widget.minYear + index;
                  widget.onDateTimeChanged(
                    DateTime(
                      selectedYear,
                      selectedMonth,
                      selectedDay,
                    ),
                  );
                },
              );
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                return Center(
                  child: Text(
                    (widget.minYear + index).toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selectedYear == widget.minYear + index
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedYear == widget.minYear + index
                          ? Colors.white
                          : const Color(0xFF030744),
                    ),
                  ),
                );
              },
              childCount: widget.maxYear - widget.minYear + 1,
            ),
          ),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> datePickers = widget.order.map((type) {
      switch (type) {
        case "day":
          return widget.showDay ? buildDatePicker("day") : const SizedBox();
        case "month":
          return widget.showMonth ? buildDatePicker("month") : const SizedBox();
        case "year":
          return widget.showYear ? buildDatePicker("year") : const SizedBox();
        default:
          return const SizedBox();
      }
    }).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 30,
          color: const Color(0xFF007BFF),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: datePickers,
          ),
        ),
      ],
    );
  }
}
