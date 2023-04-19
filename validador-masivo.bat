@echo off
setlocal enabledelayedexpansion
set VALIDATION_PATH=%1
set "CURRENT_PATH=%cd%"
set "EXTRACTION_PATH=%CURRENT_PATH%\Extractions"
set "OUTPUT_PATH=%CURRENT_PATH%\Outputs"
set "REPORT_RESULT=%CURRENT_PATH%\validation-report.csv"
set "VALIDATION_RESULT=%OUTPUT_PATH%\validation-result.log"



cd %VALIDATION_PATH%


if exist %OUTPUT_PATH% (
  rmdir /s /q "%OUTPUT_PATH%"
)

if exist %CURRENT_PATH%\validation-errors.log (
  del /s /q "%CURRENT_PATH%\validation-errors.log"
)

mkdir "%OUTPUT_PATH%"

if exist %EXTRACTION_PATH% (
  del /s /q "%EXTRACTION_PATH%"
  rmdir /s /q "%EXTRACTION_PATH%"
)

mkdir "%EXTRACTION_PATH%"

call :println ID_REQ,IS_VALID > "%REPORT_RESULT%"

for /d /r %%f in (*) do (
    call :println %%f
    call :println "-----------------"
    call :validateFad "%%f"
    call :println "###############################"
)

if exist %OUTPUT_PATH% (
  rmdir /s /q "%OUTPUT_PATH%"
)

cd %CURRENT_PATH%
goto exit

:validateFad
cd "%~f1"
set REQ_ID=null
set LLAVE=null
set VECTOR=null
set FAD_NAME=null
set FAD_PATH=null
set is_keys_file=0
set IS_FILE_FAD=0
for %%i in (*.*) do (
  call :println %%i
  call :println "IS_FILE_FAD: !IS_FILE_FAD!"
  call :println "is_keys_file: !is_keys_file!"

  if "!IS_FILE_FAD!"=="0" (
    call :isFadFile "%%i" IS_FILE_FAD
    if "!IS_FILE_FAD!"=="1" (
      call :println "%~f1\%%i"
      set "FAD_PATH=%~f1\"
      set "FAD_NAME=%%i"
    )
  )

  if "!is_keys_file!"=="0" (
    call :isKeysFile "%%i" is_keys_file
    if "!is_keys_file!"=="1" (
      call :readCSVFile "%%i" LLAVE VECTOR, REQ_ID
      call :TRIM !REQ_ID! REQ_ID
      call :println !REQ_ID!
      call :println !LLAVE!
      call :println !VECTOR!
    )
  )
)
if %REQ_ID%==null (
  call :println en la carpeta no se encontraron los parametros necesarios
  EXIT /B 0
)

if %LLAVE%==null (
  call :println en la carpeta no se encontraron los parametros necesarios
  EXIT /B 0
)
if %VECTOR%==null (
  call :println en la carpeta no se encontraron los parametros necesarios
  EXIT /B 0
)
if %FAD_NAME%==null (
  call :println en la carpeta no se encontraron los parametros necesarios
  EXIT /B 0
)
call :println "-------------------------------------------------------------"
call :println "-------------------------------------------------------------"
call :println !REQ_ID!
call :println "-------------------------------------------------------------"
call :println !LLAVE!
call :println "-------------------------------------------------------------"
call :println !VECTOR!
call :println "-------------------------------------------------------------"
call :println !FAD_NAME!
call :println "-------------------------------------------------------------"

set "NEW_FAD=!FAD_NAME!.fad"
rename "%FAD_NAME%" "%NEW_FAD%"

"%CURRENT_PATH%\jdk\bin\java.exe" -jar "%CURRENT_PATH%\FADValidator.jar" -f %NEW_FAD% --key %LLAVE% --vector %VECTOR% -o "%EXTRACTION_PATH%" > "%VALIDATION_RESULT%"

rename "%NEW_FAD%" "%FAD_NAME%"

findstr /x /c:"FAD file is valid" "%VALIDATION_RESULT%"

if %errorlevel%==0 (
  ::echo There is FAD valid!
  echo !REQ_ID!,true >> "%REPORT_RESULT%"
) else (
  ::echo There isn't FAD valid!
  echo !REQ_ID!,false >> "%REPORT_RESULT%"
  echo Requisition ID: !REQ_ID! >> "%CURRENT_PATH%\validation-errors.log"
  echo Errors: >> "%CURRENT_PATH%\validation-errors.log"
  FOR /F "tokens=* delims=" %%x in ('type "%VALIDATION_RESULT%"') DO echo %%x >> "%CURRENT_PATH%\validation-errors.log"
  echo ---------------- >> "%CURRENT_PATH%\validation-errors.log"
  @ECHO. >> "%CURRENT_PATH%\validation-errors.log"
)

if exist %EXTRACTION_PATH% (
  del /s /q "%EXTRACTION_PATH%"
  rmdir /s /q "%EXTRACTION_PATH%"
)

:isFadFile
set FAD_FILE=%~1
set %~2=0
if "!FAD_FILE:~0,13!"=="SOLICITUD_FAD" (
  set %~2=1
)
if "!FAD_FILE:~-4!"==".fad" (
  set %~2=1
)
EXIT /B 0

:isKeysFile
set KEY_FILE=%~1
set %~2=0
if "!KEY_FILE:~0,4!"=="KEYS" (
  set %~2=1
)
if "!KEY_FILE:~-4!"==".csv" (
  set %~2=1
)
EXIT /B 0

:readCSVFile
for /f "usebackq tokens=1-5 delims=," %%a in ("%~1") do (
  echo %%a - %%b %%c
  set "%~4=%%a"
  set %~2="%%b"
  set %~3="%%c"
)
EXIT /B 0

:TRIM
SET %2=%1
GOTO :EOF

:println
echo %~1 >> "%CURRENT_PATH%\output.log"

GOTO :EOF

:exit
exit /b 3