import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LeaveRequestsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leave_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No pending leave requests'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var request = snapshot.data!.docs[index];
              return Column(
                children: [
                  ListTile(
                    title: Text(request['name']),
                    subtitle: Text('${request['fromDate']} to ${request['toDate']}'),
                    trailing: Text('${request['days']} days'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Leave Request Details'),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Name: ${request['name']}'),
                              Text('Email: ${request['email']}'),
                              Text('Days: ${request['days']}'),
                              Text('From: ${request['fromDate']}'),
                              Text('To: ${request['toDate']}'),
                              Text('Type: ${request['leaveType']}'),
                              Text('Reason: ${request['reason']}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _updateLeaveRequest(context, request, 'approved'),
                        child: Text('APPROVE'),
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.green),
                      ),
                      ElevatedButton(
                        onPressed: () => _updateLeaveRequest(context, request, 'rejected'),
                        child: Text('REJECT'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _updateLeaveRequest(BuildContext context, DocumentSnapshot request, String status) async {
    // Update the leave request status
    await FirebaseFirestore.instance
        .collection('leave_requests')
        .doc(request.id)
        .update({'status': status});
    
    // Set notification flag for the user
    var userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: request['email'])
        .get();
    if (userQuery.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userQuery.docs.first.id)
          .update({
        'hasNotification': true,
        'notificationMessage': 'Your leave request has been $status',
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Leave request $status and notification sent')),
    );
  }
}

Future<void> approveLeave(String employeeId, String leaveType, int days) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(employeeId).update({
      leaveType.toLowerCase(): FieldValue.increment(days),
      'absents': FieldValue.increment(days),
    });

    // Fetch the updated user data
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(employeeId).get();
    
    // Update the local state or notify listeners about the change
    // This part depends on how your state management is set up
    // For example, if you're using a provider:
    // Provider.of<UserProvider>(context, listen: false).updateUserData(userDoc.data());

    print('Leave approved and user data updated');
  } catch (e) {
    print('Error approving leave: $e');
  }
}

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text('Admin Name: Akshat Bhagat'),
              accountEmail: Text(''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  'A',
                  style: TextStyle(fontSize: 40.0),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.phone),
              title: Text('Phone: +91 9608154511'),
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email: akshatbhagat359@gmail.com'),
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: <Widget>[
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return DashboardCard(
                          title: 'Total Employees',
                          value: '...',
                          color: Colors.red,
                        );
                      }
                      int employeeCount = snapshot.data?.docs.length ?? 0;
                      return DashboardCard(
                        title: 'Total Employees',
                        value: employeeCount.toString(),
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EmployeeListScreen()),
                          );
                        },
                      );
                    },
                  ),
                  DashboardCard(
                    title: 'Employee Details',
                    value: 'View',
                    color: Colors.yellow,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeDetailsScreen()),
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('leave_requests')
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return DashboardCard(
                          title: 'Leave Requests',
                          value: '...',
                          color: Colors.blue,
                        );
                      }
                      int leaveRequestCount = snapshot.data?.docs.length ?? 0;
                      return DashboardCard(
                        title: 'Leave Requests',
                        value: leaveRequestCount.toString(),
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LeaveRequestsScreen()),
                          );
                        },
                      );
                    },
                  ),
                  DashboardCard(
                    title: 'Attendance Records',
                    value: 'View',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeAttendanceScreen()),
                      );
                    },
                  ),
                  DashboardCard(
                    title: 'Add New',
                    value: 'USER',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddUserScreen()),
                      );
                    },
                  ),
                  DashboardCard(
                    title: 'Attendance',
                    value: 'Statistics',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AttendanceStatisticsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeeDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Employee Details')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No employees found'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var employee = snapshot.data!.docs[index];
              return ListTile(
                title: Text(employee['name'] ?? 'No Name'),
                subtitle: Text(employee['email'] ?? 'No Email'),
                
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeDetailEditScreen(employeeId: employee.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EmployeeDetailEditScreen extends StatefulWidget {
  final String employeeId;

  EmployeeDetailEditScreen({required this.employeeId});

  @override
  _EmployeeDetailEditScreenState createState() => _EmployeeDetailEditScreenState();
}

class _EmployeeDetailEditScreenState extends State<EmployeeDetailEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _presentsController;
  late TextEditingController _absentsController;
  late TextEditingController _clController;
  late TextEditingController _elController;
  late TextEditingController _slController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _presentsController = TextEditingController();
    _absentsController = TextEditingController();
    _clController = TextEditingController();
    _elController = TextEditingController();
    _slController = TextEditingController();
    _loadEmployeeData();
  }

  void _loadEmployeeData() async {
  var doc = await FirebaseFirestore.instance.collection('users').doc(widget.employeeId).get();
  if (doc.exists) {
    setState(() {
      _nameController.text = doc['name'] ?? '';
      _emailController.text = doc['email'] ?? '';
      _phoneController.text = doc['phone'] ?? '';
      _addressController.text = doc['address'] ?? '';
      _presentsController.text = (doc['presents'] ?? 0).toString();
      _absentsController.text = (doc['absents'] ?? 0).toString();
      _clController.text = (doc['cl'] ?? 0).toString();
      _elController.text = (doc['el'] ?? 0).toString();
      _slController.text = (doc['sl'] ?? 0).toString();
    });
  }
}

  void _saveEmployeeData() async {
  if (_formKey.currentState!.validate()) {
    await FirebaseFirestore.instance.collection('users').doc(widget.employeeId).set({
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'address': _addressController.text,
      'presents': int.tryParse(_presentsController.text) ?? 0,
      'absents': int.tryParse(_absentsController.text) ?? 0,
      'cl': int.tryParse(_clController.text) ?? 0,
      'el': int.tryParse(_elController.text) ?? 0,
      'sl': int.tryParse(_slController.text) ?? 0,
    }, SetOptions(merge: true));
    Navigator.pop(context);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Employee Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Please enter an email' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
                validator: (value) => value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Address'),
                validator: (value) => value!.isEmpty ? 'Please enter an address' : null,
              ),
              TextFormField(
                controller: _presentsController,
                decoration: InputDecoration(labelText: 'Presents'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _absentsController,
                decoration: InputDecoration(labelText: 'Absents'),
                keyboardType: TextInputType.number,
              ),
              Text('Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextFormField(
                controller: _clController,
                decoration: InputDecoration(labelText: 'Casual Leave (CL)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _elController,
                decoration: InputDecoration(labelText: 'Earned Leave (EL)'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _slController,
                decoration: InputDecoration(labelText: 'Sick Leave (SL)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveEmployeeData,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _presentsController.dispose();
    _absentsController.dispose();
    _clController.dispose();
    _elController.dispose();
    _slController.dispose();
    super.dispose();
  }
}

class EmployeeListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee List'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['name']),
                subtitle: Text(doc['email']),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceCalendarScreen(employeeId: doc.id),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class AttendanceCalendarScreen extends StatefulWidget {
  final String employeeId;

  AttendanceCalendarScreen({required this.employeeId});

  @override
  _AttendanceCalendarScreenState createState() => _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState extends State<AttendanceCalendarScreen> {
  Map<DateTime, Map<String, dynamic>> _attendanceMap = {};
  bool _isLoading = true;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchAttendanceData();
  }

 Future<void> _fetchAttendanceData() async {
  setState(() => _isLoading = true);
  try {
    final attendanceSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.employeeId)
        .collection('attendance')
        .doc('records')
        .get();

     if (attendanceSnapshot.exists) {
        final data = attendanceSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _attendanceMap = data.map((key, value) {
            final date = DateTime.parse(key);
            if (value is Map<String, dynamic>) {
              return MapEntry(date, {
                'status': value['status'] == 'true' || value['status'] == true,
                'count': value['count'] ?? 1,
              });
            } else {
              return MapEntry(date, {
                'status': value == 'true' || value == true,
                'count': 1,
              });
            }
          });
        });
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMonthChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }


   Map<String, bool> _getAttendanceDataForMonth() {
    final startOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final endOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    return Map.fromEntries(
      _attendanceMap.entries.where((entry) {
        return entry.key.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
            entry.key.isBefore(endOfMonth.add(Duration(days: 1)));
      }).map((entry) {
        return MapEntry(
          DateFormat('yyyy-MM-dd').format(entry.key),
           entry.value['count'] == 2 && entry.value['status'] as bool,
        );
      }),
    );
  }

  int _getWorkingDays() {
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    return daysInMonth - _getWeekendsInMonth();
  }

  int _getWeekendsInMonth() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    int weekendCount = 0;

    for (var day = firstDayOfMonth; day.isBefore(lastDayOfMonth.add(Duration(days: 1))); day = day.add(Duration(days: 1))) {
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        weekendCount++;
      }
    }

    return weekendCount;
  }

  int _getDaysPresent() {
    return _getAttendanceDataForMonth().values.where((status) => status).length;
  }

  int _getDaysAbsent() {
    return _getWorkingDays() - _getDaysPresent();
  }
Color _getColorForAttendance(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    final attendanceData = _attendanceMap[date];

    if (attendanceData != null) {
      if (attendanceData['count'] == 2) {
        return attendanceData['status'] ? Colors.green : Colors.red;
      }
    }
    
    return Colors.grey; // Default color for no data or incomplete attendance
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Matrix'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    MonthPicker(
                      selectedDate: _selectedDate,
                      onChanged: _onMonthChanged,
                    ),
                    SizedBox(height: 20),
                    ContributionGraph(
                      attendanceData: _getAttendanceDataForMonth(),
                      selectedDate: _selectedDate,
                    ),
                    SizedBox(height: 20),
                    AttendanceSummary(
                      workingDays: _getWorkingDays(),
                      daysPresent: _getDaysPresent(),
                      daysAbsent: _getDaysAbsent(),
                    ),
                    SizedBox(height: 20),
                    _buildMonthlyCalendar(),
                    SizedBox(height: 20),
                    _buildLegend(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMonthlyCalendar() {
  final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
  final startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);

  return GridView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      childAspectRatio: 1,
    ),
    itemCount: daysInMonth,
    itemBuilder: (context, index) {
      final date = startDate.add(Duration(days: index));
      return Container(
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: _getColorForAttendance(date),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    },
  );
}

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _LegendItem(color: Colors.grey, label: 'No data or incomplete'),
        _LegendItem(color: Colors.green, label: 'Present (2nd marking)'),
        _LegendItem(color: Colors.red, label: 'Absent (2nd marking)'),
      ],
    );
  }
}

class MonthPicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  MonthPicker({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(selectedDate.year, selectedDate.month - 1)),
        ),
        Text(
          DateFormat('MMMM yyyy').format(selectedDate),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: () => onChanged(DateTime(selectedDate.year, selectedDate.month + 1)),
        ),
      ],
    );
  }
}

class AttendanceMatrixLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _LegendItem(color: Colors.grey, label: 'Less than 2 attendances'),
        _LegendItem(color: Colors.green, label: 'Present'),
        _LegendItem(color: Colors.red, label: 'Absent/Leave'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({Key? key, required this.color, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create user in Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Add user to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'name': '', // You can add more fields as needed
          'role': 'employee',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User added successfully')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding user: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add User')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _addUser,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Add User'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class EmployeeAttendanceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Attendance'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No employees found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final employee = snapshot.data!.docs[index];
              return ListTile(
                title: Text(employee['name'] ?? 'Unknown'),
                subtitle: Text(employee['email'] ?? 'No email'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceCalendarScreen(employeeId: employee.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class AttendanceStatisticsScreen extends StatefulWidget {
  @override
  _AttendanceStatisticsScreenState createState() => _AttendanceStatisticsScreenState();
}

class _AttendanceStatisticsScreenState extends State<AttendanceStatisticsScreen> {
  DateTime selectedDate = DateTime.now();
  int totalEmployees = 0;
  int checkedIn = 0;
  int notCheckedIn = 0;
  int onLeave = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchAttendanceData();
  }

  Future<void> fetchAttendanceData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);
      
      // Get all users
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      totalEmployees = usersSnapshot.docs.length;

      // Initialize counters
      checkedIn = 0;
      onLeave = 0;
      notCheckedIn = 0;

      // Iterate through each user
      for (var userDoc in usersSnapshot.docs) {
        final attendanceDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('attendance')
            .doc('records')
            .get();

        if (attendanceDoc.exists) {
          final attendanceData = attendanceDoc.data() as Map<String, dynamic>;
          if (attendanceData.containsKey(dateString)) {
            final status = attendanceData[dateString]['status'];
            if (status == true) {
              checkedIn++;
            } else if (status == 'On Leave (CL)' || status == 'On Leave (EL)' || status == 'On Leave (SL)') {
              onLeave++;
            } else {
              notCheckedIn++;
            }
          } else {
            notCheckedIn++;
          }
        } else {
          notCheckedIn++;
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Statistics'),
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EmployeeLiveLocationList()),
                  );
                },
                child: Text('Live Location of Employees'),
              ),
                ElevatedButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                      fetchAttendanceData();
                    }
                  },
                  child: Text('Select Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.blue,
                            value: checkedIn.toDouble(),
                            title: 'Checked In',
                            radius: 90,
                            titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: notCheckedIn.toDouble(),
                            title: 'Not Checked In',
                            radius: 90,
                            titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          PieChartSectionData(
                            color: Colors.green,
                            value: onLeave.toDouble(),
                            title: 'On Leave',
                            radius: 90,
                            titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                        sectionsSpace: 0,
                        centerSpaceRadius: 50,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text('Total Employees: $totalEmployees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    StatCard(title: 'Checked In', value: checkedIn, color: Colors.blue),
                    StatCard(title: 'Not Checked In', value: notCheckedIn, color: Colors.red),
                    StatCard(title: 'On Leave', value: onLeave, color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const StatCard({Key? key, required this.title, required this.value, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(value.toString(), style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class ContributionGraph extends StatelessWidget {
  final Map<String, bool> attendanceData;
  final DateTime selectedDate;

  ContributionGraph({required this.attendanceData, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    // Implement the contribution graph widget
    return Container(
      child: Text('Contribution Graph Placeholder'),
    );
  }
}

class AttendanceSummary extends StatelessWidget {
  final int workingDays;
  final int daysPresent;
  final int daysAbsent;

  AttendanceSummary({
    required this.workingDays,
    required this.daysPresent,
    required this.daysAbsent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SummaryBox(
              title: 'Working Days',
              value: workingDays.toString(),
            ),
            SummaryBox(
              title: 'Days Present',
              value: daysPresent.toString(),
            ),
            SummaryBox(
              title: 'Days Absent',
              value: daysAbsent.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class SummaryBox extends StatelessWidget {
  final String title;
  final String value;

  SummaryBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(value),
        ],
      ),
    );
  }
}

class EmployeeLiveLocationList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Live Locations'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No employees found'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var employee = snapshot.data!.docs[index];
              return ListTile(
                title: Text(employee['name'] ?? 'No Name'),
                subtitle: Text(employee['email'] ?? 'No Email'), // Changed from 'phone' to 'email'
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeLiveLocationMap(
                        employeeName: employee['name'] ?? 'No Name',
                        employeeEmail: employee['email'] ?? 'No Email', // Changed from 'phone' to 'email'
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EmployeeLiveLocationMap extends StatefulWidget {
  final String employeeName;
  final String employeeEmail; // Changed from phoneNumber to employeeEmail

  EmployeeLiveLocationMap({required this.employeeName, required this.employeeEmail});

  @override
  _EmployeeLiveLocationMapState createState() => _EmployeeLiveLocationMapState();
}

class _EmployeeLiveLocationMapState extends State<EmployeeLiveLocationMap> {
  GoogleMapController? _controller;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _updateCameraPosition();
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _updateCameraPosition() {
    if (_currentPosition != null && _controller != null) {
      _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employeeName}\'s Location'),
      ),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              markers: {
                Marker(
                  markerId: MarkerId('employeeLocation'),
                  position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                  infoWindow: InfoWindow(
                    title: widget.employeeName,
                    snippet: 'Email: ${widget.employeeEmail}',
                  ),
                ),
              },
            ),
    );
  }
}