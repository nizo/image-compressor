@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

rem %1 input directory
rem %2 output directory, defaults to input current

set /a jpgQuality=75

rem extract absolute paths from the input directory
pushd .
cd %~dp0
set inputDirectory=%~f1
set inputFileName=%~n1
set inputFileExtension=%~x1
set singleFileConversion=0
popd

if "%inputDirectory%"=="" (
	echo No input directory provided
) else (
	if exist "%inputDirectory%" (
		if "%inputFileName%" NEQ "" (
			set extensionSupported=0
			if "%inputFileExtension%" EQU ".jpg" set extensionSupported=1
			if "%inputFileExtension%" EQU ".png" set extensionSupported=1

			if "!extensionSupported!" EQU "1" (
				set /a singleFileConversion=1
				goto setOutputDirectory
			) else (
				echo Extension %inputFileExtension% is not supported
				goto quit
			)
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
		set outputDirectory=%~dp2
		if "!outputDirectory!" EQU "!inputDirectory!" (
			set /a overwriteFiles=1
			echo Input and output directories are the same, files will be overwritten
			set /P continue=Press enter to continue . . .
		)
		if not exist "!outputDirectory!" (
			mkdir "!outputDirectory!"
		)

	) else (
		set outputDirectory=%inputDirectory%
		set overwriteFiles=1
		echo Output directory is not defined, files in the input directory will be overwritten
		set /P continue=Press enter to continue . . .
	)
	goto compress

:compress
	set /a inputSizeTotal=0
	set /a outputSizeTotal=0
	set /a optimizationStarted=0
	set /a counter = 1

	rem change working directory to the input and process files
	set currentDirectory=%~dp0
	cd %1

	echo.

	if "!singleFileConversion!" EQU "1" (
		call :optimizeFile !inputDirectory!

	) else (
		for /R %%i in (*.jpg *.png) do (
			if /I "!optimizationStarted!" EQU "0" (
				echo ==============================
				echo OPTIMIZATION STARTED
				echo ==============================

				set /a optimizationStarted=1
			)
			call :optimizeFile %%i
		)
	)

	goto summary

:optimizeFile
	set /a inputFileSize=%~z1
	if /I "!overwriteFiles!" EQU "1" (
		set outputFile="%~p1%~nx1"
		set tempFile="%~p1%~nx1.__tmp"
	) else (
		rem // Save current directory and change to target directory
		set currentFileInputDirectory=%~dp1
		set currentFileOutputDirectory=!currentFileInputDirectory:%inputDirectory%=%outputDirectory%!
		set outputFile=!currentFileOutputDirectory!%~nx1
		set tempFile=!currentFileOutputDirectory!%~nx1.__tmp

		if not exist "!currentFileOutputDirectory!" (
			mkdir !currentFileOutputDirectory!>nul
		)
	)
	if /I "%~x1" EQU ".jpg" (
		%~dp0/bin/cjpeg-static.exe -quality !jpgQuality! "%1" > !tempFile!
	)

	if /I "%~x1" EQU ".png" (
		%~dp0/bin/pngquant.exe "%1" --force --quality=45-85 --output !tempFile!
	)

	for %%a in (!tempFile!) do (
		set /a tempFileSize=%%~za
	)
	set /a inputSizeTotal=^(!inputSizeTotal!+!inputFileSize!^)

	if "!tempFileSize!" NEQ "0" (
		if "!tempFileSize!" LSS "!inputFileSize!" (
			copy /Y !tempFile! !outputFile! >nul

			set /a outputSizeTotal=^(!outputSizeTotal!+!tempFileSize!^)
			set /a saveInKb=^(!inputFileSize!-!tempFileSize!^)
			set /a saveInKb=^(!saveInKb!/1000^)
			set /a savedInPercent=^(!tempFileSize!*100^)
			set /a savedInPercent=^(!savedInPercent!/!inputFileSize!^)
			set /a savedInPercent=^(100 - !savedInPercent!^)

			echo !counter!  %~nx1 reduced by !saveInKb! kB ^(!savedInPercent! %%^)
			set /a counter=^(!counter!+1^)
		)

	) else (
		echo [101;93mERROR OCCURED [0m
	)

	del /F !tempFile!
	exit /b


:summary
	if /I "!inputSizeTotal!" NEQ "0" (
		set /a savedInPercentTotal=^(!outputSizeTotal!*100^)
		set /a savedInPercentTotal=^(!savedInPercentTotal!/!inputSizeTotal!^)
		set /a savedInPercentTotal=^(100 - !savedInPercentTotal!^)

		set /a savedInKBTotal=^(!inputSizeTotal!-!outputSizeTotal!^)
		set /a savedInKBTotal=^(!savedInKBTotal!/1000^)

		echo ==============================
		echo SIZE REDUCED BY !savedInKBTotal! kB ^(!savedInPercentTotal! %%^)
		echo ==============================

		rem	echo END %time%
	)

:quit
	echo.


