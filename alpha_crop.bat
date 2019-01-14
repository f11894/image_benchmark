@echo off
set magick=C:\Software\ImageMagick\magick.exe
IF "%~x1"=="" set Folder=1&&Goto Folder

:enc
%magick% identify -format "%%A" "%~1" | Findstr /R "Blend" && set Alpha=1

FOR /f "DELIMS=" %%A IN ('%magick% identify -format %%w "%~1"') DO SET Width=%%A
FOR /f "DELIMS=" %%A IN ('%magick% identify -format %%h "%~1"') DO SET Height=%%A

set Height2=%Height:~-1,1%
set Width2=%Width:~-1,1%
for %%i in (1,3,5,7,9) do (
   if "%Width2%"=="%%i" set Width_Odd=1
   if "%Height2%"=="%%i" set Height_Odd=1
)

if "%Width_Odd%"=="1" (set /a Width_Resize=%Width%-1) else set Width_Resize=%Width%
if "%Height_Odd%"=="1" (set /a Height_Resize=%Height%-1) else set Height_Resize=%Height%

if "%Alpha%"=="1" (
     %magick% convert "%~1" -background white -flatten -alpha off png24:"%~dpn1_alpha.png"&&del "%~1"
     if not "%Width_Odd%%Height_Odd%"=="" %magick% convert -crop %Width_Resize%x%Height_Resize%+0+0 +repage "%~dpn1_alpha.png" "%~dpn1_trim.png"&&del "%~dpn1_alpha.png"
     if exist "%~dpn1_alpha.png" ren "%~dpn1_alpha.png" "%~n1.png"
     if exist "%~dpn1_trim.png" ren "%~dpn1_trim.png" "%~n1.png"
)

if not "%Width_Odd%%Height_Odd%"=="" if "%Alpha%"=="" %magick% convert -crop %Width_Resize%x%Height_Resize%+0+0 +repage "%~1" "%~dpn1_trim.png"&&del "%~1"
if exist "%~dpn1_trim.png" ren "%~dpn1_trim.png" "%~n1.png"

set Height_Odd=
set Width_Odd=
set Height_Resize=
set Width_Resize=
set Alpha=

if "%Folder%"=="1" exit /b
if "%~2"=="" goto end

Shift
goto enc

:end
exit /b

:Folder
for %%i in ("%~dpn1\*.png") do call :enc "%%i" hoge
pause
exit
