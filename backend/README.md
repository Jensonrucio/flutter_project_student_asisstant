# XAMPP Authentication API

The Flutter app uses the existing XAMPP API at `/student_api`. The auth endpoint is `auth.php`; task and quiz-log endpoints require its bearer token and only return rows owned by the signed-in user.

## Local Setup

The live API files are installed in `C:\xampp\htdocs\student_api`. They use the existing `db.php` connection; keep database credentials there and do not commit them. The CLI-only `setup_auth.php` has been run against the configured database. In phpMyAdmin, select `stundent_todo_db` and confirm these tables exist:

- `auth_users`
- `auth_tokens`
- `auth_login_attempts`
- `auth_password_reset_requests`
- `auth_password_reset_tokens`
- `tasks`
- `quiz_logs`

To repeat setup after restoring the API folder, run:

```powershell
C:\xampp\php\php.exe C:\xampp\htdocs\student_api\setup_auth.php
```

The setup script creates missing tables and adds `user_id` columns when needed. Existing unowned tasks and quiz logs are assigned to the first account registered after setup. The setup endpoint returns 404 over HTTP and should only be run from the CLI.

## Password recovery

Install backend dependencies from the `backend` directory and run the idempotent schema setup:

```powershell
Set-Location backend\student_api
composer install --no-dev --prefer-dist
C:\xampp\php\php.exe setup_auth.php
```

Configure these variables for Apache before restarting Apache. For XAMPP, they can be set with `SetEnv` directives in Apache configuration; do not commit real values:

```apache
SetEnv SMTP_HOST smtp.gmail.com
SetEnv SMTP_PORT 587
SetEnv SMTP_ENCRYPTION tls
SetEnv SMTP_USERNAME your-sender@gmail.com
SetEnv SMTP_PASSWORD your-google-app-password
SetEnv SMTP_FROM_EMAIL your-sender@gmail.com
SetEnv SMTP_FROM_NAME "Student Assistant"
SetEnv APP_PUBLIC_API_URL http://localhost/student_api
```

Use an SMTP app password/API credential, not your normal mailbox password. For a reset link opened on a physical phone, set `APP_PUBLIC_API_URL` to an address that phone can reach (prefer an HTTPS hostname; a local Wi-Fi address works only on the same network). The base URL must point to the `/student_api` directory.

Reset links expire after 60 minutes, are stored as hashes, and can be used once. Password reset requests are rate-limited, return a generic response to avoid revealing whether an email is registered, and revoke existing sessions after the password changes. The reset form enforces the same 12–72 byte password limit as registration.

## Study Buddy notes quiz

Study Buddy lets a signed-in student upload a PDF, TXT, or DOCX file (or paste notes), extracts text on the device, and sends those notes to the authenticated `generate_quiz.php` endpoint. Uploaded notes are not stored by the app; they are sent to Gemini `gemini-3.8-flash` only after the student requests quiz generation. Students can choose 5, 10, 15, or 20 questions. The server prompt restricts questions to the supplied notes, and the app reveals the score and correct answers after all selected questions are answered. The app uses Gemini only; there is no alternate AI provider. PDF extraction requires selectable text; scanned image PDFs are not OCR'd.

Copy `backend\student_api\generate_quiz.php` into `C:\xampp\htdocs\student_api\generate_quiz.php` when updating an existing XAMPP installation.

The Gemini key must stay on the server, not in Flutter, source code, or a checked-in config file. Revoke any key shared in chat or source control, create a replacement in Google AI Studio, and restrict it to the Gemini API. For XAMPP, create `C:\xampp\apache\conf\student-assistant-secrets.ini` (outside the public `htdocs` directory) with:

```ini
GEMINI_API_KEY = "paste-your-new-api-key-here"
```

Replace the placeholder locally with a newly created key. If a key was ever added to a README, source control, chat, or another shared location, revoke it and create a replacement before testing. Do not paste the key into chat, commit the file, or put it under `htdocs`. The endpoint reads this file on each request, so Apache does not need to be restarted. Alternatively, set `GEMINI_API_KEY` in Apache with `SetEnv`; this takes precedence. On a non-XAMPP host, set `STUDENT_ASSISTANT_SECRETS_FILE` to the absolute path of an equivalently protected INI file if Apache environment variables are unavailable.

The endpoint requires a signed-in user, accepts up to 12,000 characters of notes and 1–20 requested questions, and rejects responses whose question count differs from the request or that do not contain four-option questions. If the key is missing, the endpoint returns a configuration error; it never calls another provider.

If quiz generation fails, the app distinguishes Gemini quota limits, invalid credentials, missing model access, blocked notes, temporary service outages, and responses that hit Gemini's output limit. For other upstream failures, check the Apache/PHP error log for the Gemini HTTP status; logs do not include the API key or study notes.

Start Apache and MySQL in XAMPP, then launch Flutter from the project root. Default API URLs are `http://localhost/student_api` on web, `http://10.0.2.2/student_api` on Android emulators, and `http://127.0.0.1/student_api` on desktop.

To override the URL, copy `config/api.example.json` to `config/api.local.json`, edit `API_BASE_URL`, and run Flutter from the project root:

```powershell
Copy-Item config/api.example.json config/api.local.json
flutter run --dart-define-from-file=config/api.local.json
```

For a physical phone, use the computer's Wi-Fi/LAN IPv4 address in the URL (for example, `http://192.168.0.108/student_api`), not `localhost` or `10.0.2.2`. Keep the phone and computer on the same network, allow Apache through Windows Defender Firewall on a private network, and ensure Apache accepts connections on the LAN interface. The computer's LAN address may change when it reconnects to Wi-Fi.

When `APP_ALLOWED_ORIGINS` is unset, the API accepts HTTP/HTTPS browser origins on `localhost` or `127.0.0.1` for Flutter Web development, including dynamically selected ports. Set `APP_ALLOWED_ORIGINS` in Apache to an exact comma-separated production allowlist; when set, it disables this local-development rule. Do not use `*`.

Use **Create an account** on the login screen for the first user. Passwords are hashed with PHP `password_hash`; bearer tokens are random, expire after 24 hours, and only their SHA-256 hashes are stored. The Flutter token remains in memory, so restarting the app requires signing in again. Logs never include passwords, tokens, or email addresses.

For production, serve the API over HTTPS, restrict the CORS allowlist to the deployed app origin, and configure a non-root MySQL user with only the required database permissions.