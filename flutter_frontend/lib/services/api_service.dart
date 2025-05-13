import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // 后端API地址配置
  // 开发环境配置指南：
  // - 模拟器测试：使用10.0.2.2（Android）或localhost（iOS）
  // - 真机测试：使用计算机的局域网IP地址
  // - 端口号应与后端HTTPS_PORT环境变量一致（默认5443）
  //static const String _baseUrl = 'https://10.0.2.2:5443/api'; // 使用HTTPS端口
  static const String _baseUrl = 'http://10.0.2.2:5000/api'; // 使用HTTP端口

  // Helper method for GET requests
  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...?headers, // Spread operator to add optional headers
      },
    );
    return _handleResponse(response);
  }

  // Helper method for POST requests
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...?headers,
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // Helper method for PUT requests
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, {Map<String, String>? headers}) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...?headers,
      },
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  // Helper method for DELETE requests
  static Future<Map<String, dynamic>> delete(String endpoint, {Map<String, String>? headers}) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        ...?headers,
      },
    );
    return _handleResponse(response);
  }

  // Helper method to handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes)); // Decode using UTF-8
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      // Throw an exception with the error message from the backend, if available
      throw Exception('API Error (${response.statusCode}): ${responseBody['message'] ?? response.reasonPhrase}');
    }
  }

  // --- Auth Endpoints ---

  // User Registration
  static Future<Map<String, dynamic>> register(String username, String password, String email, String? phone) async {
    return await post('/auth/register', {
      'username': username,
      'password': password,
      'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
  }

  // User Login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    return await post('/auth/login', {
      'username': username,
      'password': password,
    });
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await get('/auth/profile/$userId');
  }

  // Update User Profile
  static Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
    // Assuming the backend endpoint for updating is PUT /auth/profile/:userId
    return await put('/auth/profile/$userId', data);
  }

  // --- Chat Endpoints ---

  // Create a new conversation
  static Future<Map<String, dynamic>> createConversation(String userId, {String? title}) async {
    return await post('/chat/conversations', {
      'userId': userId,
      if (title != null && title.isNotEmpty) 'title': title,
    });
  }

  // Get all conversations for a user
  static Future<Map<String, dynamic>> getConversations(String userId) async {
    return await get('/chat/conversations/user/$userId');
  }

  // Get all messages for a conversation
  static Future<Map<String, dynamic>> getMessages(String conversationId) async {
    return await get('/chat/conversations/$conversationId/messages');
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage(String conversationId, String userId, String content, {String modelType = 'volcengine'}) async {
    return await post('/chat/conversations/$conversationId/messages', {
      'userId': userId,
      'content': content,
      'modelType': modelType,
    });
  }

  // Delete a conversation
  static Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    return await delete('/chat/conversations/$conversationId');
  }

  // Rename a conversation
  static Future<Map<String, dynamic>> renameConversation(String conversationId, String newTitle) async {
    return await put('/chat/conversations/$conversationId', {
      'title': newTitle,
    });
  }

  // Get available AI models
  static Future<Map<String, dynamic>> getAvailableModels() async {
    return await get('/chat/models');
  }

  // --- Records Endpoints ---

  // Upload a text record
  static Future<Map<String, dynamic>> uploadTextRecord(String userId, String textContent, String recordType, String description) async {
    return await post('/records/upload', {
      'userId': userId,
      'recordType': recordType,
      'textContent': textContent,
      'description': description,
      'type': 'text'
    });
  }

  // Upload a record (handles both file and text content)
  // Note: File upload requires a different approach using multipart request
  static Future<Map<String, dynamic>> uploadRecordText(String userId, String recordType, String textContent, {String? description}) async {
    return await post('/records/upload', {
      'userId': userId,
      'recordType': recordType,
      'textContent': textContent,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }

  // Upload a file record using multipart request
  static Future<Map<String, dynamic>> uploadRecordFile(String userId, String recordType, String filePath, {String? description, String? textContent}) async {
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/records/upload'));
    
    // Add file with encoded filename
    final file = await http.MultipartFile.fromPath('file', filePath);
    final originalFileName = file.filename;
    final encodedFileName = Uri.encodeComponent(originalFileName ?? '');
    
    // Create a new MultipartFile with encoded filename
    final encodedFile = http.MultipartFile(
      'file',
      file.finalize(),
      file.length,
      filename: encodedFileName,
      contentType: file.contentType
    );
    request.files.add(encodedFile);
    
    // Add other fields
    request.fields['userId'] = userId;
    request.fields['recordType'] = recordType;
    request.fields['originalFileName'] = originalFileName ?? ''; // 添加原始文件名作为单独的字段
    if (description != null) request.fields['description'] = description;
    if (textContent != null) request.fields['textContent'] = textContent;
    
    // Send request
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _handleResponse(response);
  }

  // 获取文件的MIME类型
  static MediaType _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // Upload Record with XFile
  static Future<Map<String, dynamic>> uploadRecord({
    required String userId,
    required XFile file,
    required String recordType,
    required String description,
  }) async {
    var uri = Uri.parse('$_baseUrl/records/upload');
    var request = http.MultipartRequest('POST', uri);
    // 对文件名进行UTF-8编码
    var encodedFilename = Uri.encodeComponent(file.name);
    // 添加文件
    final bytes = await file.readAsBytes();
    final extension = file.name.split('.').last;
    var mimeType = _getMimeType(extension);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: encodedFilename,
        contentType: mimeType,
      ),
    );


    // 添加其他字段
    request.fields['userId'] = userId;
    request.fields['recordType'] = recordType;
    request.fields['description'] = description;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('上传文件失败: ${e.toString()}');
    }
  }
  
  // Upload a file as message attachment and send message
  static Future<Map<String, dynamic>> sendMessageWithAttachment(String conversationId, String userId, String content, String filePath, {String modelType = 'volcengine'}) async {
    // First upload the file as a record
    final recordResponse = await uploadRecordFile(userId, 'attachment', filePath);
    final recordId = recordResponse['record']['_id'];
    
    // Then send the message with attachment reference
    return await post('/chat/conversations/$conversationId/messages', {
      'userId': userId,
      'content': content,
      'modelType': modelType,
      'attachments': [{'recordId': recordId}]
    });
  }

  // Get all records for a user
  static Future<Map<String, dynamic>> getRecords(String userId) async {
    return await get('/records/user/$userId');
  }

  // Get details for a single record
  static Future<Map<String, dynamic>> getRecordDetail(String recordId, String userId) async {
    // Pass userId as a query parameter for authorization check in backend
    return await get('/records/$recordId?userId=$userId');
  }

  // Download record file
  static Future<List<int>> downloadRecordFile(String recordId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/records/$recordId/file?userId=$userId'),
        headers: {
          'Accept': '*/*',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        final Map<String, dynamic> errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('下载失败 (${response.statusCode}): ${errorBody['message'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('下载文件失败: ${e.toString()}');
    }
  }

  // Download a record file
  // static Future<List<int>> downloadRecordFile(String recordId, String userId) async {
  //   final response = await http.get(
  //     Uri.parse('$_baseUrl/records/$recordId/download?userId=$userId'),
  //     headers: {
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //   );
    
  //   if (response.statusCode >= 200 && response.statusCode < 300) {
  //     return response.bodyBytes;
  //   } else {
  //     final Map<String, dynamic> responseBody = jsonDecode(utf8.decode(response.bodyBytes));
  //     throw Exception('下载失败 (${response.statusCode}): ${responseBody['message'] ?? response.reasonPhrase}');
  //   }
  // }

  // Delete a record
  static Future<Map<String, dynamic>> deleteRecord(String recordId, String userId) async {
    // Pass userId in the body or headers if needed for authorization, 
    // although DELETE typically uses URL params or relies on session/token auth.
    // Assuming backend checks ownership based on authenticated user or requires userId in query/body.
    // Let's add userId to the body for consistency with backend expectation (if any).
    // Adjust if backend expects it differently (e.g., query param).
    // NOTE: Standard REST practice might not put a body in DELETE. Check backend implementation.
    // Simpler approach: Backend uses auth token to identify user.
    // If backend requires userId explicitly for deletion check:
    // return await delete('/records/$recordId?userId=$userId'); 
    return await delete('/records/$recordId'); // Assuming backend identifies user via auth token
  }
}