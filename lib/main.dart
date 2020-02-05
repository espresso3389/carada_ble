import 'package:flutter/material.dart';

import 'carada.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CARADA Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final carada = ValueNotifier<CaradaClient>(null);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      carada.value = await CaradaClient.discoverDevice();
      await carada.value.start();
    });
  }

  @override
  void dispose() {
    carada.value?.stop();
    carada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CARADA Demo'),
      ),
      body: ValueListenableBuilder<CaradaClient>(
        valueListenable: carada,
        builder: (context, client, child) {
          if (client == null) {
            return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TGF901-BTを検索中...', style: TextStyle(fontSize: 30.0)),
                    SizedBox(height: 10),
                    CircularProgressIndicator()
                  ]
                )
              );
          }
          return StreamBuilder<CaradaData>(
            stream: client.stream,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null) {
                return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('体組成計と通信中...', style: TextStyle(fontSize: 30.0)),
                    SizedBox(height: 10),
                    CircularProgressIndicator()
                  ]
                )
              );
              }
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('体重 ${data.weight} kg', style: TextStyle(fontSize: 40.0)),
                    Text('体脂肪率 ${data.bodyFats} %', style: TextStyle(fontSize: 40.0)),
                    Text('体水分量 ${data.totalBodyWater} %', style: TextStyle(fontSize: 40.0)),
                    Text('体筋肉率 ${data.bodyMusclePerc} %', style: TextStyle(fontSize: 40.0)),
                    Text('骨量 ${data.boneMass} kg', style: TextStyle(fontSize: 40.0)),
                    Text('基礎代謝量 ${data.basalMetabolicRate} kcal', style: TextStyle(fontSize: 40.0)),
                  ]
                )
              );
            }
          );
        }
      )// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}