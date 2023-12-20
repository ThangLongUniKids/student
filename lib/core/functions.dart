import 'dart:convert';

List<List<int>> classTimeStamps = [
  [25200, 28200],
  [28800, 31800],
  [33000, 36000],
  [36600, 39600],
  [40200, 43200],
  [46800, 49800],
  [50400, 53400],
  [54000, 57000],
  [57600, 60600],
  [61200, 64200],
  [64800, 67800],
  [68400, 71400],
  [72000, 75000],
  [75600, 78600],
];

List<String> dates = [
  "Chủ Nhật",
  "Thứ Hai",
  "Thứ Ba",
  "Thứ Tư",
  "Thứ Năm",
  "Thứ Sáu",
  "Thứ Bảy",
  ""
];

class ClassTimeStamp {
  final int dint;
  late int startStamp;
  late final int startStampUnix;
  late int endStamp;
  late final int endStampUnix;
  final int dayOfWeek;
  late final String day;
  final String teacherID;
  final String room;
  ClassTimeStamp({
    required this.dint,
    required this.dayOfWeek,
    required this.teacherID,
    required this.room,
  }) {
    startStamp = 0;
    if (room == "Elearning") {
      endStamp = 0;
      startStampUnix = 0;
      endStampUnix = 0;
      day = "";
      return;
    }
    endStamp = 12;
    int tmpDint = dint;
    while (tmpDint != 0) {
      if ((dint & 1) == 0) {
        endStamp--;
      } else {
        startStamp++;
      }
      tmpDint >>= 1;
    }
    startStampUnix = classTimeStamps[startStamp][0];
    endStampUnix = classTimeStamps[endStamp][1];
    day = dates[dayOfWeek];
  }
}

class SubjectClass {
  final String classID;
  final List<ClassTimeStamp> timestamp;
  late final List<int> dint;
  late final int length;
  SubjectClass({
    required this.classID,
    required this.timestamp,
  }) {
    dint = [0, 0, 0, 0, 0, 0, 0];
		length = timestamp.length;
    if (timestamp[0].room == "Elearning") {
      return;
    }
    for (ClassTimeStamp stamp in timestamp) {
      dint[stamp.dayOfWeek] |= stamp.dint;
    }
  }

  void mergeLT(SubjectClass? lt) {
    if (lt is! SubjectClass) {
      return;
    }
    for (ClassTimeStamp stamp in lt.timestamp) {
      dint[stamp.dayOfWeek] |= stamp.dint;
    }
  }
}

class SubjectFilter {
  final List<String> inClass;
  final List<String> notInClass;
  final List<String> teacherIDs;
  SubjectFilter({
    this.inClass = const [],
    this.notInClass = const [],
    this.teacherIDs = const [],
  });
}

class Subject {
  final String subjectID;
  final String name;
  final int tin;
  final List<SubjectClass> classes;
  const Subject({
    required this.subjectID,
    required this.name,
    required this.tin,
    required this.classes,
  });

  List<SubjectClass> filter(SubjectFilter filterLayer) {
    List<SubjectClass> result = [];
    if (filterLayer.inClass.isNotEmpty) {
      //
    }
    if (filterLayer.notInClass.isNotEmpty) {
      //
    }
    if (filterLayer.teacherIDs.isNotEmpty) {
      //
    }
    return result;
  }
}

class Tkb {
  late final List<Subject> tkb;
  late final Map<String, SubjectClass> _tkbLT;
  late final Map<String, String> _teacherByIds;
  final RegExp _ltMatch = RegExp(r"/_LT$/");
  final RegExp _btMatch = RegExp(r"/.[0-9]_BT$/");
  final List<List<String>> input;
  Tkb(this.input) {
    tkb = [];
    _tkbLT = {};
    _teacherByIds = {};
    Map<String, Map<String, dynamic>> tmpTkb = {};
    Map<String, List<ClassTimeStamp>> tmpClassesLT = {};

    for (List<String> mon in input) {
      String subjectID = mon[1];
      String name = mon[2];
      String classID = mon[3];
      int dayOfWeek = int.parse(mon[4]);
      int classStamp = _toBits(mon[5]);
      String classRoom = mon[6];
      int tin = int.parse(mon[7]);
      String teacherID = _teacherToID(mon[8]);

      if (classRoom == "Elearning") {
        dayOfWeek = 7;
        classStamp = 0;
      }

      ClassTimeStamp stamp = ClassTimeStamp(
        dint: classStamp,
        dayOfWeek: dayOfWeek,
        teacherID: teacherID,
        room: classRoom,
      );

      if (_ltMatch.hasMatch(classID)) {
        String realClassID = classID.replaceFirst(_ltMatch, '');
        if (!tmpClassesLT.containsKey(realClassID)) {
          tmpClassesLT[realClassID] = [stamp];
        } else {
          tmpClassesLT[realClassID]?.add(stamp);
        }
        continue;
      }

      if (!tmpTkb.containsKey(subjectID)) {
        tmpTkb[subjectID] = {
          "name": name,
          "tin": tin,
          "classes": <String, List<ClassTimeStamp>>{},
        };
      }

      if (!tmpTkb[subjectID]?["classes"].containsKey(classID)) {
        tmpTkb[subjectID]?["classes"][classID] = <ClassTimeStamp>[];
      }
      tmpTkb[subjectID]?["classes"]?[classID].add(stamp);
    }

    tmpClassesLT.forEach((classID, timestamp) =>
        _tkbLT[classID] = SubjectClass(classID: classID, timestamp: timestamp));

    tmpTkb.forEach((subjectID, subjectInfo) => tkb.add(Subject(
          subjectID: subjectID,
          name: subjectInfo["name"].toString(),
          tin: subjectInfo["tin"],
          classes: _mapToClass(subjectID, subjectInfo["classes"]),
        )));
  }

