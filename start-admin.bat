@echo off
rem Admin panel with hot reload (Vite dev server on port 5173)
rem For daily use just open http://<your-ip>:8080/admin-ui/ instead - no node needed.
cd /d "%~dp0admin"
echo Starting admin dev server ...
start "Bounty Admin Dev (5173)" cmd /k "npm run dev"
