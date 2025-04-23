// CommonUserForm.cs
using System;
using System.Drawing;
using System.Windows.Forms;
using WindowsFormsApp.Data;

namespace WindowsFormsApp.Forms
{
    public static class CommonUserForm
    {
        public static void InitUI(this Form form, string title)
        {
            form.Text = title;
            form.Size = new Size(600, 400);
            form.StartPosition = FormStartPosition.CenterScreen;
            form.BackColor = Color.White;

            Label lbl = new Label()
            {
                Text = $"Xin chào {UserSession.Hoten} - Vai trò: {UserSession.Role}",
                Font = new Font("Segoe UI", 14),
                AutoSize = true,
                Location = new Point(50, 80)
            };
            form.Controls.Add(lbl);

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
            form.Controls.Add(btnXemThongBao);
        }
    }
}