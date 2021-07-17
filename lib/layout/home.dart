import 'package:flutter/material.dart';
import 'package:todolistsql/_screen/archive.dart';
import 'package:todolistsql/_screen/done.dart';
import 'package:todolistsql/_screen/tassk.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:conditional_builder/conditional_builder.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0; //select tap
  List<Widget> navbarnavigete = [
    Task(),
    Done(),
    Archive(),
  ]; //list of move btwn screen
  List<String> titles = [
    'Task',
    'Done',
    'Archive',
  ]; //list of title app bar

  @override
  void initState() {
    super.initState();
    createDatabase(); //for database
  }

  Database database; //database
  var formKey = GlobalKey<FormState>();
  var scaffoldKey = GlobalKey<ScaffoldState>(); //moving in scaffeld
  bool isBottomSheetShow = false; //show bottom
  IconData fabIcon = Icons.edit; //change icon floatbottom
  var titleController = TextEditingController();
  var timeController = TextEditingController();
  var dateController = TextEditingController();
  List<Map> tasks = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(titles[currentIndex]),
      ),
      body: ConditionalBuilder(
        condition: tasks.length > 0,
        builder: (context) => navbarnavigete[currentIndex],
        fallback: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isBottomSheetShow) {
            if (formKey.currentState.validate()) {
              insertToDatabase(
                title: titleController.text,
                date: dateController.text,
                time: timeController.text,
              ).then((value) {
                getDataFromDB(database).then((value) {
                  setState(() {
                    Navigator.pop(context);
                    isBottomSheetShow = false;
                    fabIcon = Icons.edit;
                    tasks = value;
                  });
                });
              });
            }
          } else {
            scaffoldKey.currentState
                .showBottomSheet(
                  (context) => Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.all(22.2),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: titleController,
                            keyboardType: TextInputType.text,
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'title must nnot be empty';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'new Tasks',
                              labelStyle: TextStyle(color: Colors.greenAccent),
                              prefixIcon: Icon(
                                Icons.title,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 15.2,
                          ),
                          TextFormField(
                            controller: timeController,
                            keyboardType: TextInputType.datetime,
                            onTap: () {
                              showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              ).then((value) {
                                timeController.text = value
                                    .format(context)
                                    .toString(); //print time in formfield
                              });
                            },
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'time must nnot be empty';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Time Tasks',
                              labelStyle: TextStyle(color: Colors.greenAccent),
                              prefixIcon: Icon(
                                Icons.watch_later_outlined,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 15.2,
                          ),
                          TextFormField(
                            controller: dateController,
                            keyboardType: TextInputType.datetime,
                            onTap: () {
                              showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.parse(''),
                              ).then((value) {
                                dateController.text =
                                    DateFormat.yMMMd().format(value);
                              });
                            },
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'dte must nnot be empty';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Date Tasks',
                              labelStyle: TextStyle(color: Colors.greenAccent),
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .closed
                .then((value) {
              isBottomSheetShow = false;
              setState(() {
                fabIcon = Icons.edit;
              });
            });
            isBottomSheetShow = true;
            setState(() {
              fabIcon = Icons.add;
            });
          }
        },
        label: const Text('Approve'),
        icon: Icon(
          fabIcon,
        ),
        backgroundColor: Colors.pink,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex, //selecT tap
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Done',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.archive),
            label: 'Archive',
          ),
        ],
      ),
    );
  }

  void createDatabase() async {
    database = await openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version) {
        print('database created');
        database
            .execute(
                'CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, date TEXT,time TEXT,status TEXT)')
            .then((value) {
          print('table created');
        }).catchError((error) {
          print('error when creating table ${error.toString()}');
        });
      },
      onOpen: (database) {
        getDataFromDB(database).then((value) {
          setState(() {
            tasks = value;
          });
        });
        print('open db');
      },
    );
  }

  Future insertToDatabase({
    @required String title,
    @required String time,
    @required String date,
  }) async {
    return await database.transaction((txn) {
      txn
          .rawInsert(
              'INSERT INTO tasks(title, date, time, status) VALUES("$title", "$date", "$time","new")')
          .then((value) {
        print('$value succsuf');
      }).catchError((error) {
        print('error when inserting data ${error.toString()}');
      });
      return null;
    });
  }

  Future<List<Map>> getDataFromDB(database) async {
    return await database.rawQuery('SELECT * FROM tasks');
  }
}
