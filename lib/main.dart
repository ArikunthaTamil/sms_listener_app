import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SmsHome(),
    );
  }
}

class SmsHome extends StatefulWidget {
  @override
  _SmsHomeState createState() => _SmsHomeState();
}

class _SmsHomeState extends State<SmsHome> {
  static const platform = MethodChannel('com.example.sms/sms');
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _smtpServerController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _receiverEmailController = TextEditingController();

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadEmailConfig();
    requestSmsPermission();
    platform.setMethodCallHandler((call) async {
      if (call.method == "smsReceived") {
        String smsContent = call.arguments;
        print("Received SMS: $smsContent");
        await _sendEmail(smsContent); // Forward the SMS content to email
      }
    });
  }

  Future<void> _loadEmailConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _usernameController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _smtpServerController.text = prefs.getString('smtpServer') ?? '';
      _smtpPortController.text = (prefs.getInt('smtpPort') ?? '').toString();
      _receiverEmailController.text = prefs.getString('receiverEmail') ?? '';
    });
  }

  Future<void> _saveEmailConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text);
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('password', _passwordController.text);
    await prefs.setString('smtpServer', _smtpServerController.text);
    await prefs.setInt(
        'smtpPort', int.tryParse(_smtpPortController.text) ?? 587);
    await prefs.setString('receiverEmail', _receiverEmailController.text);
    setState(() {
      _isEditing = false; // Exit edit mode
    });
  }

  Future<void> requestSmsPermission() async {
    final status = await Permission.sms.request();

    if (status.isGranted) {
      print("SMS permission granted");
      _startListening();
    } else {
      print("SMS permission denied");
    }
  }

  Future<void> _startListening() async {
    try {
      await platform.invokeMethod('startListening');
    } on PlatformException catch (e) {
      print("Failed to start listening: '${e.message}'.");
    }
  }

  Future<void> _sendEmail(String smsContent) async {
    final smtpServer = SmtpServer(
      _smtpServerController.text,
      port: int.tryParse(_smtpPortController.text) ?? 587,
      username: _usernameController.text,
      password: _passwordController.text,
    );

    final message = Message()
      ..from = Address(_emailController.text)
      ..recipients.add(_receiverEmailController.text)
      ..subject = 'New SMS Received'
      ..text = smsContent;

    try {
      await send(message, smtpServer);
      print('Email sent successfully');
    } catch (e) {
      print('Error sending email: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SMS Listener'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveEmailConfig();
              } else {
                setState(() {
                  _isEditing = true; // Enter edit mode
                });
              }
            },
          ),
        ],
      ),
      body: Center(
        child: _isEditing
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Sender Email'),
                    ),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: 'SMTP Username'),
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    TextField(
                      controller: _smtpServerController,
                      decoration: InputDecoration(labelText: 'SMTP Server'),
                    ),
                    TextField(
                      controller: _smtpPortController,
                      decoration: InputDecoration(labelText: 'SMTP Port'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _receiverEmailController,
                      decoration: InputDecoration(labelText: 'Receiver Email'),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Listening for incoming SMS...'),
                  SizedBox(height: 20),
                  Text('Configured Sender Email: ${_emailController.text}'),
                  Text(
                      'Configured Receiver Email: ${_receiverEmailController.text}'),
                ],
              ),
      ),
    );
  }
}
