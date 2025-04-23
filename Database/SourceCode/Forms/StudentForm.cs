using System;
using System.Drawing;
using System.Windows.Forms;
using WindowsFormsApp.Data;

namespace WindowsFormsApp.Forms
{
    public class StudentForm : Form
    {
        public StudentForm()
        {
            this.Text = "Trang Sinh viên";
            this.Size = new Size(600, 400);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.White;

            Label lbl = new Label()
            {
                Text = $"Xin chào {UserSession.Hoten} - Mã SV: {UserSession.Username}",
                Font = new Font("Segoe UI", 14),
                AutoSize = true,
                Location = new Point(50, 80)
            };
            this.Controls.Add(lbl);

            Button btnXemThongBao = new Button()
            {
                Text = "📢 Xem thông báo",
                Size = new Size(180, 40),
                Location = new Point(50, 140),
                BackColor = Color.LightSteelBlue
            };
            btnXemThongBao.Click += (s, e) =>
            {
                NotificationForm frm = new NotificationForm();
                frm.ShowDialog();
            };
            this.Controls.Add(btnXemThongBao);
        }
    }
}
