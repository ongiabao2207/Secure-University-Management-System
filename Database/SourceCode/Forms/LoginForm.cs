using System;
using System.Drawing;
using System.Windows.Forms;
using Oracle.ManagedDataAccess.Client; // NHỚ: chỉ thêm dòng này nếu đã cài NuGet

namespace WindowsFormsApp
{
    public partial class LoginForm : Form
    {
        Label lblTitle, lblUsername, lblPassword, lblRole;
        TextBox txtUsername, txtPassword;
        ComboBox cbRole;
        Button btnLogin, btnClose;

        public LoginForm()
        {
            InitializeComponent();
            InitUI();
        }

        private void InitUI()
        {
            this.Text = "ĐĂNG NHẬP HỆ THỐNG";
            this.Size = new Size(800, 500);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.White;

            lblTitle = new Label()
            {
                Text = "HỆ THỐNG QUẢN LÝ DỮ LIỆU NỘI BỘ",
                Font = new Font("Segoe UI", 20, FontStyle.Bold),
                ForeColor = Color.SteelBlue,
                AutoSize = true
            };
            // Căn giữa ngang:
            lblTitle.Location = new Point((this.ClientSize.Width - lblTitle.PreferredWidth) / 2, 50);
            this.Controls.Add(lblTitle);

            lblUsername = new Label()
            {
                Text = "TÊN ĐĂNG NHẬP",
                Location = new Point(200, 130),
                AutoSize = true
            };
            this.Controls.Add(lblUsername);

            txtUsername = new TextBox()
            {
                Location = new Point(350, 125),
                Width = 200
            };
            this.Controls.Add(txtUsername);

            lblPassword = new Label()
            {
                Text = "MẬT KHẨU",
                Location = new Point(200, 180),
                AutoSize = true
            };
            this.Controls.Add(lblPassword);

            txtPassword = new TextBox()
            {
                Location = new Point(350, 175),
                Width = 200,
                UseSystemPasswordChar = true
            };
            this.Controls.Add(txtPassword);

            lblRole = new Label()
            {
                Text = "VAI TRÒ",
                Location = new Point(200, 230),
                AutoSize = true
            };
            this.Controls.Add(lblRole);

            cbRole = new ComboBox()
            {
                Location = new Point(350, 225),
                Width = 200,
                DropDownStyle = ComboBoxStyle.DropDownList
            };
            cbRole.Items.AddRange(new string[] {
                "Trưởng đơn vị",
                "Giảng viên",
                "Nhân viên Phòng Khảo thí",
                "Nhân viên Phòng Đào tạo",
                "Nhân viên Phòng Tổ chức Hành chính",
                "Sinh viên"
            });
            cbRole.SelectedIndex = 0;
            this.Controls.Add(cbRole);

            btnLogin = new Button()
            {
                Text = "ĐĂNG NHẬP",
                Location = new Point(350, 280),
                Width = 100
            };
            btnLogin.Click += BtnLogin_Click;
            this.Controls.Add(btnLogin);

            btnClose = new Button()
            {
                Text = "Close",
                Location = new Point(700, 420),
                Width = 60
            };
            btnClose.Click += (s, e) => Application.Exit();
            this.Controls.Add(btnClose);
        }

        private void BtnLogin_Click(object sender, EventArgs e)
        {
            string user = txtUsername.Text.Trim();
            string pass = txtPassword.Text.Trim();
            string role = cbRole.SelectedItem.ToString();

            if (user == "" || pass == "")
            {
                MessageBox.Show("Vui lòng nhập đầy đủ thông tin.");
                return;
            }

            try
            {
                string connStr = $"DATA SOURCE=localhost:1521/xe;USER ID={user};PASSWORD={pass};";
                using (OracleConnection conn = new OracleConnection(connStr))
                {
                    conn.Open();
                    MessageBox.Show("Đăng nhập thành công!");

                    // mở form khác nếu cần
                    // FormThongBao frm = new FormThongBao(user);
                    // frm.Show();
                    // this.Hide();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Đăng nhập thất bại: " + ex.Message);
            }
        }
    }
}
