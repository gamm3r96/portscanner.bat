@echo off
setlocal enabledelayedexpansion

:: Set log file path
set "logfile=%~dp0portscan_log.txt"

:: Function to write to the log file
:log
echo %* >> "%logfile%"
exit /b

:: Temporary VBScript file path
set "vbscriptFile=%TEMP%\portscanner_ui.vbs"

:: Function to validate IP address
:validateIP
set "ip=%1"
setlocal enabledelayedexpansion
set "valid=1"

:: Check for the number of octets
for /f "tokens=1-4 delims=." %%a in ("%ip%") do (
    if "%%d"=="" goto invalid
    if "%%e"=="" goto invalid
    if "%%f" neq "" goto invalid
)

:: Validate each octet
for %%a in (%ip%) do (
    if %%a lss 0 goto invalid
    if %%a gtr 255 goto invalid
)

goto :eof

:invalid
set "valid=0"
goto :eof

:: Create VBScript to display a welcome message and collect input
(
    echo Set objShell = CreateObject("WScript.Shell")
    echo userResponse = objShell.InputBox("Enter target IP addresses (comma-separated, e.g., 192.168.1.1,192.168.1.2):", "Port Scanner", "")
    echo WScript.Echo userResponse
    echo Set objShell = Nothing
) > "%vbscriptFile%"

:: Run VBScript to get target IPs
for /f "delims=" %%a in ('cscript //nologo "%vbscriptFile%"') do set "TARGET_IPS=%%a"

:: Collect start and end ports
set /p "START_PORT=Enter the starting port number (default: 1): "
set /p "END_PORT=Enter the ending port number (default: 1024): "

:: Set default values if no input
if "%START_PORT%"=="" set "START_PORT=1"
if "%END_PORT%"=="" set "END_PORT=1024"

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
call :log "Port Range: %START_PORT% to %END_PORT%"

:: Split the IPs by comma
for %%i in (%TARGET_IPS%) do (
    set "TARGET_IP=%%i"
    
    :: Validate IP address
    call :validateIP "!TARGET_IP!"
    if !valid!==0 (
        echo Invalid IP address: !TARGET_IP!. Skipping...
        call :log "Invalid IP address: !TARGET_IP!. Skipping..."
        continue
    )

    :: Log start of the scan for each IP
    call :log "Port Scan Started for !TARGET_IP!"
    echo Scanning IP: !TARGET_IP!

    :: Output initial UI pop-up
    (
        echo Set objShell = CreateObject("WScript.Shell")
        echo objShell.Popup "Port Scanner Started for !TARGET_IP!. Please wait while scanning...", 5, "Port Scanner", 64
        echo Set objShell = Nothing
    ) > "%vbscriptFile%"

    :: Run the VBScript to display the initial UI pop-up
    cscript //nologo "%vbscriptFile%"

    :: Loop through the port range and show progress
    echo.
    echo Scanning ports from %START_PORT% to %END_PORT% on !TARGET_IP!
    echo -------------------------------

    set "progress=0"
    for /L %%p in (%START_PORT%,1,%END_PORT%) do (
        echo Checking port %%p on !TARGET_IP!...
        
        :: Capture the result
        set "result="
        for /f "delims=" %%r in ('powershell -Command "if (Test-NetConnection -ComputerName '!TARGET_IP!' -Port %%p -InformationLevel Quiet) { 'Port %%p is open on !TARGET_IP!.' } else { 'Port %%p is closed on !TARGET_IP!.' }"') do set "result=%%r"
        echo !result!

        :: Log the result
        call :log "!result!"

        :: Update progress
        set /A "progress+=1"
        set /A "percent=(progress*100)/(%END_PORT%-%START_PORT%+1)"
        
        :: Create VBScript to show progress
        (
            echo Set objShell = CreateObject("WScript.Shell")
            echo objShell.Popup "Scanning: !percent!%% complete for !TARGET_IP!", 1, "Progress", 64
            echo Set objShell = Nothing
        ) > "%vbscriptFile%"

        :: Run VBScript to display progress
        cscript //nologo "%vbscriptFile%"
    )

    :: Display final completion message for each IP
    (
        echo Set objShell = CreateObject("WScript.Shell")
        echo objShell.Popup "Port Scan Complete for !TARGET_IP!. Check the results in the console.", 5, "Port Scanner", 64
        echo Set objShell = Nothing
    ) > "%vbscriptFile%"

    :: Run VBScript to display final message
    cscript //nologo "%vbscriptFile%"

    :: Log completion for each IP
    call :log "Port Scan Complete for !TARGET_IP!"
)

:: Clean up temporary VBScript file
del "%vbscriptFile%"

endlocal
pause
