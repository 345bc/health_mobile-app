// import 'package:flutter/material.dart';

// void main() {
//   runApp(const HealthAppMockup());
// }

// class HealthAppMockup extends StatelessWidget {
//   const HealthAppMockup({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         scaffoldBackgroundColor: const Color(0xFFF7F8FA),
//         fontFamily: 'Inter',
//       ),
//       home: const StatsScreen(),
//     );
//   }
// }

// class StatsScreen extends StatelessWidget {
//   const StatsScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           physics: const BouncingScrollPhysics(),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 20.0,
//               vertical: 10.0,
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const CustomHeader(),
//                 const SizedBox(height: 24),
//                 const TimeSegmentControl(),
//                 const SizedBox(height: 30),
//                 const ActivitySection(),
//                 const SizedBox(height: 20),
//                 const QuickStatsRow(),
//                 const SizedBox(height: 20),
//                 const AiSuggestionCard(),
//                 const SizedBox(height: 30),
//                 const SleepQualitySection(),
//                 const SizedBox(height: 100),
//               ],
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: const CustomBottomNavBar(),
//       extendBody: true,
//     );
//   }
// }

// // ================= WIDGETS =================

// class CustomHeader extends StatelessWidget {
//   const CustomHeader({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         CircleAvatar(
//           radius: 22,
//           backgroundImage: const NetworkImage(
//             'https://i.pravatar.cc/150?img=11',
//           ),
//           onBackgroundImageError: (e, s) {},
//           child: const Icon(Icons.person, color: Colors.white),
//         ),
//         const SizedBox(width: 12),
//         const Text(
//           'Thống kê & Xu hướng',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 22,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF111111),
//           ),
//         ),
//         const Spacer(),
//         const Icon(Icons.notifications, color: Color(0xFF0F75F4), size: 28),
//       ],
//     );
//   }
// }

// class TimeSegmentControl extends StatelessWidget {
//   const TimeSegmentControl({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 48,
//       decoration: BoxDecoration(
//         color: const Color(0xFFEBECEE),
//         borderRadius: BorderRadius.circular(24),
//       ),
//       padding: const EdgeInsets.all(4),
//       child: Row(
//         children: [
//           _buildTab(context, 'Ngày', isActive: true),
//           _buildTab(context, 'Tuần'),
//           _buildTab(context, 'Tháng'),
//           _buildTab(context, 'Năm'),
//         ],
//       ),
//     );
//   }

//   Widget _buildTab(
//     BuildContext context,
//     String title, {
//     bool isActive = false,
//   }) {
//     return Expanded(
//       child: Container(
//         decoration: BoxDecoration(
//           color: isActive ? Colors.white : Colors.transparent,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: isActive
//               ? [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ]
//               : [],
//         ),
//         alignment: Alignment.center,
//         child: Text(
//           title,
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 15,
//             fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
//             color: isActive ? const Color(0xFF0F75F4) : const Color(0xFF6C757D),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ActivitySection extends StatelessWidget {
//   const ActivitySection({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'HOẠT ĐỘNG TUẦN NÀY',
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 13,
//             fontWeight: FontWeight.w700,
//             letterSpacing: 1.2,
//             color: Color(0xFF0F75F4),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             const Text(
//               '74,230',
//               style: TextStyle(
//                 fontFamily: 'Inter',
//                 fontSize: 34,
//                 fontWeight: FontWeight.w800,
//                 color: Color(0xFF111111),
//                 height: 1,
//               ),
//             ),
//             const SizedBox(width: 8),
//             const Padding(
//               padding: EdgeInsets.only(bottom: 4.0),
//               child: Text(
//                 'bước',
//                 style: TextStyle(
//                   fontFamily: 'Inter',
//                   fontSize: 18,
//                   fontWeight: FontWeight.w400,
//                   color: Color(0xFF6C757D),
//                 ),
//               ),
//             ),
//             const Spacer(),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFD1F2D9),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.trending_up, color: Color(0xFF198754), size: 16),
//                   SizedBox(width: 4),
//                   Text(
//                     '+12% vs tuần trước',
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFF198754),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//         // Chart Area
//         Container(
//           height: 200,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.03),
//                 blurRadius: 10,
//                 spreadRadius: 2,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(
//                   bottom: 20.0,
//                   left: 16,
//                   right: 16,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'].map((
//                     day,
//                   ) {
//                     bool isToday = day == 'T4';
//                     return Text(
//                       day,
//                       style: TextStyle(
//                         fontFamily: 'Inter',
//                         fontSize: 12,
//                         fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
//                         color: isToday ? const Color(0xFF0F75F4) : Colors.black,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }

