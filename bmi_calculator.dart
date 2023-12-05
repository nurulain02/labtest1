// main.dart
import 'package:flutter/material.dart';
import '../controller/sqlite_db.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Calculator',
      home: BMICalculator(),
    );
  }
}

class BMICalculator extends StatefulWidget {
  @override
  _BMICalculatorState createState() => _BMICalculatorState();
}

class _BMICalculatorState extends State<BMICalculator> {
  TextEditingController nameController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController heightController = TextEditingController();

  String result = '';
  String status = '';
  String gender = 'male';

  List<double> maleBMIs = [];
  List<double> femaleBMIs = [];

  SQLiteDb dbHelper = SQLiteDb();


  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await dbHelper.init();
    Map<String, dynamic>? data = await dbHelper.getData();
    if (data != null) {
      setState(() {
        nameController.text = data['username'] ?? '';
        weightController.text = data['weight'] ?? '';
        heightController.text = data['height'] ?? '';
        gender = data['gender'] ?? 'male';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BMI Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: heightController,
              decoration: InputDecoration(labelText: 'Height (cm)'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text('Gender:'),
                SizedBox(width: 10),
                Radio(
                  value: 'male',
                  groupValue: gender,
                  onChanged: (value) {
                    setState(() {
                      gender = value.toString();
                    });
                  },
                ),
                Text('Male'),
                SizedBox(width: 10),
                Radio(
                  value: 'female',
                  groupValue: gender,
                  onChanged: (value) {
                    setState(() {
                      gender = value.toString();
                    });
                  },
                ),
                Text('Female'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                calculateBMI();
              },
              child: Text('Calculate BMI'),
            ),
            SizedBox(height: 20),
            Text('BMI: $result', style: TextStyle(fontSize: 18)),
            Text('Status: $status', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            FutureBuilder<Map<String, dynamic>?>(
              future: dbHelper.getData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  int maleCount = snapshot.data!['maleCount'] ?? 0;
                  int femaleCount = snapshot.data!['femaleCount'] ?? 0;
                  double maleAverageBMI = snapshot.data!['male_average_bmi'] ?? 0;
                  double femaleAverageBMI = snapshot.data!['female_average_bmi'] ?? 0;

                  return Column(
                    children: [
                      Text(
                        'Statistics:\nMale Count: $maleCount\nFemale Count: $femaleCount',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Average BMI:\nMale: ${maleAverageBMI.toStringAsFixed(2)}\nFemale: ${femaleAverageBMI.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  );
                } else {
                  return Text('No data available');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void calculateBMI() async {
    double weight = double.tryParse(weightController.text) ?? 0;
    double height = double.tryParse(heightController.text) ?? 0;

    if (weight > 0 && height > 0) {
      double bmi = weight / ((height / 100) * (height / 100));

      setState(() {
        result = bmi.toStringAsFixed(2);

        if (gender == 'male') {
          status = getMaleBMIStatus(bmi);
          maleBMIs.add(bmi); // Store individual BMI for male
        } else {
          status = getFemaleBMIStatus(bmi);
          femaleBMIs.add(bmi); // Store individual BMI for female
        }

        dbHelper.saveData(
          name: nameController.text,
          weight: weightController.text,
          height: heightController.text,
          gender: gender,
          bmiStatus: status,
        );
      });
    } else {
      setState(() {
        result = 'Invalid input';
        status = '';
      });
    }
  }
  void calculateAverageBMI() async {
    List<Map<String, dynamic>> dataList = await dbHelper.getDataList();

    Map<String, dynamic> statistics = dbHelper.calculateStatistics(dataList);

    double maleAverageBMI = statistics['male_average_bmi'];
    double femaleAverageBMI = statistics['female_average_bmi'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Average BMI'),
          content: Column(
            children: [
              Text('Male: ${maleAverageBMI.toStringAsFixed(2)}'),
              Text('Female: ${femaleAverageBMI.toStringAsFixed(2)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }


  String getMaleBMIStatus(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight. Careful during strong wind!';
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return 'That’s ideal! Please maintain';
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      return 'Overweight! Work out please';
    } else {
      return 'Whoa Obese! Dangerous mate!';
    }
  }

  String getFemaleBMIStatus(double bmi) {
    if (bmi < 16) {
      return 'Underweight. Careful during strong wind!';
    } else if (bmi >= 16 && bmi <= 22) {
      return 'That’s ideal! Please maintain';
    } else if (bmi >= 22 && bmi <= 27) {
      return 'Overweight! Work out please';
    } else {
      return 'Whoa Obese! Dangerous mate!';
    }
  }
}
