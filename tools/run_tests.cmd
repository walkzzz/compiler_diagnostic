@echo off
REM =============================================================================
REM compiler-diagnostic · 按子包逐个运行测试（Windows CMD 版）
REM 用法：
REM   run_tests.cmd ut       （仅单元测试）
REM   run_tests.cmd hlt      （仅高层测试）
REM   run_tests.cmd llt      （仅端到端测试）
REM   run_tests.cmd all      （依次 ut -> hlt -> llt，默认）
REM 依赖：cjpm (Cangjie 1.1.3)；需 CANGJIE_HOME 指向 vendored SDK。
REM =============================================================================
setlocal
cd /d %~dp0\..

if "%CANGJIE_HOME%"=="" set "CANGJIE_HOME=D:\CodeWorkspace\compiler-diagnostic\cangjie-sdk-1.1.3\cangjie"
set "PATH=%CANGJIE_HOME%\bin;%CANGJIE_HOME%\tools\bin;%CANGJIE_HOME%\tools\lib;%CANGJIE_HOME%\runtime\lib\windows_x86_64_cjnative;%PATH%"

set "PKG=%1"
if "%PKG%"=="" set "PKG=all"

if "%PKG%"=="ut"  goto :ut
if "%PKG%"=="hlt" goto :hlt
if "%PKG%"=="llt" goto :llt
if "%PKG%"=="all" goto :all
echo unknown pkg: %PKG%  (可选: ut ^| hlt ^| llt ^| all)
exit /b 1

:ut
echo ===== cjpm test ut =====
cjpm test ut
goto :eof

:hlt
echo ===== cjpm test hlt =====
cjpm test hlt
goto :eof

:llt
echo ===== cjpm test llt =====
cjpm test llt
goto :eof

:all
echo ===== cjpm test ut =====
cjpm test ut
if errorlevel 1 exit /b 1
echo ===== cjpm test hlt =====
cjpm test hlt
if errorlevel 1 exit /b 1
echo ===== cjpm test llt =====
cjpm test llt
goto :eof