// class QuickStatsRow extends StatelessWidget {
//   const QuickStatsRow({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatCard(
//             icon: Icons.favorite,
//             iconColor: const Color(0xFFDC3545),
//             iconBg: const Color(0xFFFDECEA),
//             title: 'NHỊP TIM TB',
//             value: '72',
//             unit: 'bpm',
//             bottomWidget: const Text(
//               'Ổn định',
//               style: TextStyle(
//                 fontFamily: 'Inter',
//                 fontSize: 13,
//                 fontWeight: FontWeight.w700,
//                 color: Color(0xFF198754),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: _buildStatCard(
//             icon: Icons.water_drop,
//             iconColor: const Color(0xFF0F75F4),
//             iconBg: const Color(0xFFE7F1FF),
//             title: 'TỔNG NƯỚC',
//             value: '14.5',
//             unit: 'Lít',
//             bottomWidget: Stack(
//               children: [
//                 Container(
//                   height: 6,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFEBECEE),
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//                 Container(
//                   height: 6,
//                   width: 80,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF0F75F4),
//                     borderRadius: BorderRadius.circular(3),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard({
//     required IconData icon,
//     required Color iconColor,
//     required Color iconBg,
//     required String title,
//     required String value,
//     required String unit,
//     required Widget bottomWidget,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.03),
//             blurRadius: 10,
//             spreadRadius: 2,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(shape: BoxShape.circle, color: iconBg),
//             child: Icon(icon, color: iconColor, size: 24),
//           ),
//           const SizedBox(height: 20),
//           Text(
//             title,
//             style: const TextStyle(
//               fontFamily: 'Inter',
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 1.0,
//               color: Color(0xFF111111),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 value,
//                 style: const TextStyle(
//                   fontFamily: 'Inter',
//                   fontSize: 28,
//                   fontWeight: FontWeight.w800,
//                   color: Color(0xFF111111),
//                   height: 1,
//                 ),
//               ),
//               const SizedBox(width: 4),
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 3.0),
//                 child: Text(
//                   unit,
//                   style: const TextStyle(
//                     fontFamily: 'Inter',
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Color(0xFF111111),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           bottomWidget,
//         ],
//       ),
//     );
//   }
// }

// class AiSuggestionCard extends StatelessWidget {
//   const AiSuggestionCard({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0F75F4),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF0F75F4).withOpacity(0.3),
//             blurRadius: 15,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: const Icon(
//               Icons.auto_awesome,
//               color: Colors.white,
//               size: 28,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Gợi ý từ Trí tuệ ảo',
//                   style: TextStyle(
//                     fontFamily: 'Inter',
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 RichText(
//                   text: TextSpan(
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       fontSize: 15,
//                       fontWeight: FontWeight.w400,
//                       color: Colors.white.withOpacity(0.9),
//                       height: 1.5,
//                     ),
//                     children: const [
//                       TextSpan(text: 'Dựa trên dữ liệu tuần qua, bạn nên '),
//                       TextSpan(
//                         text: 'đi ngủ sớm hơn 30 phút',
//                         style: TextStyle(
//                           fontFamily: 'Inter',
//                           fontWeight: FontWeight.w700,
//                           decoration: TextDecoration.underline,
//                         ),
//                       ),
//                       TextSpan(
//                         text:
//                             ' để cải thiện chỉ số hồi phục và nhịp tim buổi sáng.',
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {},
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.white,
//                     foregroundColor: const Color(0xFF0F75F4),
//                     elevation: 0,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                   ),
//                   child: const Text(
//                     'Thiết lập nhắc nhở',
//                     style: TextStyle(
//                       fontFamily: 'Inter',
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SleepQualitySection extends StatelessWidget {
//   const SleepQualitySection({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           flex: 6,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Chất lượng giấc ngủ',
//                 style: TextStyle(
//                   fontFamily: 'Inter',
//                   fontSize: 22,
//                   fontWeight: FontWeight.w700,
//                   color: Color(0xFF111111),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Thời gian ngủ sâu của bạn tăng 15% so với tháng trước nhờ thói quen thiền định.',
//                 style: TextStyle(
//                   fontFamily: 'Inter',
//                   fontSize: 15,
//                   fontWeight: FontWeight.w400,
//                   color: Color(0xFF495057),
//                   height: 1.5,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           flex: 4,
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(20),
//             child: Image.network(
//               'https://images.unsplash.com/photo-1518241353330-0f797844d187?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
//               height: 100,
//               fit: BoxFit.cover,
//               errorBuilder: (context, error, stackTrace) {
//                 return Container(
//                   height: 100,
//                   color: Colors.grey[300],
//                   child: const Center(
//                     child: Icon(Icons.image_not_supported, color: Colors.grey),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class CustomBottomNavBar extends StatelessWidget {
//   const CustomBottomNavBar({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(30),
//           topRight: Radius.circular(30),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 20,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           _buildNavItem(
//             icon: Icons.home_filled,
//             label: 'HOME',
//             isActive: false,
//           ),
//           _buildNavItem(icon: Icons.bar_chart, label: 'STATS', isActive: true),
//           _buildNavItem(
//             icon: Icons.add_circle_outline,
//             label: 'LOG',
//             isActive: false,
//           ),
//           _buildNavItem(
//             icon: Icons.person_outline,
//             label: 'PROFILE',
//             isActive: false,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavItem({
//     required IconData icon,
//     required String label,
//     required bool isActive,
//   }) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: isActive ? const Color(0xFFE7F1FF) : Colors.transparent,
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(
//             icon,
//             color: isActive ? const Color(0xFF0F75F4) : const Color(0xFFADB5BD),
//             size: 26,
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             fontFamily: 'Inter',
//             fontSize: 10,
//             fontWeight: FontWeight.w700,
//             letterSpacing: 1.0,
//             color: isActive ? const Color(0xFF0F75F4) : const Color(0xFFADB5BD),
//           ),
//         ),
//       ],
//     );
//   }ư
// }

import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';

// Gọi hàm này khi app start
void checkAndCreateDatabase() async {
  try {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'frontend.db'); // đặt tên phù hợp

    // Tạo database ngay lập tức
    Database db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print('✅ Database vừa được tạo!');
        // Tạo bảng mẫu để test
        await db.execute('''
          CREATE TABLE test_table (
            id INTEGER PRIMARY KEY,
            name TEXT
          )
        ''');
      },
    );

    print('✅ Database path: $path');
    await db.close();
  } catch (e) {
    print('❌ Lỗi: $e');
  }
}

void main() {
  runApp(const MyApp());
}
