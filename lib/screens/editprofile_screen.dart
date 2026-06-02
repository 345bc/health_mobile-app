import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/data/models/user.dart';
import 'package:frontend/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/data/controller/user_controller.dart';
import 'package:frontend/services/user-service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:frontend/services/notification_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String? _gender;
  String? _bloodType;
  String? _avatarUrl;
  bool _isLoading = false;

  final List<String> _genders = ['MALE', 'FEMALE'];
  final List<String> _bloodTypes = [
    'O+',
    'O-',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final User? user = userProvider.getUser();

    _nameController = TextEditingController(text: user?.user_name ?? '');
    _dobController = TextEditingController(text: user?.dateOfBirth ?? '');
    _heightController = TextEditingController(
      text: user?.height != null ? user!.height.toString() : '',
    );
    _weightController = TextEditingController(
      text: user?.weight != null ? user!.weight.toString() : '',
    );

    _gender = user?.gender;
    if (_gender == null || !_genders.contains(_gender)) {
      _gender = 'MALE';
    }

    _bloodType = user?.bloodType;
    if (_bloodType == null || !_bloodTypes.contains(_bloodType)) {
      _bloodType = 'O+';
    }

    _avatarUrl = user?.avatar;
  }

  ImageProvider _buildAvatarImage(String? path) {
    if (path == null || path.isEmpty) {
      return const AssetImage('assets/images/profile-image.jpg');
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return FileImage(File(path));
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
        final String savedPath = p.join(directory.path, fileName);

        await File(image.path).copy(savedPath);

        setState(() {
          _avatarUrl = savedPath;
        });
      }
    } catch (e) {
      print("Lỗi khi chọn/chụp ảnh: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Không thể chọn hoặc chụp ảnh: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 25),
    );
    if (_dobController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dobController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F75F4),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111111),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _showAvatarPicker() {
    final TextEditingController urlController = TextEditingController(
      text: _avatarUrl,
    );
    final List<String> presets = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&h=150&fit=crop',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&h=150&fit=crop',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&h=150&fit=crop',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop',
      'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&h=150&fit=crop',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn ảnh đại diện',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111111),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF6C757D)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7F1FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Color(0xFF0F75F4),
                              size: 28,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Chụp ảnh',
                              style: TextStyle(
                                color: Color(0xFF0F75F4),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: Color(0xFF6C757D),
                              size: 28,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Thư viện',
                              style: TextStyle(
                                color: Color(0xFF6C757D),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEBECEE), height: 1),
              const SizedBox(height: 20),
              const Text(
                'Hoặc chọn ảnh mẫu có sẵn:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C757D),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: presets.length,
                itemBuilder: (context, index) {
                  final presetUrl = presets[index];
                  final isSelected = _avatarUrl == presetUrl;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _avatarUrl = presetUrl;
                        urlController.text = presetUrl;
                      });
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF0F75F4)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(presetUrl),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Hoặc nhập liên kết ảnh tùy chọn (URL):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6C757D),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: 'https://example.com/image.png',
                  hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                  filled: true,
                  fillColor: const Color(0xFFF4F6FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF0F75F4)),
                    onPressed: () {
                      if (urlController.text.trim().isNotEmpty) {
                        setState(() {
                          _avatarUrl = urlController.text.trim();
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                onChanged: (val) {
                  setModalState(() {
                    _avatarUrl = val.trim();
                  });
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Hoàn tất',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final User? currentUser = userProvider.getUser();

      if (currentUser != null) {
        setState(() {
          _isLoading = true;
        });

        final updatedUser = currentUser.copyWith(
          user_name: _nameController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          gender: _gender,
          height: double.tryParse(_heightController.text),
          weight: double.tryParse(_weightController.text),
          bloodType: _bloodType,
          avatar: _avatarUrl,
        );

        bool isSavedOnServer = false;
        bool isOffline = false;
        String errorMessage = "Đã xảy ra lỗi khi lưu hồ sơ.";

        try {
          final ApiService apiService = ApiService();
          final UserService userService = UserService(apiService);

          if (updatedUser.userId != null) {
            // Construct a clean patch payload matching EndUsersPatchRequest DTO
            final Map<String, dynamic> patchData = {
              'fullName': updatedUser.endUser!.name,
              'birthDate': updatedUser.endUser!.dateOfBirth,
              'gender': updatedUser.endUser!.gender,
              'height': updatedUser.endUser!.height,
              'weight': updatedUser.endUser!.weight,
              'bloodType': updatedUser.endUser!.bloodType,
              'avatar': updatedUser.endUser!.avatar,
            };

            final response = await userService.updateEndUserProfile(
              updatedUser.userId!,
              patchData,
            );

            if (response != null) {
              if (response.statusCode == 200 || response.statusCode == 201) {
                isSavedOnServer = true;
              } else {
                isSavedOnServer = false;
                final responseData = response.data;
                if (responseData is Map<String, dynamic> &&
                    responseData.containsKey('message')) {
                  errorMessage = responseData['message'];
                } else {
                  errorMessage = "Lỗi máy chủ (${response.statusCode})";
                }
              }
            } else {
              isOffline = true;
            }
          }
        } catch (e) {
          print("Lỗi khi cập nhật lên server: $e");
          isOffline = true;
        }

        if (isSavedOnServer || isOffline) {
          // 2. Update in SQLite Database
          final UserController userController = UserController();
          await userController.updateUser(updatedUser);

          // 3. Update in state Provider
          userProvider.setUser(updatedUser);

          setState(() {
            _isLoading = false;
          });

          if (isSavedOnServer) {
            NotificationService().showNotification(
              id: 1,
              title: "Cập nhật thành công",
              body: "Thông tin hồ sơ của bạn đã được lưu lại thành công.",
            );
          } else {
            NotificationService().showNotification(
              id: 2,
              title: "Lưu tạm thời (Offline)",
              body: "Đã lưu hồ sơ cục bộ. Không thể kết nối tới máy chủ.",
            );
          }

          if (!mounted) return;
          Navigator.pop(context);
        } else {
          setState(() {
            _isLoading = false;
          });
          NotificationService().showNotification(
            id: 3,
            title: "Cập nhật thất bại",
            body: errorMessage,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar edit
              Center(
                child: GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF0F75F4,
                            ).withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundImage: _buildAvatarImage(_avatarUrl),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F75F4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Full Name field
              _buildSectionTitle('THÔNG TIN CHUNG'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Họ và tên',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth field
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _dobController,
                    label: 'Ngày sinh',
                    icon: Icons.cake_outlined,
                    hint: 'YYYY-MM-DD',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('CHỈ SỐ SỨC KHỎE'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _heightController,
                      label: 'Chiều cao (cm)',
                      icon: Icons.height,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Số không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'Cân nặng (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Số không hợp lệ';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender and Blood Type Dropdowns
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Giới tính',
                      value: _gender,
                      items: _genders,
                      icon: Icons.wc_outlined,
                      onChanged: (val) => setState(() => _gender = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Nhóm máu',
                      value: _bloodType,
                      items: _bloodTypes,
                      icon: Icons.bloodtype_outlined,
                      onChanged: (val) => setState(() => _bloodType = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F75F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6C757D),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111111),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFADB5BD),
          fontWeight: FontWeight.normal,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF6C757D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6C757D), size: 22),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F75F4), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF6C757D),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF6C757D), size: 22),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0F75F4), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C757D)),
      dropdownColor: Colors.white,
    );
  }
}
