import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;

  Duration _lastTick = Duration.zero;

  bool _cameraStatus = true;
  final _dateTime = ValueNotifier<DateTime>(DateTime.now());

  final baseUrl = 'http://192.168.0.245';
  late final rebootAPI = '$baseUrl/form/reboot';
  late final presetSetAPI = '$baseUrl/form/presetSet';
  late final setPTZCfgAPI = '$baseUrl/form/setPTZCfg';

  late final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      },
      connectTimeout: const Duration(seconds: 1),
      receiveTimeout: const Duration(seconds: 1),
    ),
  );

  Future<bool> ping() async =>
      await dio.head(baseUrl).then((response) => response.statusCode == 200);
  Future<void> reboot() async => await dio.get(rebootAPI);
  Future<void> onPresset(num presetNum) async => await dio.post(
        presetSetAPI,
        data: {
          'flag': '4',
          'existFlag': '1',
          'language': 'cn',
          'presetNum': presetNum,
        },
      );
  Future<void> onCommand(num command) async {
    final body = {
      'command': command,
      'ZFSpeed': 0,
      'PTSpeed': 0,
      'panSpeed': 1,
      'tiltSpeed': 1,
      'focusSpeed': 2,
      'FocusMode': 2,
      'zoomSpeed': 2,
      'standBy': 0,
    };
    await dio.post(
      setPTZCfgAPI,
      data: body,
    );

    await Future.delayed(const Duration(milliseconds: 300));
    body['command'] = 0;
    await dio.post(setPTZCfgAPI, data: body);
    body['command'] = 55;
    await dio.post(setPTZCfgAPI, data: body);
    body['command'] = 0;
    await dio.post(setPTZCfgAPI, data: body);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _ticker = Ticker(
      (elapsed) async {
        _dateTime.value = DateTime.now();
        if (_lastTick == Duration.zero) {
          _lastTick = elapsed;
        } else {
          final difference = (elapsed - _lastTick).inSeconds;
          if (difference >= 5) {
            _lastTick = elapsed;
            try {
              _cameraStatus = await ping();
            } catch (_) {
              _cameraStatus = false;
            }
            if (!mounted) return;
            if (_cameraStatus) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              return;
            }
            final snackBar = SnackBar(
              content: Text('Câmera Desligada!'),
              duration: Duration(seconds: 5),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        }
      },
    )..start();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ValueListenableBuilder(
              valueListenable: _dateTime,
              builder: (_, value, __) => Text(
                DateFormat('HH:mm:ss - dd/MM/yyyy').format(value),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _presets()),
                IntrinsicHeight(child: VerticalDivider(color: Colors.black)),
                Expanded(child: _zoomRestart()),
                IntrinsicHeight(child: VerticalDivider(color: Colors.black)),
                Expanded(flex: 2, child: _moveActions()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moveActions() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          Text('Movimento'),
          ElevatedButton(
            onPressed: () => onCommand(1),
            child: Column(
              children: [
                Icon(Icons.arrow_circle_up),
                Text('Cima'),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onPresset(3),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_circle_left),
                      Text('Esquerda'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onPresset(4),
                  child: Column(
                    children: [
                      Icon(Icons.arrow_circle_right),
                      Text('Direita'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => onPresset(2),
            child: Column(
              children: [
                Icon(Icons.arrow_circle_down),
                Text('Baixo'),
              ],
            ),
          ),
        ],
      );

  Widget _zoomRestart() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          Text('Comandos'),
          ElevatedButton(
            onPressed: () => onCommand(13),
            child: Column(
              children: [
                Icon(Icons.zoom_in),
                Text('Zoom +'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => onPresset(14),
            child: Column(
              children: [
                Icon(Icons.zoom_out),
                Text('Zoom -'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: reboot,
            child: Column(
              children: [
                Icon(Icons.restart_alt),
                Text('Reiniciar'),
              ],
            ),
          ),
        ],
      );

  Widget _presets() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8.0,
        children: [
          Text('Presets'),
          ElevatedButton(
            onPressed: () => onPresset(0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home),
                    Text('[0]'),
                  ],
                ),
                Text('Salão'),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => onPresset(3),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.table_bar),
                    Text('[3]'),
                  ],
                ),
                Text('Mesa'),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onPresset(1),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_circle),
                          Text('[1]'),
                        ],
                      ),
                      Text('Tribuna'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onPresset(2),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_library),
                          Text('[2]'),
                        ],
                      ),
                      Text('Leitor'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () => onPresset(4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle),
                    Icon(Icons.local_library),
                    Text('[4]'),
                  ],
                ),
                Text('Orador e Leitor'),
              ],
            ),
          )
        ],
      );
}
