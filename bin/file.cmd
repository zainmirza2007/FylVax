@echo off
if "%1"=="-b" if "%2"=="--mime-type" (echo application/octet-stream & exit /b 0)
echo application/octet-stream
