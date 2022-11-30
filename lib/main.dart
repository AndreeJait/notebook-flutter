import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

var routes = {
  "/home": (context) => const HomePage(),
  "/add-note": (context) => const AddNote()
};

const colors = [
  Colors.blue,
  Colors.greenAccent,
  Colors.lightBlueAccent,
  Colors.amber,
];
const jsonFileName = "notes.json";
const formatDate = "dd/MM/yyyy HH:mm";

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: routes,
      initialRoute: "/home",
    );
  }
}

class Note {
  String title;
  String content;
  String json;
  late DateTime createdAt;

  Note(this.title, this.content, this.json) {
    createdAt = DateTime.now();
  }

  Map<String, String> toJson() => {
        "title": title,
        "content": content,
        "json": json,
        "created_at": getTime(),
      };

  Note.fromJson(Map<String, dynamic> json)
      : content = json['content'],
        json = json['json'],
        title = json["title"],
        createdAt = DateFormat(formatDate).parse(json['created_at']);

  String getTime() {
    return DateFormat(formatDate).format(DateTime.now());
  }
}

class StaticData {
  static String mode = "";
  static Note selected = Note("", "", "");
  static int selectedIndex = -1;
  static Document docs =
      Document.fromDelta(Delta.fromOperations([Operation.insert("")]));
}

class CardNotes extends StatelessWidget {
  Function(int) callbackOnClick;
  Function(int) callbackOnDeleteClick;
  Function(int) callbackOnEditClick;
  Note note;
  int index;

  CardNotes(
      {Key? key,
      required this.callbackOnClick,
      required this.callbackOnDeleteClick,
      required this.callbackOnEditClick,
      required this.note,
      required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        callbackOnClick(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 1,
                offset: const Offset(0, 1), // changes position of shadow
              ),
            ],
            borderRadius: BorderRadius.circular(5),
            color: colors[index % colors.length]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: Text(
                    note.content,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                )
              ],
            )),
            SizedBox(
              height: 20,
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 5,
                children: [
                  InkWell(
                    child: const Icon(
                      Icons.edit,
                      color: Colors.yellow,
                    ),
                    onTap: () {
                      callbackOnEditClick(index);
                    },
                  ),
                  InkWell(
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onTap: () {
                      callbackOnDeleteClick(index);
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Home Page
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool fileExists = false;

  late File jsonFile;
  late Directory dir;

  late List<Note> notes = [];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: addNote,
          elevation: 4,
          child: const Icon(Icons.add),
        ),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          ...notes
              .asMap()
              .map((index, note) => MapEntry(
                  index,
                  CardNotes(
                    callbackOnClick: callbackCard,
                    callbackOnDeleteClick: callbackDeleteCard,
                    callbackOnEditClick: callbackEditCard,
                    note: note,
                    index: index,
                  )))
              .values
              .toList()
        ],
      ),
    ));
  }

  @override
  void initState() {
    getApplicationDocumentsDirectory().then((Directory dir) {
      this.dir = dir;
      jsonFile = File("${dir.path}/$jsonFileName");
      fileExists = jsonFile.existsSync();
      if (fileExists) {
        setState(() {
          var tempFile = jsonDecode(jsonFile.readAsStringSync());
          notes = [...tempFile["notes"].map((item) => Note.fromJson(item))];
        });
      } else {
        createNoteFile({"notes": <Note>[]}, dir, jsonFileName);
      }
    });
    super.initState();
  }

  void callbackCard(int index) {
    StaticData.mode = "view";
    StaticData.selectedIndex = index;
    Navigator.pushReplacementNamed(context, "/add-note");
  }

  void addNote() {
    StaticData.mode = "add";
    StaticData.docs = Document.fromDelta(Delta.fromOperations([
      Operation.insert("Title Note"),
      Operation.insert("\n", {"header": 1})
    ]));
    Navigator.pushReplacementNamed(context, "/add-note");
  }

  void callbackDeleteCard(int index) {
    notes.removeAt(index);
    var pattern = {"notes": notes};
    jsonFile.writeAsStringSync(jsonEncode(pattern));
    Navigator.pushReplacementNamed(context, "/home");
    setState(() {});
  }

  void callbackEditCard(int index) {
    StaticData.mode = "edit";
    StaticData.selectedIndex = index;
    Navigator.pushReplacementNamed(context, "/add-note");
  }

  void createNoteFile(
      Map<String, List<Note>> content, Directory dir, String fileName) {
    File file = File("${dir.path}/$fileName");
    file.createSync();
    fileExists = true;
    file.writeAsStringSync(jsonEncode(content));
  }
}

