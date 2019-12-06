@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

rem %1 input directory
rem %2 output directory, defaults to input current

SET /a jpgQuality=75

if "%~1"=="" (
	echo No input directory provided
) else (
	if exist "%~1" (
		if "%~n1" NEQ "" (
			echo Single file compression is not supported
		) else (
			goto setOutputDirectory
		)
	) else (
		echo Input directory is invalid
	)
)
goto quit

:setOutputDirectory
if exist "%~2" (
	SET destinationDirectory=%~2
	if "!destinationDirectory!" EQU "%~1" (
		SET /a overwriteFiles=1
		echo Input and output directories are the same, files will be overwritten
		SET /P continue=Press enter to continue . . .
	)
) else (
	SET destinationDirectory=%~1
	SET overwriteFiles=1
	echo Output directory is not defined, files in the input directory will be overwritten
	set /P continue=Press enter to continue . . .

	rem mkdir %2
	rem  SET destinationDirectory=%~2
)
goto compress

:compress
SET /a inputSizeTotal=0
SET /a outputSizeTotal=0
SET /a optimizationStarted=0
SET /a counter = 1

rem change working directory to the input and process files
SET currentDirectory=%~dp0
cd %1

echo.

for /R %%i in (*.jpg *.png) do (
	if /I "!optimizationStarted!" EQU "0" (
		echo ==============================
		echo OPTIMIZATION STARTED
		echo ==============================

		SET /a optimizationStarted=1
	)

	SET /a inputFileSize=%%~zi
	if /I "!overwriteFiles!" EQU "1" (
		SET outputFile="%%~pi%%~nxi"
		SET tempFile="%%~pi%%~nxi.__tmp"
		if /I "%%~xi" EQU ".jpg" (
			%~dp0/libs/cjpeg-static.exe -quality !jpgQuality! "%%i" > !tempFile!
		)

		if /I "%%~xi" EQU ".png" (
			%~dp0/libs/pngquant.exe "%%i" --force --quality=45-85 --output !tempFile!
		)

		copy /Y !tempFile! !outputFile! >nul
		del /F !tempFile!
	) else (
		SET outputFile=%%~dpi
		SET outputFileDirectory=!outputFile:%~1=%~2!
		SET outputFile=!outputFileDirectory!%%~nxi

		if not exist "!outputFileDirectory!" (
			mkdir !outputFileDirectory!>nul
		)

		if /I "%%~xi" EQU ".jpg" (
			%~dp0/libs/cjpeg-static.exe -quality !jpgQuality! "%%i" > !outputFile!
		)

		if /I "%%~xi" EQU ".png" (
			%~dp0/libs/pngquant.exe %%i --force --quality=45-85 --output !outputFile!
		)
	)

	for %%a in (!outputFile!) do (
		set /a outputFileSize=%%~za
	)

	SET /a outputSizeTotal=^(!outputSizeTotal!+!outputFileSize!^)
	SET /a inputSizeTotal=^(!inputSizeTotal!+!inputFileSize!^)

	SET /a savedInPercent=^(!outputFileSize!*100^)
	SET /a savedInPercent=^(!savedInPercent!/!inputFileSize!^)
	SET /a savedInPercent=^(100 - !savedInPercent!^)

	echo !counter!  %%~nxi reduced by ^(!savedInPercent! %%^)
	set /a counter=^(!counter!+1^)
)

if /I "!inputSizeTotal!" NEQ "0" (
	SET /a savedInPercentTotal=^(!outputSizeTotal!*100^)
	SET /a savedInPercentTotal=^(!savedInPercentTotal!/!inputSizeTotal!^)
	SET /a savedInPercentTotal=^(100 - !savedInPercentTotal!^)
	SET /a savedInKB=^(!inputSizeTotal!-!outputSizeTotal!^)
	SET /a savedInKB=^(!savedInKB!/1000^)

	echo ==============================
	echo SIZE REDUCED BY !savedInKB! kB ^(!savedInPercentTotal! %%^)
	echo ==============================
)

:quit
echo.
