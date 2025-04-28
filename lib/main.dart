import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(ProfileApp());

class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iOS Profile Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ProfileHomePage(),
    );
  }
}

class ProfileOption {
  final String name;
  final String key;
  final String value;

  ProfileOption(this.name, this.key, this.value);
}

class ProfileHomePage extends StatefulWidget {
  @override
  _ProfileHomePageState createState() => _ProfileHomePageState();
}

class _ProfileHomePageState extends State<ProfileHomePage> {
  final List<ProfileOption> options = [
    ProfileOption("카메라 차단", "allowCamera", "false"),
    ProfileOption("iCloud 백업 차단", "allowCloudBackup", "false"),
  ];

  final Map<String, bool> selected = {};

  @override
  void initState() {
    super.initState();
    for (var opt in options) {
      selected[opt.key] = false;
    }
  }

  String uuid() {
    final rand = Random.secure();
    return List.generate(4, (_) => rand.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0')).join('-');
  }

  void generateAndDownloadProfile() {
    final payloadItems = options.where((opt) => selected[opt.key] == true).map((opt) {
      return "<key>${opt.key}</key>\n<${opt.value}/>`";
    }).join('\n      ');

    if (payloadItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최소 한 가지 옵션을 선택하세요.')),
      );
      return;
    }

    final profile = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadType</key>
  <string>Configuration</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
  <key>PayloadIdentifier</key>
  <string>com.example.profile</string>
  <key>PayloadUUID</key>
  <string>${uuid()}</string>
  <key>PayloadDisplayName</key>
  <string>Custom iOS Profile</string>
  <key>PayloadOrganization</key>
  <string>Your Company</string>
  <key>PayloadContent</key>
  <array>
    <dict>
      <key>PayloadType</key>
      <string>com.apple.applicationaccess</string>
      <key>PayloadVersion</key>
      <integer>1</integer>
      <key>PayloadIdentifier</key>
      <string>com.example.profile.access</string>
      <key>PayloadUUID</key>
      <string>${uuid()}</string>
      <key>PayloadDisplayName</key>
      <string>Restrictions</string>
      <key>PayloadEnabled</key>
      <true/>
      $payloadItems
    </dict>
  </array>
</dict>
</plist>
''';

    final encoded = base64Encode(utf8.encode(profile));
    final url = 'data:application/x-apple-aspen-config;base64,$encoded';

    final anchor = html.AnchorElement(href: url)
      ..target = '_blank'
      ..download = 'profile.mobileconfig'
      ..click();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('다운로드 완료'),
        content: Text('설정 앱 > 일반 > VPN 및 기기 관리로 이동하여 프로파일을 설치하세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('iOS 프로파일 생성기')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...options.map((opt) => CheckboxListTile(
                  title: Text(opt.name),
                  value: selected[opt.key],
                  onChanged: (val) {
                    setState(() => selected[opt.key] = val ?? false);
                  },
                )),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: generateAndDownloadProfile,
                child: Text('📥 프로파일 다운로드'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
