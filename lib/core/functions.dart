import 'dart:convert';

const List<List<int>> classTimeStamps = [
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

const List<String> dates = [
  "Chủ Nhật",
  "Thứ Hai",
  "Thứ Ba",
  "Thứ Tư",
  "Thứ Năm",
  "Thứ Sáu",
  "Thứ Bảy",
  ""
];
const List<int> emptyDint = [0, 0, 0, 0, 0, 0, 0];

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
  late final List<String> teachers;
  late final List<String> rooms;
  SubjectClass({
    required this.classID,
    required this.timestamp,
  }) {
    dint = [...emptyDint];
    length = timestamp.length;
    teachers = timestamp.map((m) => m.teacherID).toList();
    rooms = timestamp.map((m) => m.room).toList();
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
  final List<String> includeTeacher;
  final List<String> excludeTeacher;
  final List<int> forcefulDint;
  final List<int> spareDint;
  late int length;
  late final bool isEmpty;
  late final bool isNotEmpty;
  SubjectFilter({
    this.inClass = const [],
    this.notInClass = const [],
    this.includeTeacher = const [],
    this.excludeTeacher = const [],
    this.forcefulDint = const [],
    this.spareDint = const [],
  }) {
    length = 0;
    if (inClass.isNotEmpty) {
      length++;
    }
    if (notInClass.isNotEmpty) {
      length++;
    }
    if (includeTeacher.isNotEmpty) {
      length++;
    }
    if (excludeTeacher.isNotEmpty) {
      length++;
    }
    if (forcefulDint.isNotEmpty) {
      length++;
    }
    if (spareDint.isNotEmpty) {
      length++;
    }
    isEmpty = length == 0;
    isNotEmpty = !isEmpty;
  }
}

class CompareStamp {
  final double delta;
  final SubjectClass subjectClass;
  const CompareStamp({
    required this.delta,
    required this.subjectClass,
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

  Subject filter(SubjectFilter filterLayer) {
    if (classes[0].rooms[0] == "Elearning" || filterLayer.isEmpty) {
      return this;
    }
    List<SubjectClass> result = [];
    if (filterLayer.inClass.isNotEmpty) {
      result = classes
          .where((c) => filterLayer.inClass.contains(c.classID))
          .toList();
    }
    if (filterLayer.notInClass.isNotEmpty) {
      result = classes
          .where((c) => !filterLayer.notInClass.contains(c.classID))
          .toList();
    }
    if (filterLayer.includeTeacher.isNotEmpty) {
      List<CompareStamp> o = classes
          .map((c) => CompareStamp(
                delta: c.teachers.isEmpty
                    ? 0.0
                    : c.teachers
                            .where(
                                (t) => filterLayer.includeTeacher.contains(t))
                            .length /
                        c.teachers.length,
                subjectClass: c,
              ))
          .where((c) => c.delta != 0.0)
          .map((c) => CompareStamp(
                delta: ((c.delta - 1).abs() * 100),
                subjectClass: c.subjectClass,
              ))
          .toList();
      o.sort((a, b) => a.delta.compareTo(b.delta).toInt());
      result = o.map((c) => c.subjectClass).toList();
    }
    if (filterLayer.excludeTeacher.isNotEmpty) {
      if (classes[0].rooms[0] == "Elearning") {
        return this;
      }
      result = classes
          .map((c) => CompareStamp(
                delta: c.teachers.isEmpty
                    ? 0.0
                    : c.teachers
                            .where(
                              (t) => filterLayer.excludeTeacher.contains(t),
                            )
                            .length /
                        c.teachers.length,
                subjectClass: c,
              ))
          .where((c) => c.delta == 0.0)
          .map((c) => c.subjectClass)
          .toList();
    }
    if (filterLayer.forcefulDint.isNotEmpty) {
      result = classes.where((c) {
        List<int> tmpDint = [...emptyDint];
        for (int i = 0; i < 7; i++) {
          tmpDint[i] = c.dint[i] & filterLayer.forcefulDint[i];
        }
        return tmpDint.fold(0, (a, b) => a + b) == 0;
      }).toList();
    }
    if (filterLayer.spareDint.isNotEmpty) {
      List<CompareStamp> o = classes
          .map((c) => CompareStamp(
                delta: (() {
                  List<int> tmpDint = [...emptyDint];
                  for (int i = 0; i < 7; i++) {
                    tmpDint[i] = c.dint[i] & filterLayer.forcefulDint[i];
                  }
                  return tmpDint
                      .map((d) => d + 1)
                      .fold(1, (p, c) => p * c)
                      .toDouble();
                })(),
                subjectClass: c,
              ))
          .toList();
      o.sort((a, b) => a.delta.compareTo(b.delta).toInt());
      result = o.map((c) => c.subjectClass).toList();
    }
    return Subject(subjectID: subjectID, name: name, tin: tin, classes: result);
  }
}

class SampleTkb {
  final List<SubjectClass> classes;
  late final List<int> dint;
  late final int length;
  SampleTkb({required this.classes}) {
    length = classes.length;
    dint = [...emptyDint];
    for (SubjectClass c in classes) {
      for (int i = 0; i < 7; i++) {
        dint[i] |= c.dint[i];
      }
    }
  }
}

class GenTkb {
  final List<Subject> _tkb;
  late final Map<String, SubjectFilter> _input;
  late List<SampleTkb> output = [];
  late List<int> dint = [...emptyDint];
  late int length = 0;
  GenTkb(this._tkb, this._input) {
    _input.forEach((key, value) => _generate(key, value));
  }

  void _generate(String key, SubjectFilter filterLayer) {
    Subject filteredSubject =
        _tkb.firstWhere((subj) => subj.subjectID == key).filter(filterLayer);
    if (output.isEmpty) {
      output
          .addAll(filteredSubject.classes.map((c) => SampleTkb(classes: [c])));
    } else {
      List<SampleTkb> newOutput = [];
      for (SampleTkb sample in output) {
        for (SubjectClass target in filteredSubject.classes) {
          List<int> tmpDint = [...emptyDint];
          for (int i = 0; i < 7; i++) {
            tmpDint[i] = sample.dint[i] & target.dint[i];
          }
          if (tmpDint.fold(0, (a, b) => a + b) == 0) {
            newOutput.add(SampleTkb(classes: sample.classes + [target]));
          }
        }
      }
      output = newOutput;
    }
  }

  GenTkb add(Map<String, SubjectFilter> subj) {
    subj.forEach((key, value) {
      _input[key] = value;
      _generate(key, value);
    });
    return this;
  }

  SubjectFilter? remove(String key) {
    SubjectFilter? value = _input.remove(key);
    output = [];
    _input.forEach((key, value) => _generate(key, value));
    return value;
  }

  bool unsave(SampleTkb sample) => output.remove(sample);

  GenTkb operator +(Map<String, SubjectFilter> subj) => add(subj);
  SubjectFilter? operator -(String key) => remove(key);
}

class Tkb {
  late final List<Subject> tkb;
  late final Map<String, SubjectClass> _tkbLT;
  late final Map<String, String> _teacherByIds;
  final RegExp _ltMatch = RegExp(r"/_LT$/");
  final RegExp _btMatch = RegExp(r"/.[0-9]_BT$/");
  final List<List<String>> _input;
  Tkb(this._input) {
    tkb = [];
    _tkbLT = {};
    _teacherByIds = {};
    Map<String, Map<String, dynamic>> tmpTkb = {};
    Map<String, List<ClassTimeStamp>> tmpClassesLT = {};

    for (List<String> mon in _input) {
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

  String? teacher(String id) => _teacherByIds[id];
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
  for (Subject s in lmao.tkb) {
    print("${s.subjectID}: ");
    print("  Name: ${s.name}");
    print("  Tin chi: ${s.tin}");
    for (SubjectClass c in s.classes) {
      print("    Lop: ${c.classID}");
      print("    dint: ${c.dint}");
    }
  }
  GenTkb k = GenTkb(lmao.tkb, {
    "IS222": SubjectFilter(inClass: ["CSODULIEU.7", "CSODULIEU.8"]),
    "VC204": SubjectFilter(),
  });
	for (SampleTkb s in k.output) {
		print("${s.dint}: ");
		for (SubjectClass c in s.classes) {
      print("    Lop: ${c.classID}");
      print("    dint: ${c.dint}");
    }
	}
}
