import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_diary/widgets/sign_in_screen.dart';
import 'package:intl/intl.dart';

class Grade {
  final String id;
  final String subject;
  final String date;
  final String score;

  Grade(this.id, this.subject, this.date, this.score);
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Grade> grades = [];
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    final QuerySnapshot snapshot =
    await FirebaseFirestore.instance.collection('grades').get();

    setState(() {
      grades = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Grade(doc.id, data['subject'], data['date'], data['score']);
      }).toList();
    });
  }

  Future<void> _addGrade() async {
    if (_subjectController.text.isNotEmpty &&
        _scoreController.text.isNotEmpty &&
        _selectedDate != null) {
      final newGrade = Grade(
        '',
        _subjectController.text,
        _selectedDate!,
        _scoreController.text,
      );

      final docRef = await FirebaseFirestore.instance.collection('grades').add({
        'subject': newGrade.subject,
        'date': newGrade.date,
        'score': newGrade.score,
      });

      setState(() {
        grades.add(Grade(docRef.id, newGrade.subject, newGrade.date, newGrade.score));
        _subjectController.clear();
        _scoreController.clear();
        _selectedDate = null;
      });
    }
  }

  void _menuOpen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Grades History'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log Out'),
                onTap: () async {
                  // Sign out from Firebase Authentication
                  await FirebaseAuth.instance.signOut();

                  // Navigate back to the SignInScreen (login screen)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInScreen()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Account',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  try {
                    // Log the authentication state to debug
                    User? user = FirebaseAuth.instance.currentUser;
                    print('Current user: $user');

                    if (user != null) {
                      // Proceed with deletion
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                      await user.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account Deleted')),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    } else {
                      // No user logged in
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No user is logged in')),
                      );
                    }
                  } catch (e) {
                    // Error handling
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                    print('Error: $e');
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }

  void _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        _dateController.text = _selectedDate ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      appBar: AppBar(
        title: const Text(
          "My Grade Diary",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_outlined),
            color: Colors.white,
            onPressed: () => _menuOpen(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: grades.length,
        itemBuilder: (BuildContext context, int index) {
          return Dismissible(
            key: Key(grades[index].id),
            background: Container(color: Colors.red),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              await FirebaseFirestore.instance
                  .collection('grades')
                  .doc(grades[index].id)
                  .delete();

              setState(() {
                grades.removeAt(index);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${grades[index].subject} deleted')),
              );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(
                  grades[index].subject,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${grades[index].date}'),
                    Text('Score: ${grades[index].score}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_forever,
                    color: Colors.deepOrange,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('grades')
                        .doc(grades[index].id)
                        .delete();

                    setState(() {
                      grades.removeAt(index);
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${grades[index].subject} deleted')),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.grey[850],
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Estimate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _subjectController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter subject",
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _scoreController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Enter a rating",
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.grey[800],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.number, // Allows only numbers
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Restrict input to digits
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _dateController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: _selectedDate ?? "Select Date", // Display selected date or "Select Date"
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.grey[800],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addGrade,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[900],
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Add Rating',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
