import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        grades.add(Grade(docRef.id, newGrade.subject, newGrade.date, newGrade.score)); // Set ID after adding
        _subjectController.clear();
        _scoreController.clear();
        _selectedDate = null;
      });
    }
  }

  void _menuOpen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const ListTile(
                title: Text(
                  'Menu',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              const Divider(color: Colors.white),
              ListTile(
                leading: const Icon(
                  Icons.home,
                  color: Colors.white,
                ),
                title: const Text(
                  'Back to Home',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _selectedDate = "${picked.toLocal()}".split(' ')[0];
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
            onPressed: _menuOpen,
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

              await FirebaseFirestore.instance.collection('grades').doc(grades[index].id).delete();

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
                    await FirebaseFirestore.instance.collection('grades').doc(grades[index].id).delete();

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
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Center(child: Text('Add Rating')),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _subjectController,
                        decoration: const InputDecoration(hintText: "Enter subject"),
                      ),
                      TextField(
                        controller: _scoreController,
                        decoration: const InputDecoration(hintText: "Enter a rating"),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          _selectedDate == null ? 'Select Date' : 'Selected Date: $_selectedDate',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      _addGrade();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add_box, color: Colors.white),
      ),
    );
  }
}
