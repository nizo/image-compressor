@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

rem %1 input directory
rem %2 output directory, defaults to input current

if "%~1"=="" (
	echo No input directory provided
) else (
	if exist "%~1" (
		goto setOutputDirectory
	) else (
		echo Input directory is invalid
	)
)
goto quit


:setOutputDirectory
if "%~2"=="" (
	SET destinationDirectory=%~1
	SET overwriteFiles=1
	echo Output directory is missing, files will be overwritten
	pause
) else (
	if exist "%~2" (
		SET destinationDirectory=%~2
	) else (
		mkdir %2
		SET destinationDirectory=%~2
	)
)
goto compress

:compress
SET /a originalSizeTotal=0
SET /a optimizedSizeTotal=0
SET /a optimizationStarted=0

for %%i in ("%~1"*.jpg "%~1"*.png) do (
	if /I "!optimizationStarted!" EQU "0" (
		echo ====================
		echo OPTIMIZATION STARTED
		echo ====================

		SET /a optimizationStarted=1
	)

	SET /a originalSize=%%~zi
	SET optimizedFile="%destinationDirectory%%%~nxi"

	if /I "!overwriteFiles!" EQU "1" (
		SET tempFile="%destinationDirectory%%%~ni_tmp%%~xi"
		if /I "%%~xi" EQU ".jpg" (
			%~dp0/libs/cjpeg-static.exe -quality 75 "%%i" > !tempFile!
		)

		if /I "%%~xi" EQU ".png" (
			%~dp0/libs/pngquant.exe "%%i" --force --quality=45-85 --output !tempFile!
		)

		copy /Y !tempFile! !optimizedFile! >nul
		del /F !tempFile!
	) else (
		if /I "%%~xi" EQU ".jpg" (
			%~dp0/libs/cjpeg-static.exe -quality 75 "%%i" > !optimizedFile!
		)

		if /I "%%~xi" EQU ".png" (
			%~dp0/libs/pngquant.exe %%i --force --quality=45-85 --output !optimizedFile!
		)
	)

	for %%a in (!optimizedFile!) do (
		set /a optimizedFileSize=%%~za
	)

	SET /a optimizedSizeTotal=^(!optimizedSizeTotal!+!optimizedFileSize!^)
	SET /a originalSizeTotal=^(!originalSizeTotal!+!originalSize!^)

	SET /a savedInPercent=^(!optimizedFileSize!*100^)
	SET /a savedInPercent=^(!savedInPercent!/!originalSize!^)
	SET /a savedInPercent=^(100 - !savedInPercent!^)

	echo %%~nxi reduced by ^(!savedInPercent! %%^)
)

if /I "!originalSizeTotal!" NEQ "0" (
	SET /a savedInPercentTotal=^(!optimizedSizeTotal!*100^)
	SET /a savedInPercentTotal=^(!savedInPercentTotal!/!originalSizeTotal!^)
	SET /a savedInPercentTotal=^(100 - !savedInPercentTotal!^)
	SET /a savedInKB=^(!originalSizeTotal!-!optimizedSizeTotal!^)
	SET /a savedInKB=^(!savedInKB!/1000^)

	echo.
	echo ==============================
	echo SIZE REDUCED BY !savedInKB! kB ^(!savedInPercentTotal! %%^)
	echo ==============================
)


:quit
echo.
