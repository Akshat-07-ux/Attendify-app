import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:attendance/methods/auth_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendance/models/user_details_form.dart';

class AttendancePage extends StatefulWidget {
  final double targetLatitude;
  final double targetLongitude;
  final String name;
  final String email;
  final String uid;

  AttendancePage({
    Key? key,
    required this.targetLatitude,
    required this.targetLongitude,
    required this.name,
    required this.email,
    required this.uid, 
  }) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  String currentDate = DateFormat.yMMMMd().format(DateTime.now());
  String currentTime = '';
  bool canMarkAttendance = true;
  String locationMessage = '';
  double? currentLatitude;
  double? currentLongitude;
  bool isLoading = true;
  Map<String, dynamic> attendanceRecords = {};
  final AuthMethods _authMethods = AuthMethods();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int attendanceCount = 0;

  
  @override
  void initState() {
    super.initState();
    initializeLocation().then((_) {
      loadAttendanceRecords();
      checkTodayAttendance();
      checkForNotifications(); 
      setState(() {
        isLoading = false;
      });
    });
  }


  void checkForNotifications() async {
  var userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .get();

  if (userDoc.data()?['hasNotification'] == true) {
    String notificationMessage = userDoc.data()?['notificationMessage'] ?? 'You have a new notification';

    // Show notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Notification'),
            content: Text(notificationMessage),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  // Clear the notification flag and message
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({
                    'hasNotification': false,
                    'notificationMessage': FieldValue.delete(),
                  });
                },
              ),
            ],
          );
        },
      );
    });
  }
}

  Future<void> initializeLocation() async {
  await requestLocationPermission();
  await getCurrentLocation();
  checkRange();
}

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationMessage = 'Location permission denied';
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationMessage = 'Location permission permanently denied';
      });
      return;
    }
    setState(() {
      locationMessage = 'Location permission granted';
    });
  }

  Future<void> getCurrentLocation() async {
  try {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;
      checkRange();
    });
  } catch (e) {
    setState(() {
      locationMessage = 'Failed to fetch current location';
    });
  }
}

  void checkRange() {
    if (currentLatitude == null || currentLongitude == null) {
      setState(() {
        locationMessage = 'Failed to fetch current location';
      });
      return;
    }
    double distanceInMeters = Geolocator.distanceBetween(
      currentLatitude!,
      currentLongitude!,
      widget.targetLatitude,
      widget.targetLongitude,
    );
    setState(() {
      if (distanceInMeters <= 3000) {
        canMarkAttendance = true;
        locationMessage = 'You are within the office range.';
      } else {
        canMarkAttendance = false;
        locationMessage = 'Please enter within office to mark attendance';
      }
    });
  }

  
  Future<void> loadAttendanceRecords() async {
    attendanceRecords = await _authMethods.getAttendanceRecords(widget.uid);
    setState(() {
      updateAttendanceStatus();
    });
  }

  Future<void> markAttendance(String status) async {
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    final currentTime = DateTime.now().toIso8601String().split('T')[1];
    
    String userId = _auth.currentUser!.uid;
    bool boolStatus = status == 'Present';
    
    await _authMethods.markAttendance(userId, currentDate, boolStatus, currentTime);
    
    setState(() {
      attendanceCount++;
      canMarkAttendance = attendanceCount < 2;
      this.currentTime = DateFormat.Hms().format(DateTime.now());
    });

    String message = attendanceCount == 1
        ? "${widget.name} has marked today's attendance."
        : "Attendance marked for today.";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    loadAttendanceRecords();
  }

  void updateAttendanceStatus() {
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    var todayAttendance = attendanceRecords[currentDate];
    if (todayAttendance != null) {
      attendanceCount = todayAttendance['count'] ?? 0;
      canMarkAttendance = attendanceCount < 2;
      currentTime = todayAttendance['time'] ?? 'Not marked';
    } else {
      attendanceCount = 0;
      canMarkAttendance = true;
      currentTime = 'Not marked';
    }
  }

  Future<void> checkTodayAttendance() async {
    String userId = _auth.currentUser!.uid;
    final currentDate = DateTime.now().toIso8601String().split('T')[0];
    var todayAttendance = attendanceRecords[currentDate];
    setState(() {
      if (todayAttendance != null) {
        attendanceCount = todayAttendance['count'] ?? 0;
        canMarkAttendance = attendanceCount < 2;
        currentTime = todayAttendance['time'] ?? 'Not marked';
      } else {
        attendanceCount = 0;
        canMarkAttendance = true;
        currentTime = 'Not marked';
      }
    });
  }

 
  Future<void> logout() async {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Your Attendance'),
        centerTitle: true,
        backgroundColor: Colors.grey[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Handle account
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.pushNamed(context, '/adminLogin');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.grey[700],
              ),
              child: Text(
                'Nav Bar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              title: Text('About Agrix'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Agrix is an absolute advantage to small and marginal farmers. With our tried and tested profitable agriculture management ideas, farmers have earned better realizations per acre (40% more than before).\n\n'
                    'With 24×7 farm automation and timely availability of services, Agrix added an additional cropping season -- Zaid, which has helped farmers earn more revenue.\n\n'
                    'With a view to engage farmers across the agri value chain, we are focused on making agriculture smart and affordable by providing a complete farming ecosystem and mentorship support to the farmers.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('User Details'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: UserDetailsForm(email: widget.email),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('See Representation'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AgrixRepresentation(),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('Leave Request'),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LeaveRequestForm(email: widget.email, name: widget.name),
                ),
              ],
            ),
            
          ],
        ),
      ),
      backgroundColor: Colors.grey[800],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome, ${widget.name}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Today\'s Date: $currentDate',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Find below the options to mark your attendance',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (isLoading)
                      CircularProgressIndicator()
                    else if (locationMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          locationMessage,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: canMarkAttendance ? () => markAttendance('Present') : null,
                      child: const Text('Present'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: canMarkAttendance ? () => markAttendance('Absent') : null,
                      child: const Text('Absent'),
                    ),
                     const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: canMarkAttendance ? () => markAttendance('On Leave (CL)') : null,
                      child: const Text('Mark Leave (CL)'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: canMarkAttendance ? () => markAttendance('On Leave (EL)') : null,
                      child: const Text('Mark Leave (EL)'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: canMarkAttendance ? () => markAttendance('On Leave (SL)') : null,
                      child: const Text('Mark Leave (SL)'),
                    ),
                    const SizedBox(height: 20),
                    Text('Current status: $currentTime'),
                    const SizedBox(height: 20),
                    Text('Attendance marked: $attendanceCount time(s) today'),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: kToolbarHeight + 8,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                foregroundColor: Colors.red,
                backgroundColor: Colors.white,
              ),
              onPressed: logout,
              child: Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaveRequestForm extends StatefulWidget {
  final String email;
  final String name;

  LeaveRequestForm({required this.email, required this.name});

  @override
  _LeaveRequestFormState createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends State<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _daysController = TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String _leaveType = 'CL';

   @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _daysController,
            decoration: InputDecoration(labelText: 'Number of Days'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the number of days';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _fromDateController,
            decoration: InputDecoration(labelText: 'From Date'),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                _fromDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the start date';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _toDateController,
            decoration: InputDecoration(labelText: 'To Date'),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
               lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                _toDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the end date';
              }
              return null;
            },
          ),
          DropdownButtonFormField<String>(
            value: _leaveType,
            decoration: InputDecoration(labelText: 'Type of Leave'),
            items: ['CL', 'EL', 'SL'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _leaveType = newValue!;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select the type of leave';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(labelText: 'Leave Reason'),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the reason for leave';
              }
              return null;
            },
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitLeaveRequest,
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _submitLeaveRequest() async {
    if (_formKey.currentState!.validate()) {
      // Submit the leave request
      await FirebaseFirestore.instance.collection('leave_requests').add({
        'email': widget.email,
        'name': widget.name,
        'days': _daysController.text,
        'fromDate': _fromDateController.text,
        'toDate': _toDateController.text,
        'leaveType': _leaveType,
        'reason': _reasonController.text,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
     await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        'leavesRequested': FieldValue.increment(1),
      });

      // Show confirmation to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave request submitted successfully')),
      );

      // Clear the form
      _daysController.clear();
      _fromDateController.clear();
      _toDateController.clear();
      _reasonController.clear();
      setState(() {
        _leaveType = 'CL';
      });
    }
  }
}

class AgrixRepresentation extends StatefulWidget {
  @override
  _AgrixRepresentationState createState() => _AgrixRepresentationState();
}

class _AgrixRepresentationState extends State<AgrixRepresentation> {
  bool showDetails = false;

  void toggleDetails() {
    setState(() {
      showDetails = !showDetails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: toggleDetails,
          child: Text(
            showDetails ? 'Hide Details' : 'Show Details',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
        ),
        if (showDetails) ...[
          Text(
            'Agrix is represented here!',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Agrix provides various services to farmers, including:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '- Profitable agriculture management ideas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Text(
            '- 24x7 farm automation and services',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Text(
            '- Additional cropping season support (Zaid)',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Text(
            '- Complete farming ecosystem and mentorship support ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}

class MessageBox extends StatelessWidget {
  final String email;

  MessageBox({required this.email});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('messages')
          .where('email', isEqualTo: email)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No messages'));
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var message = snapshot.data!.docs[index];
            return ListTile(
              title: Text(message['content']),
              subtitle: Text(DateFormat.yMd().add_jm().format(message['timestamp'].toDate())),
            );
          },
        );
      },
    );
  }
}
