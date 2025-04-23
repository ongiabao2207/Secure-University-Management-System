using System;
using System.Drawing;
using System.Windows.Forms;
using Oracle.ManagedDataAccess.Client;
using WindowsFormsApp.Data;

namespace WindowsFormsApp.Forms
{
    public partial class LoginForm : Form
    {
        Label lblTitle, lblUser, lblPass;
        TextBox txtUsername, txtPassword;
        Button btnLogin, btnClose;

        public LoginForm()
        {
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
            lblTitle.Location = new Point((this.ClientSize.Width - lblTitle.PreferredWidth) / 2, 50);
            this.Controls.Add(lblTitle);

            lblUser = new Label() { Text = "TÊN ĐĂNG NHẬP", Location = new Point(200, 150), AutoSize = true };
            txtUsername = new TextBox() { Location = new Point(350, 145), Width = 200 };
            this.Controls.Add(lblUser);
            this.Controls.Add(txtUsername);

            lblPass = new Label() { Text = "MẬT KHẨU", Location = new Point(200, 200), AutoSize = true };
            txtPassword = new TextBox() { Location = new Point(350, 195), Width = 200, UseSystemPasswordChar = true };
            this.Controls.Add(lblPass);
            this.Controls.Add(txtPassword);

            btnLogin = new Button() { Text = "ĐĂNG NHẬP", Location = new Point(350, 250), Width = 100 };
            btnLogin.Click += BtnLogin_Click;
            this.Controls.Add(btnLogin);

            btnClose = new Button() { Text = "Close", Location = new Point(700, 420), Width = 60 };
            btnClose.Click += (s, e) => Application.Exit();
            this.Controls.Add(btnClose);
        }

        private void BtnLogin_Click(object sender, EventArgs e)
        {
            string user = txtUsername.Text.Trim();
            string pass = txtPassword.Text.Trim();

            if (user == "" || pass == "")
            {
                MessageBox.Show("Vui lòng nhập đầy đủ thông tin.");
                return;
            }

            try
            {
                using (var conn = DbConnectionHelper.GetConnection(user, pass))
                {
                    conn.Open();

                    // Kiểm tra trong bảng NHANVIEN
                    string sqlNv = "SELECT HOTEN, VAITRO FROM QLDH.NHANVIEN WHERE MANV = :manv";
                    using (var cmdNv = new OracleCommand(sqlNv, conn))
                    {
                        cmdNv.Parameters.Add("manv", user);
                        using (var readerNv = cmdNv.ExecuteReader())
                        {
                            if (readerNv.Read())
                            {
                                string hoten = readerNv.GetString(0);
                                string vaitro = readerNv.GetString(1);

                                UserSession.Username = user;
                                UserSession.Password = pass;
                                UserSession.Hoten = hoten;
                                UserSession.Role = vaitro;

                                Form nextForm = null;
                                switch (vaitro)
                                {
                                    case "TRGDV": nextForm = new TrgdvForm(); break;
                                    case "GV": nextForm = new GvForm(); break;
                                    case "NV PDT": nextForm = new NvPdtForm(); break;
                                    case "NV PKT": nextForm = new NvPktForm(); break;
                                    case "NV TCHC": nextForm = new NvTchcForm(); break;
                                    case "NV CTSV": nextForm = new NvCtsvForm(); break;
                                    case "NVCB": nextForm = new NvCbForm(); break;
                                    default:
                                        MessageBox.Show("Vai trò chưa được hỗ trợ: " + vaitro);
                                        return;
                                }

                                nextForm.Show();
                                this.Hide();
                                return;
                            }
                        }
                    }

                    // Nếu không phải nhân viên, kiểm tra bảng SINHVIEN
                    string sqlSv = "SELECT HOTEN FROM QLDH.SINHVIEN WHERE MASV = :masv";
                    using (var cmdSv = new OracleCommand(sqlSv, conn))
                    {
                        cmdSv.Parameters.Add("masv", user);
                        using (var readerSv = cmdSv.ExecuteReader())
                        {
                            if (readerSv.Read())
                            {
                                string hoten = readerSv.GetString(0);

                                UserSession.Username = user;
                                UserSession.Password = pass;
                                UserSession.Hoten = hoten;
                                UserSession.Role = "SINHVIEN";

                                var studentForm = new StudentForm();
                                studentForm.Show();
                                this.Hide();
                                return;
                            }
                        }
                    }

                    MessageBox.Show("Không tìm thấy người dùng.");
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Đăng nhập thất bại: " + ex.Message);
            }
        }
    }
}
