// sqlite_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteDb {
  static const String _dbName = "bitp3453_bmi";
  static const String _tblName = "bmi";
  static const String _colUsername = "username";
  static const String _colWeight = "weight";
  static const String _colHeight = "height";
  static const String _colGender = "gender";
  static const String _colStatus = "bmi_status";

  late Database _database;

  Future<void> init() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), _dbName),
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE $_tblName("
              "$_colUsername TEXT, "
              "$_colWeight TEXT, "
              "$_colHeight TEXT, "
              "$_colGender TEXT, "
              "$_colStatus TEXT)",
        );
      },
    );
  }

  Future<void> saveData({
    String? name,
    String? weight,
    String? height,
    String? gender,
    String? bmiStatus,
  }) async {
    await _database.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR REPLACE INTO $_tblName($_colUsername, $_colWeight, $_colHeight, $_colGender, $_colStatus) VALUES(?, ?, ?, ?, ?)',
        [name, weight, height, gender, bmiStatus],
      );
    });
  }

  Future<Map<String, dynamic>?> getData() async {
    List<Map<String, dynamic>> results = await _database.query(_tblName);
    return results.isNotEmpty ? calculateStatistics(results) : null;
  }

  Future<List<Map<String, dynamic>>> getDataList() async {
    List<Map<String, dynamic>> results = await _database.query(_tblName);
    return results;
  }

  Map<String, dynamic> calculateStatistics(List<Map<String, dynamic>> dataList) {
    int maleCount = 0;
    int femaleCount = 0;
    double maleTotalBMI = 0;
    double femaleTotalBMI = 0;

    for (var data in dataList) {
      double bmi = double.tryParse(data['bmi_status'].toString()) ?? 0;

      if (data['gender'] == 'male') {
        maleTotalBMI += bmi;
        maleCount++;
      } else {
        femaleTotalBMI += bmi;
        femaleCount++;
      }
    }

    double maleAverageBMI = maleCount > 0 ? maleTotalBMI / maleCount : 0;
    double femaleAverageBMI = femaleCount > 0 ? femaleTotalBMI / femaleCount : 0;

    return {
      'maleCount': maleCount,
      'femaleCount': femaleCount,
      'male_average_bmi': maleAverageBMI,
      'female_average_bmi': femaleAverageBMI,
    };
  }
}





