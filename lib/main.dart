import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(LockBoxApp());
}

class LockBoxApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LockBox',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LockBoxScreen(),
    );
  }
}

class LockBoxScreen extends StatefulWidget {
  @override
  _LockBoxScreenState createState() => _LockBoxScreenState();
}

class _LockBoxScreenState extends State<LockBoxScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  String? _encryptedData;
  String? _decryptedData;

  String encrypt(String data, String key) {
    final encrypter = enc.Encrypter(enc.AES(enc.Key.fromUtf8(key), mode: enc.AESMode.cbc));
    final iv = enc.IV.fromLength(16);
    final encrypted = encrypter.encrypt(data, iv: iv);
    return base64Encode(iv.bytes + encrypted.bytes);
  }

  String decrypt(String encryptedBase64, String key) {
    final encryptedBytes = base64Decode(encryptedBase64);
    final iv = enc.IV(encryptedBytes.sublist(0, 16));
    final encryptedData = encryptedBytes.sublist(16);
    final encrypter = enc.Encrypter(enc.AES(enc.Key.fromUtf8(key), mode: enc.AESMode.cbc));
    return encrypter.decrypt(enc.Encrypted(encryptedData), iv: iv);
  }

  void handleEncrypt() {
    final data = _dataController.text;
    final password = _passwordController.text;
    if (data.isNotEmpty && password.isNotEmpty) {
      final key = password.padRight(32, '*').substring(0, 32);
      final encryptedData = encrypt(data, key);
      setState(() {
        _encryptedData = encryptedData;
        _decryptedData = null;
      });
      showMessage('数据已成功加密！请妥善保存加密结果和密码。', Colors.green);
    }
  }

  void handleDecrypt() {
    final encryptedJson = _encryptedData;
    final password = _passwordController.text;
    if (encryptedJson != null && password.isNotEmpty) {
      try {
        final key = password.padRight(32, '*').substring(0, 32);
        final decryptedData = decrypt(encryptedJson, key);
        setState(() {
          _decryptedData = decryptedData;
          _encryptedData = null;
        });
        showMessage('数据已成功解密！请核对解密内容是否正确。', Colors.green);
      } catch (e) {
        showMessage('解密失败！请检查输入的密码是否正确，并确保数据未被篡改。', Colors.red);
      }
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((value) {
      showMessage('已成功复制到剪贴板！请放心使用。', Colors.blue);
    });
  }

  void showMessage(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER, // 提示信息居中显示
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('LockBox')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '温馨提示：所有数据均在本地加密，不会存储到任何地方，请妥善保存密码和加密结果！',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '请输入密码',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => _passwordController.clear(),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: _dataController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: '请输入数据',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () => _dataController.clear(),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: handleEncrypt, child: Text('加密')),
                  ElevatedButton(onPressed: handleDecrypt, child: Text('解密')),
                ],
              ),
              if (_encryptedData != null || _decryptedData != null) ...[
                SizedBox(height: 16.0),
                Text(
                  _encryptedData != null ? '加密结果:' : '解密结果:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  constraints: BoxConstraints(minWidth: double.infinity, minHeight: 50),
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _encryptedData ?? _decryptedData!,
                      style: TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => copyToClipboard(_encryptedData ?? _decryptedData!),
                    child: Text('复制结果'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
