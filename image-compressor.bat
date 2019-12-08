@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

rem %1 input directory
rem %2 output directory, defaults to input current
rem image-compressor.bat ./input ./output --q75
rem image-compressor.bat ./input --q75


rem save input directory
pushd .
cd %~dp0
set inputDirectory=%~f1
set inputFileName=%~n1
set inputFileExtension=%~x1
set singleFileConversion=0
set extractedJpgQuality=""
set /a jpgQuality=75
popd

rem save output directory
pushd .
cd %~dp0
set outputDirectory=%~f2
popd

if "%inputDirectory%"=="" (
	echo No input directory provided
) else (
	if exist "%inputDirectory%" (
		if "%2" NEQ "" (
			call :extractJpgQuality %2
			if !extractedJpgQuality! NEQ "" (
				set /a jpgQuality=!extractedJpgQuality!
				set outputDirectory=
			)
		)
		if "%3" NEQ "" (
			call :extractJpgQuality %3
			if !extractedJpgQuality! NEQ "" (
				set /a jpgQuality=!extractedJpgQuality!
			)
		)

		if "%inputFileName%" NEQ "" (
			rem Single file optimization

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
			rem Directory optimization
			goto setOutputDirectory
		)
	) else (
		echo Input directory is invalid
	)
)
goto quit

:extractJpgQuality
	set candidate=%1
	set extractedJpgQuality=""
	if "!candidate:~0,3!" EQU "--q" (
		set rawJpgQuality=!candidate:--q=!
		if !rawJpgQuality! EQU +!rawJpgQuality! (
			if !rawJpgQuality! GTR 100 (
				set /a rawJpgQuality=100
			)
			if !rawJpgQuality! LSS 0 (
				set /a rawJpgQuality=0
			)
			set /a extractedJpgQuality=!rawJpgQuality!
		) else (
			echo JPEG quality parameter is invalid, try "image-compressor.bat ./input --q75"
			goto quit
		)
	)
	exit /b

:setOutputDirectory
	if "!outputDirectory!" NEQ "" (
		rem Set output directory/create directory
		if "!outputDirectory!" EQU "!inputDirectory!" (
			set /a overwriteFiles=1
			echo Input and output directories are the same, files will be overwritten
			set /P continue=Press enter to continue . . .
		)
		if not exist "!outputDirectory!" (
			mkdir "!outputDirectory!"
		)

	) else (
		rem No output directory is specified, overwrite input
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
				echo OPTIMIZATION STARTED ^(quality !jpgQuality!^)
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
		if !tempFileSize! LSS !inputFileSize! (
			copy /Y !tempFile! !outputFile! >nul

			set /a outputSizeTotal=^(!outputSizeTotal!+!tempFileSize!^)
			set /a savedInKB=^(!inputFileSize!-!tempFileSize!^)
			set /a savedInKB=^(!savedInKB!/1000^)
			set /a savedInPercent=^(!tempFileSize!*100^)
			set /a savedInPercent=^(!savedInPercent!/!inputFileSize!^)
			set /a savedInPercent=^(100 - !savedInPercent!^)

			echo !counter!  %~nx1 reduced by !savedInKB! kB ^(!savedInPercent! %%^)
		) else (
			rem original is more efficient than optimized
			set /a outputSizeTotal=^(!outputSizeTotal!+!inputFileSize!^)
			if /I "!overwriteFiles!" NEQ "1" (
				copy /Y %1 !outputFile! >nul
			)
			echo !counter!  %~nx1 - Optimized file is bigger than original, not replacing
		)
		set /a counter=^(!counter!+1^)

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


