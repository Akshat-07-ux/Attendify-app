import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceRecordScreen extends StatefulWidget {
  final String userId;

  AttendanceRecordScreen({required this.userId});

  @override
  _AttendanceRecordScreenState createState() => _AttendanceRecordScreenState();
}

class _AttendanceRecordScreenState extends State<AttendanceRecordScreen> {
  late TextEditingController _yearMonthController;
  Map<String, Map<String, dynamic>> attendanceData = {};
  int workingDays = 0;
  int daysPresent = 0;
  int daysAbsent = 0;
  bool isLoading = false;
  late DateTime selectedDate;
  String? selectedOption;
  int attendanceCount = 0;
  bool canMarkAttendance = true;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _yearMonthController = TextEditingController();
    _yearMonthController.text = DateFormat('yyyy-MM').format(selectedDate);
    fetchAttendanceData(_yearMonthController.text);
  }

  @override
  void dispose() {
    _yearMonthController.dispose();
    super.dispose();
  }

  Future<void> fetchAttendanceData(String yearMonth) async {
  setState(() {
    isLoading = true;
  });
  try {
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('attendance')
        .doc('records')
        .get();

    if (attendanceSnapshot.exists) {
      Map<String, dynamic> data = attendanceSnapshot.data() as Map<String, dynamic>;
      int presentCount = 0;
      setState(() {
        attendanceData = Map.fromEntries(data.entries.where((entry) {
          return entry.key.startsWith(yearMonth);
        }).map((entry) {
          if (entry.value is bool) {
            // Handle old format
            if (entry.value) presentCount++;
            return MapEntry(entry.key, {
              'status': entry.value,
              'times': [],
              'count': 1,
            });
          } else if (entry.value is Map<String, dynamic>) {
            // Handle new format
            if (entry.value['status'] == true && entry.value['count'] == 2) {
              presentCount++;
            }
            return MapEntry(entry.key, entry.value as Map<String, dynamic>);
          } else {
            // Handle unexpected format
            print('Unexpected data format for date ${entry.key}: ${entry.value}');
            return MapEntry(entry.key, {
              'status': false,
              'times': [],
              'count': 0,
            });
          }
        }));
        workingDays = attendanceData.length;
        daysPresent = presentCount;
        daysAbsent = workingDays - daysPresent;
        selectedDate = DateFormat('yyyy-MM').parse(yearMonth);
        updateMarkingStatus();
      });

      // Update the user document with the calculated present count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'presents': presentCount});

    } else {
      setState(() {
        attendanceData = {};
        workingDays = 0;
        daysPresent = 0;
        daysAbsent = 0;
        selectedDate = DateFormat('yyyy-MM').parse(yearMonth);
        canMarkAttendance = true;
      });
    }
  } catch (e) {
    print('Error fetching attendance data: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load attendance data')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

 void updateMarkingStatus() {
    final now = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(now);
    var todayAttendance = attendanceData[todayKey];
    if (todayAttendance != null) {
      attendanceCount = todayAttendance['count'] ?? 0;
      canMarkAttendance = attendanceCount < 2;
    } else {
      attendanceCount = 0;
      canMarkAttendance = true;
    }
  }

  Future<void> markAttendance(String option) async {
  if (!canMarkAttendance) return;

  setState(() {
    isLoading = true;
  });

  try {
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final timeKey = DateFormat('HH:mm:ss').format(DateTime.now());
    
    bool boolOption = option == 'Present';

    var currentAttendance = attendanceData[dateKey] ?? {'count': 0, 'times': []};
    int newCount = (currentAttendance['count'] as int) + 1;
    List<dynamic> times = List.from(currentAttendance['times'] ?? [])..add(timeKey);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('attendance')
        .doc('records')
        .set({
      dateKey: {
        'status': boolOption,
        'count': newCount,
        'times': times,
      }
    }, SetOptions(merge: true));

    // Update user's total attendance count
    if (newCount == 2) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        boolOption ? 'presents' : 'absents': FieldValue.increment(1),
      });
    }

    setState(() {
      attendanceData[dateKey] = {
        'status': boolOption,
        'count': newCount,
        'times': times,
      };
      updateMarkingStatus();

      workingDays = attendanceData.length;
      daysPresent = attendanceData.values.where((v) => v['status'] == true).length;
      daysAbsent = attendanceData.values.where((v) => v['status'] == false).length;
    });

    String message = attendanceCount == 1
        ? "First attendance marked for today."
        : "Second attendance marked for today.";
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

  } catch (e) {
    print('Error marking attendance: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to mark attendance')),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Record'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _yearMonthController,
                    decoration: InputDecoration(labelText: 'Enter Year-Month (YYYY-MM)'),
                    onSubmitted: (value) => fetchAttendanceData(value),
                  ),
                  SizedBox(height: 20),
                  ContributionGraph(
                    attendanceData: attendanceData.map((key, value) => MapEntry(key, value['status'] as bool)),
                    selectedDate: selectedDate,
                  ),
                  SizedBox(height: 20),
                  Text('Attendance Summary:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Working Days: $workingDays'),
                  Text('Days Present: $daysPresent'),
                  Text('Days Absent: $daysAbsent'),
                  SizedBox(height: 20),
                  Text('Attendance Details:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  ...attendanceData.entries.map((entry) =>
                    ListTile(
                      title: Text(entry.key),
                      subtitle: Text('Times: ${(entry.value['times'] as List<dynamic>).join(", ")}'),
                      trailing: Text(entry.value['status'] ? 'Present' : 'Absent'),
                    )
                  ).toList(),
                  SizedBox(height: 20),
                  Text('Mark Attendance:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: canMarkAttendance ? () => markAttendance('Present') : null,
                        child: Text('Present'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: canMarkAttendance ? () => markAttendance('Absent') : null,
                        child: Text('Absent'),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: canMarkAttendance ? () => showLeaveOptions(context) : null,
                        child: Text('On Leave'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text('Attendance marked: $attendanceCount time(s) today'),
                ],
              ),
            ),
    );
  }

   void showLeaveOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Leave Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  markAttendance('CL');
                  Navigator.pop(context);
                },
                child: Text('CL'),
              ),
              ElevatedButton(
                onPressed: () {
                  markAttendance('EL');
                  Navigator.pop(context);
                },
                child: Text('EL'),
              ),
              ElevatedButton(
                onPressed: () {
                  markAttendance('SL');
                  Navigator.pop(context);
                },
                child: Text('SL'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ContributionGraph extends StatelessWidget {
  final Map<String, bool> attendanceData;
  final DateTime selectedDate;

  ContributionGraph({required this.attendanceData, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);

    return Container(
      height: 400, // Adjusted height
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 7 + daysInMonth, // Added 7 for weekday labels
              itemBuilder: (context, index) {
                if (index < 7) {
                  // Weekday labels
                  return Center(
                    child: Text(
                      ['S', 'M', 'T', 'W', 'T', 'F', 'S'][index],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }

                final dayIndex = index - 7;
                final date = firstDayOfMonth.add(Duration(days: dayIndex));
                final dateString = DateFormat('yyyy-MM-dd').format(date);
                final isPresent = attendanceData[dateString] ?? false;
                final isAbsent = attendanceData.containsKey(dateString) && !isPresent;
                final isToday = date.isAtSameMomentAs(DateTime.now().toLocal());

                Color color;
                if (isPresent) {
                  color = Colors.green;
                } else if (isAbsent) {
                  color = Colors.red;
                } else if (date.month != selectedDate.month) {
                  color = Colors.grey.shade100;
                } else {
                  color = Colors.grey.shade300;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isPresent || isAbsent ? Colors.white : Colors.black54,
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, 'Present'),
              SizedBox(width: 16),
              _buildLegendItem(Colors.red, 'Absent'),
              SizedBox(width: 16),
              _buildLegendItem(Colors.grey.shade300, 'No Record'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}


