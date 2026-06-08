import 'package:flutter/material.dart';
import 'package:frontend/data/database_helper.dart';
import 'package:frontend/data/controller/water_controller.dart';
import 'package:frontend/services/sound_service.dart';
import 'package:frontend/services/notification_service.dart';

class AlarmReminderCard extends StatefulWidget {
  final int userId;
  final String type; // 'vitals', 'activity', 'sleep', 'nutrition', 'water'
  final VoidCallback? onSaved;

  const AlarmReminderCard({
    super.key,
    required this.userId,
    required this.type,
    this.onSaved,
  });

  @override
  State<AlarmReminderCard> createState() => _AlarmReminderCardState();
}

class _AlarmReminderCardState extends State<AlarmReminderCard> {
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    try {
      final setting = await DatabaseHelper().getReminder(
        widget.userId,
        widget.type,
      );
      if (mounted) {
        if (setting != null) {
          final String timeStr = setting['time'] ?? '08:00';
          final parts = timeStr.split(':');
          int hour = 8;
          int minute = 0;
          if (parts.length == 2) {
            hour = int.tryParse(parts[0]) ?? 8;
            minute = int.tryParse(parts[1]) ?? 0;
          }
          setState(() {
            _isEnabled = (setting['is_enabled'] ?? 1) == 1;
            _selectedTime = TimeOfDay(hour: hour, minute: minute);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('[AlarmReminderCard] _loadSetting lỗi: $e');
    }
  }

  Future<void> _saveSetting() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Đảm bảo NotificationService đã được khởi tạo
      await NotificationService().init();

      final String timeStr =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      // Gọi controller để lưu cài đặt & lên lịch thông báo
      await WaterController().saveReminderSetting(
        userId: widget.userId,
        type: widget.type,
        time: timeStr,
        isEnabled: _isEnabled,
      );

      // Phát âm thanh báo thành công tương tự như baikt
      await SoundService.playSuccess();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnabled
                  ? '🔔 Đã đặt nhắc nhở lúc $timeStr hàng ngày.'
                  : '🔕 Đã tắt nhắc nhở.',
            ),
            backgroundColor: _isEnabled ? Colors.green : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        if (widget.onSaved != null) widget.onSaved!();
      }
    } catch (e) {
      print('[AlarmReminderCard] _saveSetting lỗi: $e');
      // Hoàn tác state nếu lưu thất bại
      if (mounted) {
        setState(() => _isEnabled = !_isEnabled);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể lưu cài đặt nhắc nhở: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: const Color(0xFFEBECEE), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.alarm,
                      color: Color(0xFF0F75F4),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhắc nhở hàng ngày',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF111111),
                        ),
                      ),
                      Text(
                        'Thông báo đẩy nhắc ghi chép',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Hiển thị loading khi đang lưu, ngược lại hiện Switch
              _isSaving
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Switch.adaptive(
                      value: _isEnabled,
                      activeTrackColor: const Color(0xFF0F75F4),
                      onChanged: (val) {
                        setState(() => _isEnabled = val);
                        _saveSetting();
                      },
                    ),
            ],
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFEBECEE)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF6C757D),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thời gian nhận thông báo:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null && picked != _selectedTime) {
                            setState(() => _selectedTime = picked);
                            await _saveSetting();
                          }
                        },
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F75F4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
