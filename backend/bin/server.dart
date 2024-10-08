import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

// Cấu hình các routes
final _router = Router(notFoundHandler: _notFoundHandler)
  ..get('/', _rootHandler)
  ..get('/api/v1/check', _checkHandler)
  ..get('/api/v1/echo/<message>', _echoHandler)
  ..post('/api/v1/submit', _submitHandler);
// Header mặc định cho dữ liệu trả về dưới dạng JSON
final _headers = {'Content-Type': 'application/json'};

// Xử lý các yêu cầu đến các đường dẫn không được định nghĩa (404 Not Found).
Response _notFoundHandler(Request req) {
  return Response.notFound('Không tìm thấy đường dẫn "${req.url}" trên server');
}

/// hàm xử lý các yêu cầu gốc tại đường dẫn '/'
///
/// Trả về một phản hồi với thông điệp "Hello world!" dưới dạng JSON
///
/// [reg]: Đối tượng yêu cầu từ client
///
/// Trả về : Một đối tượng'Response' với mã trạng thái 200 và nội dung JSON

Response _rootHandler(Request req) {
  //Constructor 'ok' của response có statusCode là 200
  return Response.ok(
    json.encode({'message': 'Hello, World!'}),
    headers: _headers,
  );
}

// Hàm xử lý yêu cầu tại đường dẫn '/api/v1/check'
Response _checkHandler(Request req) {
  return Response.ok(
    json.encode({'message': 'Chào mừng bạn đến với ứng dụng web động'}),
    headers: _headers,
  );
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<Response> _submitHandler(Request req) async {
  try {
    //Đọc payload từ request
    final payload = await req.readAsString();
    // Giải mã JSON từ payload
    final data = json.decode(payload);
    // Lấy gía trị 'name,studentid,date' từ data, ép kiểu về String? nếu có
    final name = data['name'] as String?;
    final studentId = data['studentId'] as String?;
    final date = data['date'] as String?;
    // Kiểm tra nếu'name,studentid,date' hợp lệ
    if (name != null &&
        name.isNotEmpty &&
        !name.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>1234567890]')) &&
        studentId != null &&
        studentId.length < 11 &&
        studentId.isNotEmpty &&
        date != null &&
        date.isNotEmpty) {
      // Tạo phản hồi chào mừng
      final response = {
        'message':
            'Chào mừng đến với thông tin của bạn \n Tên: $name \n Mã Sinh viên: $studentId \n Ngày sinh:$date'
      };
      // Trả về phản hồi với statusCode 200 và nội dung JSON
      return Response.ok(
        json.encode(response),
        headers: _headers,
      );
    } else {
      //Tạo phản hồi yêu cầu cung cấp thông tin
      final response = {'message': 'Server không nhận được thông tin của bạn.'};
      // Trả về phản hồi với statusCode 400 và nội dung JSON
      return Response.badRequest(
        body: json.encode(response),
        headers: _headers,
      );
    }
  } catch (e) {
    //Xử lý ngoại lệ khi giải mã JSON
    final response = {'message': 'Yêu cầu không hợp lệ. Lỗi ${e.toString()}'};
    //Trả về phản hồi với statusCode 400
    return Response.badRequest(
      body: json.encode(response),
      headers: _headers,
    );
  }
}

void main(List<String> args) async {
  // Lắng nghe trên tất cả các địa chỉ IPv4
  final ip = InternetAddress.anyIPv4;

  final corsHeader = createMiddleware(
    requestHandler: (req) {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: {
          //Cho phép mọi nguồn truy cập (trong môi trường dev). Trong môi trường production chúng ta nên thay * bằng domain cụ thể.
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,PATCH,HEAD',
          'Access-Control-Allow-Headers': 'Content-Type,Authorization',
        });
      }
      return null; //Tiếp tục xử lý các yêu cầu khác
    },
    responseHandler: (res) {
      return res.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,PATCH,HEAD',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      });
    },
  );

  // Cấu hình một pipline để logs các requests và middleware
  final handler = Pipeline()
      .addMiddleware(corsHeader) // Thêm middleware xử lý CORS
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // Để chạy trong các container, chúng ta sẽ sử dụng biến môi trường PORT.
  // Nếu biến môi trường không được thiết lập nó sẽ sử dụng giá trị từ biến
  //Môi trường này;nếu không , nó sẽ sử dụng giá trị mặc định là 8080.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  //Khởi chạy server tại địa chỉ và cổng chỉ định
  final server = await serve(handler, ip, port);
  print('Server đang chạy tại http://${server.address.host}:${server.port}');
}