  int _add0(int i, int n) => i << n;
  int _add1(int i, int n) => (i << (n + 1)) + (2 << n) - 1;

  int _toBits(String str) {
    if (str == "0-0") return 0;
    List<int> e = str.split("-").map(int.parse).toList(growable: false);
    return _add0(_add1(0, e[1] - e[0]), 12 - e[1]);
  }

  String _teacherToID(String str) {
    if (str.isEmpty) {
      return "";
    }

    RegExp teacherIDFilter = RegExp(r"\([A-Z]{3}[0-9]{3}\)");

    String teacherID = teacherIDFilter.stringMatch(str).toString();
    teacherID = teacherID.substring(1, teacherID.length - 1);

    if (!_teacherByIds.containsKey(teacherID)) {
      _teacherByIds[teacherID] = str.replaceFirst(teacherIDFilter, '');
    }

    return teacherID;
  }

  List<SubjectClass> _mapToClass(
      String id, Map<String, List<ClassTimeStamp>> info) {
    List<SubjectClass> tmpClasses = [];
    info.forEach((classID, timestamp) {
      SubjectClass tmpClass =
          SubjectClass(classID: classID, timestamp: timestamp);
      if (_btMatch.hasMatch(id)) {
        tmpClass.mergeLT(_tkbLT[id.replaceFirst(_btMatch, '')]);
      }
      tmpClasses.add(tmpClass);
    });
    return tmpClasses;
  }

  void printTkb() {
    for (Subject s in tkb) {
      print("${s.subjectID}: ");
      print("  Name: ${s.name}");
      print("  Tin chi: ${s.tin}");
      for (SubjectClass c in s.classes) {
        print("    Lop: ${c.classID}");
        print("    dint: ${c.dint}");
      }
    }
  }
}

void main(List<String> args) {
  var dinput = jsonDecode('''
[
	[
		"1",
		"VC204",
		"Các dân tộc Việt Nam",
		"DANTOCVN.1",
		"5",
		"3-5",
		"B403",
		"3",
		"Nguyễn Anh Cường(MXV036)"
	],
	[
		"2",
		"VC204",
		"Các dân tộc Việt Nam",
		"DANTOCVN.1",
		"5",
		"6-7",
		"B307",
		"3",
		"Nguyễn Anh Cường(MXV036)"
	],
	[
		"3",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.7",
		"3",
		"1-2",
		"A709",
		"3",
		"Nguyễn Công Nhân(CTI048)"
	],
	[
		"4",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.8",
		"3",
		"3-5",
		"A709",
		"3",
		"Nguyễn Công Nhân(CTI048)"
	],
	[
		"5",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.8",
		"3",
		"6-7",
		"A708",
		"3",
		"Nguyễn Công Nhân(CTI048)"
	],
	[
		"6",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.6",
		"3",
		"6-7",
		"A709",
		"3",
		"Đinh Thị Thúy(CTI050)"
	],
	[
		"7",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.7",
		"3",
		"8-10",
		"A708",
		"3",
		"Nguyễn Công Nhân(CTI048)"
	],
	[
		"8",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.5",
		"3",
		"8-10",
		"A709",
		"3",
		"Đinh Thị Thúy(CTI050)"
	],
	[
		"9",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.9",
		"4",
		"6-8",
		"A708",
		"3",
		"Nguyễn Công Nhân(CTI048)"
	],
	[
		"10",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.9",
		"5",
		"4-5",
		"A709",
		"3",
		"Nguyễn Công Nhân(CTI048)"
	],
	[
		"11",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.5",
		"5",
		"6-7",
		"A709",
		"3",
		"Đinh Thị Thúy(CTI050)"
	],
	[
		"12",
		"IS222",
		"Cơ sở dữ liệu",
		"CSODULIEU.6",
		"5",
		"8-10",
		"A709",
		"3",
		"Đinh Thị Thúy(CTI050)"
	]
]
''');
  List<List<String>> input = [];
  dinput.toList().forEach((k) {
    List<String> tmp = [];
    k.toList().forEach((t) => tmp.add(t.toString()));
    input.add(tmp);
  });
  Tkb lmao = Tkb(input);
  lmao.printTkb();
}
