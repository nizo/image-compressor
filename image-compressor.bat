@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

rem %1 input directory
rem %2 output directory, defaults to input current

SET /a jpgQuality=75
rem SET inputDirectory=%~dp1
SET inputFileName=%~n1


rem extract absolute path of the input directory
pushd .
cd %~dp0
SET inputDirectory=%~f1
popd
echo %inputDirectory%

if "%inputDirectory%"=="" (
	echo No input directory provided
) else (
	if exist "%inputDirectory%" (
		if "%inputFilename%" NEQ "" (
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

if "%~2" NEQ "" (
	SET outputDirectory=%~dp2
	if "!outputDirectory!" EQU "!inputDirectory!" (
		SET /a overwriteFiles=1
		echo Input and output directories are the same, files will be overwritten
		SET /P continue=Press enter to continue . . .
	)
	if not exist "!outputDirectory!" (
		mkdir "!outputDirectory!"
	)

) else (
	SET outputDirectory=%inputDirectory%
	SET overwriteFiles=1
	echo Output directory is not defined, files in the input directory will be overwritten
	set /P continue=Press enter to continue . . .
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

rem echo START %time%
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
	) else (
		rem // Save current directory and change to target directory
		SET currentFileInputDirectory=%%~dpi
		SET currentFileOutputDirectory=!currentFileInputDirectory:%inputDirectory%=%outputDirectory%!
		SET outputFile=!currentFileOutputDirectory!%%~nxi
		SET tempFile=!currentFileOutputDirectory!%%~nxi.__tmp

		if not exist "!currentFileOutputDirectory!" (
			mkdir !currentFileOutputDirectory!>nul
		)
	)

	if /I "%%~xi" EQU ".jpg" (
		%~dp0/bin/cjpeg-static.exe -quality !jpgQuality! "%%i" > !tempFile!
	)

	if /I "%%~xi" EQU ".png" (
		%~dp0/bin/pngquant.exe "%%i" --force --quality=45-85 --output !tempFile!
	)

	for %%a in (!tempFile!) do (
		set /a tempFileSize=%%~za
	)

	if "!tempFileSize!" NEQ "0" (
		if "!tempFileSize!" LSS "!inputFileSize!" (
			copy /Y !tempFile! !outputFile! >nul
			del /F !tempFile!
			SET /a outputSizeTotal=^(!outputSizeTotal!+!tempFileSize!^)
			SET /a inputSizeTotal=^(!inputSizeTotal!+!inputFileSize!^)

			SET /a savedInPercent=^(!tempFileSize!*100^)
			SET /a savedInPercent=^(!savedInPercent!/!inputFileSize!^)
			SET /a savedInPercent=^(100 - !savedInPercent!^)

			echo !counter!  %%~nxi reduced by ^(!savedInPercent! %%^)
			set /a counter=^(!counter!+1^)
		)
	) else (
		echo [101;93mOUTPUT SIZE IS 0 [0m
	)
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

	rem	echo END %time%
)

:quit
echo.
