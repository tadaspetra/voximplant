import 'package:flutter/material.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  VIClient _client = Voximplant().getClient();

  String _displayName = "Please Login";
  bool isLoggedIn = false;
  VICall? currentCall;
  String urlmessage = "no message";

  Future<void> loginWithPassword(String username, String password) async {
    VIClientState clientState = await _client.getClientState();
    if (clientState == VIClientState.LoggedIn) {
      // already done
      isLoggedIn = true;
      setState(() {});
      return;
    }
    if (clientState == VIClientState.Disconnected) {
      await _client.connect();
    }
    VIAuthResult authResult = await _client.login(username, password);
    setState(() {
      _displayName = authResult.displayName;
      isLoggedIn = true;
      print(_displayName);
    });
  }

  Future<VICall> makeVideoCall(String number) async {
    // get permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();
    print(statuses);

    // create a call
    VICallSettings callSettings = VICallSettings();
    callSettings.videoFlags = VIVideoFlags(sendVideo: true, receiveVideo: true);
    VICall call = await _client.call(number, settings: callSettings);

    // callbacks for the call
    call.onCallDisconnected = _onCallDisconnected;
    call.onCallFailed = _onCallFailed;
    call.onCallConnected = _onCallConnected;
    call.onCallRinging = _onCallRinging;
    call.onCallAudioStarted = _onCallAudioStarted;
    call.onMessageReceived = _onMessageReceived;

    return call;
  }

  _onMessageReceived(VICall call, String message) {
    setState(() {
      urlmessage = message;
    });
    print(message);
  }

  _onCallConnected(VICall call, Map<String, String>? headers) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Call Connected")));
    print('Call connected');
  }

  _onCallDisconnected(VICall call, Map<String, String>? headers, bool something) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Call Ended")));
    setState(() {});
    print('Call disconnected');
  }

  _onCallFailed(VICall call, int something, String somethingelse, Map<String, String>? headers) {
    print(headers);
    print('Call failed');
  }

  _onCallRinging(VICall call, Map<String, String>? headers) {
    print('Call ringing');
  }

  _onCallAudioStarted(VICall call) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Call Started")));
    print('Call audio started');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vox Implant"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Logged In: " + _displayName),
            ElevatedButton(
              onPressed: () {
                loginWithPassword("tadaspetra@demo.tadaspetra.n2.voximplant.com", "12345678");
              },
              child: Text("Login"),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentCall != null) {
                  currentCall?.hangup();
                }
              },
              child: Text("Disconnect Call"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          currentCall = await makeVideoCall("+699110235");
        },
        tooltip: 'Increment',
        child: Icon(Icons.phone),
      ),
    );
  }
}