// Add Note Page
class AddNote extends StatefulWidget {
  const AddNote({Key? key}) : super(key: key);

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  QuillController _controller = QuillController.basic();
  bool editMode = false;
  bool addMode = false;
  bool editable = false;

  bool isLoadingSave = false;

  List<Note> notes = [];

  bool fileExists = false;

  late File jsonFile;
  late Directory dir;

  Document document = Document();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      floatingActionButton: Wrap(
        direction: Axis.vertical,
        spacing: 10,
        children: [
          if (!editMode && !addMode)
            FloatingActionButton(
              heroTag: "EDIT",
              onPressed: handleEditClick,
              child: const Icon(Icons.edit),
            ),
          if (!editMode && !addMode)
            FloatingActionButton(
              heroTag: "BACK",
              onPressed: handleBackClick,
              child: const Icon(Icons.arrow_back),
            ),
          if (editMode || addMode)
            FloatingActionButton(
              heroTag: "CHECK",
              onPressed: handleDoneClick,
              child: isLoadingSave
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.check),
            ),
          if (editMode || addMode)
            FloatingActionButton(
              heroTag: "CANCEL",
              onPressed: handleCancelClick,
              backgroundColor: Colors.red,
              child: const Icon(Icons.close),
            ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          Navigator.pushReplacementNamed(context, "/home");
          return false;
        },
        child: Column(
          children: [
            if (editable) QuillToolbar.basic(controller: _controller),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: QuillEditor.basic(
                  controller: _controller,
                  readOnly: !editable, // true for view only mode
                ),
              ),
            )
          ],
        ),
      ),
    ));
  }

  void handleEditClick() async {
    setState(() {
      editMode = true;
      editable = true;
      StaticData.mode = "edit-inside";
    });
  }

  void handleDoneClick() async {
    setState(() {
      isLoadingSave = true;
    });
    if (StaticData.mode == "add") {
      doSaveData();
      Navigator.pushReplacementNamed(context, "/home");
    }

    if (StaticData.mode == "edit" || StaticData.mode == "edit-inside") {
      doSaveData();
      if(StaticData.mode == "edit"){
        Navigator.pushReplacementNamed(context, "/home");
      }
      if(StaticData.mode == "edit-inside"){
        editMode = false;
        editable = false;
      }
    }

    setState(() {
      isLoadingSave = false;
    });
  }

  void doSaveData(){
    final json = _controller.document.toDelta().toJson();
    String title = json[0]["insert"];
    String description = "";
    if (json.length >= 3) {
      String temp = json[2]["insert"];
      description = json[2]["insert"];
      description = temp
          .replaceAll("\n", " ")
          .substring(0, temp.length > 100 ? 100 : temp.length).trimLeft();
    }
    String docs = jsonEncode(json);
    Note note = Note(title, description, docs);
    notes[StaticData.selectedIndex] = note;
    var pattern = {"notes": notes};
    jsonFile.writeAsStringSync(jsonEncode(pattern));
  }

  void handleCancelClick() async {
    if (StaticData.mode == "add") {
      Navigator.pushReplacementNamed(context, "/home");
    }

    if (StaticData.mode == "edit") {
      Navigator.pushReplacementNamed(context, "/home");
    }
    if(StaticData.mode == "edit-inside"){
      setState(() {
        editMode = false;
        editable = false;
      });
    }
  }

  void handleBackClick() async {
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  void initState() {
    getApplicationDocumentsDirectory().then((Directory dir) {
      this.dir = dir;
      jsonFile = File("${dir.path}/$jsonFileName");
      setState(() {
        var tempFile = jsonDecode(jsonFile.readAsStringSync());
        notes = [...tempFile["notes"].map((item) => Note.fromJson(item))];

        if (StaticData.mode == "view" || StaticData.mode == "edit") {
          if(StaticData.mode == "view"){
            editable = false;
            addMode = false;
            editMode = false;
          }
          if(StaticData.mode == "edit"){
            editMode = true;
            editable = true;
          }
          _controller = QuillController(
              document: Document.fromJson(
                  jsonDecode(notes[StaticData.selectedIndex].json)),
              selection: const TextSelection.collapsed(offset: 0));
        }

      });
    });
    if (StaticData.mode == "add") {
      _controller = QuillController(
          document: StaticData.docs,
          selection: const TextSelection.collapsed(offset: 0));
      setState(() {
        editable = true;
        addMode = true;
      });
    }

    super.initState();
  }
}
