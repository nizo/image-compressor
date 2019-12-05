@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

SET /a originalSizeTotal=0
SET /a optimizedSizeTotal=0
SET destinationFolder=optimized
SET /a optimizationStarted=0

if not exist "%destinationFolder%" mkdir "%destinationFolder%"


for %%i in (*.jpg *.png) do (
	if /I "!optimizationStarted!" EQU "0" (
		echo ====================
		echo OPTIMIZATION STARTED
		echo ====================

		SET /a optimizationStarted=1
	)

	SET /a originalSize=%%~zi
	SET optimizedFile=%%~dpi%destinationFolder%\%%~nxi

	if /I "%%~xi" EQU ".jpg" (
		cjpeg-static.exe -quality 75 %%i > !optimizedFile!
	)

	if /I "%%~xi" EQU ".png" (
		pngquant.exe %%i --force --quality=45-85 --output !optimizedFile!
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
