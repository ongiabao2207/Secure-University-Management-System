using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using Oracle.ManagedDataAccess.Client;
using WindowsFormsApp.Data;

namespace WindowsFormsApp.Forms
{
    public class NotificationForm : Form
    {
        Label lblTitle;
        DataGridView dgvThongBao;
        TextBox txtChiTiet;
        Button btnXem, btnReload;

        public NotificationForm()
        {
            InitUI();
            LoadThongBao();
        }

        private void InitUI()
        {
            this.Text = "Thông báo nội bộ";
            this.Size = new Size(850, 550);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.White;

            lblTitle = new Label()
            {
                Text = "📢 DANH SÁCH THÔNG BÁO",
                Font = new Font("Segoe UI", 16, FontStyle.Bold),
                AutoSize = true,
                Location = new Point((this.ClientSize.Width - 350) / 2, 20)
            };
            this.Controls.Add(lblTitle);

            dgvThongBao = new DataGridView()
            {
                Location = new Point(50, 70),
                Size = new Size(730, 250),
                ReadOnly = true,
                SelectionMode = DataGridViewSelectionMode.RowHeaderSelect,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill
            };

            dgvThongBao.DefaultCellStyle.SelectionBackColor = dgvThongBao.DefaultCellStyle.BackColor;
            dgvThongBao.DefaultCellStyle.SelectionForeColor = dgvThongBao.DefaultCellStyle.ForeColor;

            dgvThongBao.SelectionChanged += DgvThongBao_SelectionChanged;
            this.Controls.Add(dgvThongBao);

            txtChiTiet = new TextBox()
            {
                Location = new Point(50, 330),
                Size = new Size(730, 90),
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Vertical
            };
            this.Controls.Add(txtChiTiet);

            btnXem = new Button()
            {
                Text = "👁 Xem",
                Location = new Point(500, 440),
                Size = new Size(100, 30)
            };
            btnXem.Click += BtnXem_Click;
            this.Controls.Add(btnXem);

            btnReload = new Button()
            {
                Text = "🔄 Làm mới",
                Location = new Point(630, 440),
                Size = new Size(100, 30)
            };
            btnReload.Click += (s, e) => LoadThongBao();
            this.Controls.Add(btnReload);
        }

        private void LoadThongBao()
        {
            try
            {
                using (var conn = DbConnectionHelper.GetConnection(UserSession.Username, UserSession.Password))
                {
                    conn.Open();
                    var cmd = new OracleCommand("SELECT MATB, NOIDUNG, DIADIEM FROM ADMIN_OLS.THONGBAO", conn);
                    var adapter = new OracleDataAdapter(cmd);
                    var dt = new DataTable();
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
                string noidung = dgvThongBao.CurrentRow.Cells["NOIDUNG"].Value.ToString();
                string diadiem = dgvThongBao.CurrentRow.Cells["DIADIEM"].Value?.ToString();
                txtChiTiet.Text = noidung;
                if (!string.IsNullOrEmpty(diadiem))
                    txtChiTiet.Text += "\r\n📍 Địa điểm: " + diadiem;
            }
        }

        private void BtnXem_Click(object sender, EventArgs e)
        {
            if (dgvThongBao.CurrentRow == null)
            {
                MessageBox.Show("Vui lòng chọn một thông báo để xem.");
                return;
            }

            string matb = dgvThongBao.CurrentRow.Cells["MATB"].Value.ToString();
            string noidung = dgvThongBao.CurrentRow.Cells["NOIDUNG"].Value.ToString();
            string diadiem = dgvThongBao.CurrentRow.Cells["DIADIEM"].Value?.ToString() ?? "Không xác định";

            Form popup = new Form()
            {
                Text = $"Chi tiết thông báo #{matb}",
                Size = new Size(600, 400),
                StartPosition = FormStartPosition.CenterScreen,
                BackColor = Color.White
            };

            Label lblMatb = new Label()
            {
                Text = $"Mã TB: {matb}",
                Location = new Point(20, 20),
                Font = new Font("Segoe UI", 10),
                AutoSize = true
            };

            Label lblDiadiem = new Label()
            {
                Text = $"Địa điểm: {diadiem}",
                Location = new Point(20, 60),
                Font = new Font("Segoe UI", 10),
                AutoSize = true
            };

            TextBox txtNoidung = new TextBox()
            {
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Vertical,
                Location = new Point(20, 100),
                Size = new Size(540, 220),
                Font = new Font("Segoe UI", 10),
                WordWrap = true
            };

            txtNoidung.Text = noidung;
            txtNoidung.SelectionStart = 0;
            txtNoidung.SelectionLength = 0;
            popup.ActiveControl = null; // bỏ focus khỏi TextBox


            popup.Controls.Add(lblMatb);
            popup.Controls.Add(lblDiadiem);
            popup.Controls.Add(txtNoidung);

            popup.ShowDialog();
        }
    }
}
