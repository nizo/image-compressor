@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

rem %1 input directory
rem %2 output directory, defaults to input current

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
	if "!destinationDirectory!" EQU "%~2" (
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
SET /a originalSizeTotal=0
SET /a optimizedSizeTotal=0
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

	SET /a originalSize=%%~zi
	if /I "!overwriteFiles!" EQU "1" (
		SET optimizedFile="%%~pi%%~nxi"
		SET tempFile="%%~pi%%~nxi.__tmp"
		if /I "%%~xi" EQU ".jpg" (
			%~dp0/libs/cjpeg-static.exe -quality 75 "%%i" > !tempFile!
		)

		if /I "%%~xi" EQU ".png" (
			%~dp0/libs/pngquant.exe "%%i" --force --quality=45-85 --output !tempFile!
		)

		copy /Y !tempFile! !optimizedFile! >nul
		del /F !tempFile!
	) else (
		SET optimizedFile="%destinationDirectory%%%~nxi"
		if /I "%%~xi" EQU ".jpg" (
			%~dp0/libs/cjpeg-static.exe -quality !jpegQuality! "%%i" > !optimizedFile!
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

	echo !counter!  %%~nxi reduced by ^(!savedInPercent! %%^)
	set /a counter=^(!counter!+1^)
)

if /I "!originalSizeTotal!" NEQ "0" (
	SET /a savedInPercentTotal=^(!optimizedSizeTotal!*100^)
	SET /a savedInPercentTotal=^(!savedInPercentTotal!/!originalSizeTotal!^)
	SET /a savedInPercentTotal=^(100 - !savedInPercentTotal!^)
	SET /a savedInKB=^(!originalSizeTotal!-!optimizedSizeTotal!^)
	SET /a savedInKB=^(!savedInKB!/1000^)

	echo ==============================
	echo SIZE REDUCED BY !savedInKB! kB ^(!savedInPercentTotal! %%^)
	echo ==============================
)

:quit
echo.
