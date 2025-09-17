@echo off
setlocal EnableExtensions

REM ===== Config usuario =====
set "GITUSER=erickson558"
set "GITEMAIL=erickson558@hotmail.com"

REM ===== Verificaciones =====
where git >nul 2>&1
if %ERRORLEVEL% NEQ 0 echo [ERROR] Git no esta en PATH. & exit /b 1
where gh >nul 2>&1
if %ERRORLEVEL% NEQ 0 echo [ERROR] GitHub CLI (gh) no esta en PATH. & exit /b 1

REM ===== Nombre del repo segun carpeta =====
for %%I in (.) do set "REPO=%%~nI"
if "%REPO%"=="" echo [ERROR] No se pudo detectar el nombre de la carpeta. & exit /b 1
echo [INFO] Repo: %REPO%

REM ===== Mensaje de commit =====
set "COMMITMSG=%~1"
if "%COMMITMSG%"=="" (
  set /p COMMITMSG=Mensaje de commit (enter = 'Actualizacion automatica'): 
  if "%COMMITMSG%"=="" set "COMMITMSG=Actualizacion automatica"
)

REM ===== Limpiar lock si quedo =====
if exist ".git\index.lock" del /f /q ".git\index.lock" >nul 2>&1

REM ===== Detectar si ya es repo git =====
git rev-parse --is-inside-work-tree >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :INIT
goto :UPDATE

:INIT
echo [STEP] Inicializando repo...
git init
if %ERRORLEVEL% NEQ 0 echo [ERROR] git init fallo. & exit /b 1

echo [STEP] Configurando git (local)...
git config user.name "%GITUSER%"
git config user.email "%GITEMAIL%"
git config core.autocrlf true
git config core.filemode false
git config core.longpaths true

echo [STEP] Forzando rama main...
git checkout -q -b main 2>nul
if %ERRORLEVEL% NEQ 0 git branch -M main

if not exist "README.md" (
  >README.md echo # %REPO%
  >>README.md echo Proyecto %REPO% subido automaticamente.
)

echo [STEP] Primer commit...
git add -A
git commit -m "Primer commit" >nul 2>&1

echo [STEP] Verificando repo remoto en GitHub...
gh repo view "%GITUSER%/%REPO%" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo [STEP] Creando repo publico %REPO%...
  gh repo create "%REPO%" --public >nul 2>&1
  if %ERRORLEVEL% NEQ 0 echo [ERROR] No se pudo crear el repo remoto. Revisa 'gh auth status'. & exit /b 1
) else (
  echo [INFO] El repo remoto ya existe.
)

REM ===== Configurar origin =====
git remote get-url origin >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  git remote add origin "https://github.com/%GITUSER%/%REPO%.git"
) else (
  for /f "delims=" %%U in ('git remote get-url origin 2^>nul') do set "ORIGINURL=%%U"
  if /I not "%ORIGINURL%"=="https://github.com/%GITUSER%/%REPO%.git" git remote set-url origin "https://github.com/%GITUSER%/%REPO%.git"
)

echo [STEP] Push inicial a main...
git push -u origin main
if %ERRORLEVEL% NEQ 0 echo [ERROR] Fallo el push inicial. & exit /b 1

echo [STEP] Commit con tu mensaje (si hay cambios)...
git add -A
git diff --cached --quiet
if %ERRORLEVEL% NEQ 0 (
  git commit -m "%COMMITMSG%"
  git push
) else (
  echo [INFO] No hay cambios adicionales.
)

echo [DONE] Listo: https://github.com/%GITUSER%/%REPO%
exit /b 0

:UPDATE
echo [INFO] Repo ya inicializado. Asegurando rama main y remoto...

for /f "delims=" %%B in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set "BRANCH=%%B"
if /I not "%BRANCH%"=="main" git branch -M main

git remote get-url origin >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  git remote add origin "https://github.com/%GITUSER%/%REPO%.git"
) else (
  for /f "delims=" %%U in ('git remote get-url origin 2^>nul') do set "ORIGINURL=%%U"
  if /I not "%ORIGINURL%"=="https://github.com/%GITUSER%/%REPO%.git" git remote set-url origin "https://github.com/%GITUSER%/%REPO%.git"
)

echo [STEP] Preparando cambios...
git add -A
git diff --cached --quiet
if %ERRORLEVEL% NEQ 0 (
  echo [STEP] Commit: %COMMITMSG%
  git commit -m "%COMMITMSG%"
) else (
  echo [INFO] No hay cambios para commitear.
)

echo [STEP] Push a origin/main...
git push -u origin main

echo [DONE] OK: https://github.com/%GITUSER%/%REPO%
exit /b 0
