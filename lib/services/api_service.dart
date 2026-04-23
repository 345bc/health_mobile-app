// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../models/song.dart';

// class ApiService {
//   static const String baseUrl = "http://10.0.2.2:8080/identity";

//   static Future<List<Song>> getSongs() async {
//     final response = await http.get(Uri.parse("$baseUrl/songs"));

//     if (response.statusCode == 200) {
//       List data = jsonDecode(utf8.decode(response.bodyBytes));
//       return data.map((e) => Song.fromJson(e)).toList();
//     } else {
//       throw Exception("Failed to load songs");
//     }
//   }
// }
