import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List todoList = [];

  final _todoController = TextEditingController();

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  @override
  void initState() {
    super.initState();

    readData().then((data) {
      setState(() {
        todoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newTodo = Map();

      newTodo['title'] = _todoController.text;

      _todoController.text = '';

      newTodo['ok'] = false;

      todoList.add(newTodo);
      saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      todoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) return 1;
        else if (!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                      labelText: 'Nova tarefa',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text('ADD'),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: todoList.length,
              itemBuilder: buildItem,
            ),
            onRefresh: _refresh,
          )),
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(todoList[index]['title']),
        value: todoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(todoList[index]['ok'] ? Icons.check : Icons.error),
        ),
        onChanged: (bool value) {
          setState(() {
            todoList[index]['ok'] = value;
            saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(todoList[index]);
          _lastRemovedPosition = index;
          todoList.removeAt(index);

          saveData();

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved["title"]} reomovida !"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  todoList.insert(_lastRemovedPosition, _lastRemoved);
                  saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> saveData() async {
    String data = json.encode(todoList);

    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
