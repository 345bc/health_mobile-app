# TÀI LIỆU USE CASE HỆ THỐNG - HEALTH TRACKER

Tài liệu này mô tả danh sách Use Case hệ thống đã được cập nhật sau khi thay thế chức năng Mục tiêu bằng theo dõi Nước uống, và gộp các hành vi Xem, Thêm mới, Sửa, Xóa của từng thực thể thành một Use Case quản lý duy nhất.

---

## I. DANH SÁCH ACTOR (TÁC NHÂN)
1. **User (Người dùng di động):** Người dùng sử dụng ứng dụng di động để theo dõi chỉ số sức khỏe cá nhân.
2. **Admin (Quản trị viên hệ thống):** Người sử dụng trang web quản trị để quản lý thông tin người dùng và nhật ký hệ thống.

---

## II. DANH SÁCH USE CASE CHI TIẾT

### 1. Phân hệ Mobile App (Dành cho Actor: User)

| Mã UC | Tên Use Case | Mô tả chi tiết |
| :--- | :--- | :--- |
| **UC-U01a** | **Đăng ký tài khoản** | Cho phép người dùng mới tạo tài khoản bằng email, mật khẩu và tên hiển thị để bắt đầu sử dụng ứng dụng. |
| **UC-U01b** | **Đăng nhập** | Cho phép người dùng xác thực thông tin tài khoản để truy cập các chức năng của ứng dụng (hỗ trợ chế độ ngoại tuyến). |
| **UC-U01c** | **Đăng xuất** | Cho phép người dùng kết thúc phiên làm việc hiện tại và xóa sạch thông tin phiên đăng nhập khỏi thiết bị. |
| **UC-U02** | **Quản lý Hồ sơ cá nhân** | Cho phép người dùng xem thông tin cá nhân và cập nhật (tên hiển thị, ngày sinh, giới tính, chiều cao, cân nặng mặc định, ảnh đại diện). |
| **UC-U03** | **Quản lý Sinh hiệu (Vitals)** | Gộp các thao tác ghi nhận mới, xem lịch sử ghi chép, xem biểu đồ xu hướng và xóa các bản ghi sinh hiệu: **Cân nặng, Huyết áp, Đường huyết, Nhịp tim**. |
| **UC-U04** | **Quản lý Hoạt động (Activity)** | Cho phép thêm mới số bước chân, quãng đường, tính toán calo tiêu thụ tự động, xem danh sách lịch sử 7 ngày gần nhất và cập nhật nhật ký vận động. |
| **UC-U05** | **Quản lý Giấc ngủ (Sleep)** | Ghi nhận thời gian bắt đầu ngủ, thức giấc, đánh giá chất lượng giấc ngủ và xem lịch sử thời lượng giấc ngủ của 7 ngày gần nhất. |
| **UC-U06** | **Quản lý Dinh dưỡng (Nutrition)** | Thêm bữa ăn (sáng, trưa, tối, phụ) với tên món ăn và calo/chất đạm/carbs/fat tương ứng, xem tổng calo nạp vào, xem danh sách món ăn và xóa nhật ký bữa ăn. |
| **UC-U07** | **Quản lý Uống nước (Water Intake)** | Thêm nhanh lượng nước uống hằng ngày (+250ml, +500ml hoặc nhập tự chọn), xem tiến trình đạt chỉ tiêu (2000ml), hiển thị lịch sử và xóa nhật ký uống nước. Dữ liệu tự động đồng bộ lên máy chủ. |
| **UC-U08** | **Quản lý Tâm trạng (Mood)** | Lưu trạng thái cảm xúc (điểm số 1-5), nhập ghi chú đi kèm và hiển thị chỉ số tâm trạng mới nhất tại trang chủ. |
| **UC-U09** | **Xem Phân tích Sức khỏe Tuần** | Xem so sánh các chỉ số sức khỏe (bước chân, giấc ngủ, calo tiêu hao/tiêu thụ, nhịp tim, cân nặng) giữa tuần này và tuần trước, đồng thời nhận lời khuyên sức khỏe tự động dựa trên chỉ số BMI. |
| **UC-U10** | **Thiết lập Nhắc nhở (Alarm)** | Cho phép người dùng bật/tắt nhắc nhở và tùy chỉnh thời gian nhận thông báo đẩy hàng ngày (báo thức) cho cả 5 màn hình theo dõi (**Sinh hiệu, Hoạt động, Giấc ngủ, Dinh dưỡng, Uống nước**). |

---

### 2. Phân hệ Web Admin (Dành cho Actor: Admin)

| Mã UC | Tên Use Case | Mô tả chi tiết |
| :--- | :--- | :--- |
| **UC-A01** | **Đăng nhập Quản trị** | Cho phép tài khoản Admin đăng nhập session-based vào trang Web Admin để thực hiện các chức năng quản lý. |
| **UC-A02** | **Quản lý Người dùng** | Cho phép Admin xem danh sách tất cả người dùng, chỉnh sửa thông tin tài khoản, cập nhật vai trò (USER/ADMIN), đổi mật khẩu người dùng hoặc xóa tài khoản. |
| **UC-A03** | **Xem Thống kê Dashboard** | Hiển thị tổng số lượng người dùng, hoạt động, giấc ngủ, dinh dưỡng, tâm trạng, nước uống; xem biểu đồ/danh sách người dùng mới nhất. |

---

## III. SỰ KHÁC BIỆT CHÍNH SO VỚI THIẾT KẾ CŨ
1. **Loại bỏ hoàn toàn Use Case "Quản lý mục tiêu":** Do tính năng đăng ký Goal đã được xóa bỏ ở cả hai phía Client và Server.
2. **Thêm mới Use Case "Quản lý Uống nước" (UC-U07):** Thay thế vai trò của Goal trong việc theo dõi thói quen hằng ngày (bỏ qua quản lý nước uống thủ công phía Admin).
3. **Thêm mới tính năng Báo thức trong thiết lập nhắc nhở (UC-U10):** Cho phép đặt lịch nhắc nhở hằng ngày cục bộ tại 5 màn hình riêng biệt.
4. **Tự động hóa Calo & Lời khuyên dựa trên BMI:** Thay vì so sánh với Mục tiêu (Goal) đã đặt, hệ thống sẽ tự động tính toán BMI từ thông tin chiều cao/cân nặng hồ sơ cá nhân để xuất lời khuyên tuần phù hợp.
