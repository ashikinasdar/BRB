# BRB — HIMSAK App

This mobile app helps Kelantanese students access financial aid, announcements, and discounts in one place. It simplifies support, shares updates, and offers savings through a trusted, verified system.

---

## ⚙️ Quick Setup (For Team Members)

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [XAMPP](https://www.apachefriends.org/) installed at `C:\xampp\`

### Steps
1. Clone the repo and open a terminal in the project folder
2. **Start XAMPP** — make sure Apache and MySQL are both running
3. **Double-click `setup.bat`** — it will automatically:
   - Copy the API files to `C:\xampp\htdocs\himsak_api\`
   - Create the `himsak_db` database and run the SQL
   - Create the default admin account
   - Run `flutter pub get`
4. Run the app:
   ```bash
   flutter run
   ```

### Default Admin Login
| Field    | Value               |
|----------|---------------------|
| Email    | admin@himsak.com    |
| Password | admin123            |

> ⚠️ **Android Emulator users:** Change `localhost` to `10.0.2.2` in:
> - `lib/providers/auth_provider.dart`
> - `lib/screens/admin_dashboard_screen.dart`
