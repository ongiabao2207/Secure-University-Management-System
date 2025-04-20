using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using Oracle.ManagedDataAccess.Client;
using WindowsFormsApp.Data; // nếu UserSession đặt trong folder Data

namespace WindowsFormsApp.Forms
{
    public partial class NotificationForm : Form
    {
        Label lblTitle;
        DataGridView dgvThongBao;
        TextBox txtChiTiet;
        Button btnReload;

        public NotificationForm()
        {
            InitUI();
            LoadThongBao();
        }

        private void InitUI()
        {
            this.Text = "Thông báo nội bộ";
            this.Size = new Size(800, 500);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.White;

            lblTitle = new Label()
            {
                Text = "📢 DANH SÁCH THÔNG BÁO",
                Font = new Font("Segoe UI", 16, FontStyle.Bold),
                AutoSize = true,
                Location = new Point((this.ClientSize.Width - 300) / 2, 20)
            };
            this.Controls.Add(lblTitle);

            dgvThongBao = new DataGridView()
            {
                Location = new Point(50, 70),
                Size = new Size(680, 200),
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect
            };
            dgvThongBao.SelectionChanged += DgvThongBao_SelectionChanged;
            this.Controls.Add(dgvThongBao);

            txtChiTiet = new TextBox()
            {
                Location = new Point(50, 280),
                Size = new Size(680, 120),
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Vertical
            };
            this.Controls.Add(txtChiTiet);

            btnReload = new Button()
            {
                Text = "🔄 Làm mới",
                Location = new Point(600, 410),
                Size = new Size(130, 30)
            };
            btnReload.Click += (s, e) => LoadThongBao();
            this.Controls.Add(btnReload);
        }

        private void LoadThongBao()
        {
            try
            {
                using (OracleConnection conn = DbConnectionHelper.GetConnection(UserSession.Username, UserSession.Password))
                {
                    conn.Open();
                    OracleCommand cmd = new OracleCommand("SELECT ROWID, NOIDUNG FROM THONGBAO", conn);
                    OracleDataAdapter adapter = new OracleDataAdapter(cmd);
                    DataTable dt = new DataTable();
                    adapter.Fill(dt);

                    dgvThongBao.DataSource = dt;
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi tải thông báo: " + ex.Message);
            }
        }

        private void DgvThongBao_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvThongBao.CurrentRow != null)
            {
                txtChiTiet.Text = dgvThongBao.CurrentRow.Cells["NOIDUNG"].Value.ToString();
            }
        }
    }
}
