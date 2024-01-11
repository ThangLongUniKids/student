import 'package:student/core/presets.dart';

class ClassTimeStamp {
  final int intMatrix;
  late int startStamp;
  late final int startStampUnix;
  late int endStamp;
  late final int endStampUnix;
  final int dayOfWeek;
  late final String day;
  final String classID;
  final String teacherID;
  final String room;
  ClassTimeStamp({
    required this.intMatrix,
    required this.dayOfWeek,
    required this.classID,
    required this.teacherID,
    required this.room,
  }) {
    startStamp = 0;
    if (onlineClass.contains(room)) {
      endStamp = 0;
      startStampUnix = 0;
      endStampUnix = 0;
      day = "";
      return;
    }
    endStamp = 13;
    int tmpDint = intMatrix;
    while (tmpDint != 0) {
      if ((intMatrix & 1) == 0) {
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
  final String subjectID;
  final List<ClassTimeStamp> timestamp;
  late final List<int> intMatrix;
  late final int length;
  late final List<String> teachers;
  late final List<String> rooms;
  SubjectClass({
    required this.classID,
    required this.subjectID,
    required this.timestamp,
  }) {
    intMatrix = [0, 0, 0, 0, 0, 0, 0];
    length = timestamp.length;
    teachers = timestamp.map((m) => m.teacherID).toList();
    rooms = timestamp.map((m) => m.room).toList();
    if (onlineClass.contains(timestamp[0].room)) {
      return;
    }
    for (ClassTimeStamp stamp in timestamp) {
      intMatrix[stamp.dayOfWeek] |= stamp.intMatrix;
    }
  }

  void mergeLT(SubjectClass? lt) {
    if (lt is! SubjectClass) {
      return;
    }
    for (ClassTimeStamp stamp in lt.timestamp) {
      intMatrix[stamp.dayOfWeek] |= stamp.intMatrix;
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
    List<List> verifyList = [
      inClass,
      notInClass,
      includeTeacher,
      excludeTeacher,
      forcefulDint,
      spareDint,
    ];
    for (List property in verifyList) {
      if (property.isNotEmpty) {
        length++;
      }
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
    if (onlineClass.contains(classes[0].rooms[0]) || filterLayer.isEmpty) {
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
        for (int i = 0; i < 7; i++) {
          if (c.intMatrix[i] & filterLayer.forcefulDint[i] != 0) {
            return false;
          }
        }
        return true;
      }).toList();
    }
    if (filterLayer.spareDint.isNotEmpty) {
      List<CompareStamp> o = classes
          .map((c) => CompareStamp(
                delta: (() {
                  double deltaSum = 1.0;
                  for (int i = 0; i < 7; i++) {
                    deltaSum *= 1 + (c.intMatrix[i] & filterLayer.spareDint[i]);
                  }
                  return deltaSum;
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
