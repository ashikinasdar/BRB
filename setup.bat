@echo off
echo ============================================
echo   HIMSAK App - Automated Setup Script
echo ============================================
echo.

REM --- Check if XAMPP is installed ---
IF NOT EXIST "C:\xampp\htdocs" (
    echo [ERROR] XAMPP not found at C:\xampp\
    echo Please install XAMPP from https://www.apachefriends.org/
    pause
    exit /b 1
)

REM --- Step 1: Copy API files to XAMPP htdocs ---
echo [1/3] Copying API files to XAMPP...
IF NOT EXIST "C:\xampp\htdocs\himsak_api" (
    mkdir "C:\xampp\htdocs\himsak_api"
)
xcopy /E /Y /I "api\*" "C:\xampp\htdocs\himsak_api\"
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to copy API files.
    pause
    exit /b 1
)
echo [OK] API files copied.
echo.

REM --- Create uploads directory ---
IF NOT EXIST "C:\xampp\htdocs\himsak_api\uploads" (
    mkdir "C:\xampp\htdocs\himsak_api\uploads"
    echo [OK] Uploads folder created.
)

REM --- Create CORS htaccess for uploads ---
echo ^<IfModule mod_headers.c^> > "C:\xampp\htdocs\himsak_api\uploads\.htaccess"
echo     Header set Access-Control-Allow-Origin "*" >> "C:\xampp\htdocs\himsak_api\uploads\.htaccess"
echo ^</IfModule^> >> "C:\xampp\htdocs\himsak_api\uploads\.htaccess"
echo.

REM --- Step 2: Import the database ---
echo [2/3] Setting up the database...
"C:\xampp\mysql\bin\mysql.exe" -u root -e "source api/database.sql" 2>nul
IF %ERRORLEVEL% NEQ 0 (
    echo [WARNING] Could not auto-import database. 
    echo Please manually import api\database.sql via:
    echo   http://localhost/phpmyadmin
    echo.
) ELSE (
    echo [OK] Database created and configured.
)
echo.

REM --- Step 3: Install Flutter dependencies ---
echo [3/3] Installing Flutter dependencies...
call flutter pub get
IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter pub get failed. Make sure Flutter is installed.
    pause
    exit /b 1
)
echo [OK] Flutter dependencies installed.
echo.

echo ============================================
echo   Setup Complete!
echo ============================================
echo.
echo Make sure XAMPP Apache and MySQL are running, then:
echo   flutter run
echo.
echo Default Admin Login:
echo   Email   : admin@himsak.com
echo   Password: admin123
echo.
pause
