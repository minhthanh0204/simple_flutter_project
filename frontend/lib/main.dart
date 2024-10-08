import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const MainApp()); //Chạy ứng dụng với widget MainApp
}

// Widget MainApp là Widget gốc của ứng dụng, sử dụng một StatelessWidget
class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner:
          false, //Tắt biểu tượng debug ở góc phải ở trên
      title: 'Ứng dụng full-stack flutter đơn giản',
      home: MyHomePage(),
    );
  }
}

// Widget MyHomePage là trang chính của ứng dụng, sử dụng StatefulWidget
// Để quản lý trạng thái do có nội dung cần thay đổi trên trang này
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  // TODO: implement createState
  State<MyHomePage> createState() => _MyHomePageState();
}

// Lớp state cho MyHomePage
class _MyHomePageState extends State<MyHomePage> {
  // Controller để lấy dữ liệu từ Widget TextField
  final controller = TextEditingController();
  final controller2 = TextEditingController();
  final controller3 = TextEditingController();
  // Biến để lưu thông điệp phản hồi từ server
  String responseMessage = '';
  //Sử dụng địa chỉ IP thích hợp cho backend
  // Do android Emulator sử dụng địa chỉ 10.0.2.2 để truy cập vào localhost
  // của máy chủ thay vì localhost hoặc 127.0.0.1
  String getBackendUrl() {
    if (kIsWeb) {
      return 'http://localhost:8080'; // hoặc sử dụng Ip LAN nếu cần
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080'; // cho emulator
      //return 'http://192.168.1.x:8080'; // cho thiết bị thật khi truy cập qua LAN
    } else {
      return 'http://localhost:8080';
    }
  }

  // Hàm để gửi tên tới server
  Future<void> sendName() async {
    //Lấy tên từ TextField
    final name = controller.text;
    final studentId = controller2.text;
    final date = controller3.text;

    // Sau khi lấy được tên thì xóa nội dung trong controller
    controller.clear();
    controller2.clear();
    controller3.clear();

    final backendUrl = getBackendUrl();

    // Endpoint submit của server
    final url = Uri.parse('$backendUrl/api/v1/submit');
    try {
      // Gửi yêu cầu POST tới server
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json
                .encode({'name': name, 'studentId': studentId, 'date': date}),
          )
          .timeout(const Duration(seconds: 10));
      //Kiểm tra nếu phản hồi có nội dung
      if (response.body.isNotEmpty) {
        //Giải mã phản hồi từ server
        final data = json.decode(response.body);

        // Cập nhật trạng thái với thông điệp nhận từ server
        setState(() {
          responseMessage = data['message'];
        });
      } else {
        //Phản hồi không có nội dung
        setState(() {
          responseMessage = 'Không nhận được phản hồi từ server';
        });
      }
    } catch (e) {
      setState(() {
        responseMessage = 'Đã xảy ra lỗi: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng dụng full stack flutter đơn giản'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const Text(
              'Hoàng Minh Thành - 2221050565',
              style: TextStyle(fontSize: 20),
            ),
            const Text(
              'Nhập thông tin của sinh viên',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Tên',
                icon: Icon(Icons.account_circle),
              ),
            ),
            TextField(
              controller: controller2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Mã Sinh viên',
                icon: Icon(Icons.school),
              ),
            ),
            TextField(
              controller: controller3,
              decoration: const InputDecoration(
                labelText: 'Ngày sinh',
                icon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickdate = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100));
                if (pickdate != null) {
                  setState(() {
                    controller3.text =
                        DateFormat('dd-MM-yyyy').format(pickdate);
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            FilledButton(
              style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all<Size>(
                const Size(130, 50), // Width and Height of the button
              )),
              onPressed: sendName,
              child: const Text('Gửi', style: TextStyle(fontSize: 20)),
            ),
            //Hiển thị thông điệp phản hồi từ server
            const SizedBox(height: 20),
            const Divider(
              thickness: 2,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                child: const Text(
                  "Kết quả trả về:",
                ),
              ),
            ),

            Text(
              responseMessage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
