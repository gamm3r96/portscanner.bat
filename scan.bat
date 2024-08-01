@echo off
setlocal enabledelayedexpansion

:: Display Bio Information
echo =================================================
echo        Port Scanner Script by Gamm3r96
echo =================================================

:: Log Bio Information
set "logfile=%~dp0portscan_log.txt"
(
    echo =================================================
    echo        Port Scanner Script by Gamm3r96
    echo =================================================
) >> "%logfile%"

:: Function to print usage
:usage
echo.
echo Usage: %0 [options]
echo.
echo Options:
echo   -i <IP_ADDRESS>    Specify the IP address to scan.
echo   -s <START_PORT>    Specify the starting port number (default: 1).
echo   -e <END_PORT>      Specify the ending port number (default: 1024).
echo   -h                 Display this help message.
echo   -l                 List all available commands and options.
echo.
echo Example:
echo   %0 -i 192.168.1.1 -s 20 -e 80
echo.
exit /b

:: Function to list commands
:list_commands
echo.
echo Available Commands:
echo   -i <IP_ADDRESS>    Specify the IP address to scan. This option is required.
echo   -s <START_PORT>    Specify the starting port number. Default is 1.
echo   -e <END_PORT>      Specify the ending port number. Default is 1024.
echo   -h                 Display the help message with usage instructions.
echo   -l                 List all available commands and options.
echo.
exit /b

:: Initialize variables
set "IP_ADDRESS="
set "START_PORT=1"
set "END_PORT=1024"

:: Parse command line arguments
:parse_args
if "%~1"=="" goto check_ip
if "%~1"=="-h" goto usage
if "%~1"=="-l" goto list_commands
if "%~1"=="-i" (
    set "IP_ADDRESS=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="-s" (
    set "START_PORT=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="-e" (
    set "END_PORT=%~2"
    shift
    shift
    goto parse_args
)
echo Invalid option: %~1
goto usage

:check_ip
if "%IP_ADDRESS%"=="" (
    echo Error: IP address is required.
    goto usage
)

:: Validate port numbers
for %%p in (%START_PORT% %END_PORT%) do (
    set /A "port=%%p"
    if !port! lss 1 (
        echo Error: Port number must be greater than 0.
        exit /b
    )
    if !port! gtr 65535 (
        echo Error: Port number must be less than or equal to 65535.
        exit /b
    )
)

:: Validate port range
if %START_PORT% gtr %END_PORT% (
    echo Error: Start port cannot be greater than end port.
    exit /b
)

:: Log the port range
echo Port Range: %START_PORT% to %END_PORT% >> "%logfile%"

:: Scan ports
echo Scanning IP: %IP_ADDRESS%
echo Ports from %START_PORT% to %END_PORT%
echo -------------------------------

for /L %%p in (%START_PORT%,1,%END_PORT%) do (
    powershell -Command "if (Test-NetConnection -ComputerName '%IP_ADDRESS%' -Port %%p -InformationLevel Quiet) { Write-Output 'Port %%p is open on %IP_ADDRESS%' } else { Write-Output 'Port %%p is closed on %IP_ADDRESS%' }" >> "%logfile%"
)

echo Port scan complete.
endlocal
pause
