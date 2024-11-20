import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return base64Encode(iv.bytes + encrypted.bytes); // 合并 iv 和密文
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
      final key = password.padRight(32, '*').substring(0, 32); // 确保32字节密钥
      final encryptedData = encrypt(data, key);
      setState(() {
        _encryptedData = encryptedData;
        _decryptedData = null; // 重置解密结果
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据已成功加密！请妥善保存加密结果和密码。')),
      );
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
          _encryptedData = null; // 解密时清空加密数据（如果需要）
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据已成功解密！请核对解密内容是否正确。')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解密失败！请检查输入的密码是否正确，并确保数据未被篡改。')),
        );
      }
    }
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text)).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已成功复制到剪贴板！请放心使用。')),
      );
    });
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
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '请输入密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 16.0),
              Container(
                constraints: BoxConstraints(maxHeight: 200.0),
                child: TextField(
                  controller: _dataController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    labelText: '请输入数据',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  height: 150.0,
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
                ElevatedButton(
                  onPressed: () => copyToClipboard(_encryptedData ?? _decryptedData!),
                  child: Text('复制结果'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
