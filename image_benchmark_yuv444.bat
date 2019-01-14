set butteraugli_path=C:\Software\butteraugli\butteraugli.exe
set magick=C:\Software\ImageMagick\magick.exe
set ffmpeg=C:\Software\ffmpeg\ffmpeg.exe
set mp4box="C:\Program Files\GPAC\mp4box.exe"
set timer=C:\Software\timer\timer32.exe

set flif=C:\Software\FLIF-0.3\flif.exe
set fuif=C:\Software\fuif\fuif.exe

set mozjpeg=C:\Software\mozjpeg\cjpeg.exe
set guetzli=C:\Software\guetzli\guetzli_windows_x86-64.exe

set bpg_dir=C:\Software\bpg-0.9.6-win64\
set bpg0.9.5_dir=C:\Software\bpg-0.9.5-win32\
set JXR_dir=C:\Software\JXREncApp\
set opj_dir=C:\Software\openjpeg-v2.3.0-windows-x64\bin\
set libaom_dir=C:\Software\aom_gcc\

set "OUTPUT_DIR=%~dp1%~n1_output\"

set image_del=0
set refimage_del=0
set butteraugli_set=0
cd %~dp1
for %%M in (%SSIM%) do set SSIM_dir="%%~dpM"
for %%M in (%SSIM%) do set SSIM_exe=%%~nxM
for %%M in (%butteraugli_path%) do set butteraugli_dir="%%~dpM"
for %%M in (%butteraugli_path%) do set butteraugli_exe=%%~nxM

:start
SET "A=%~a1"
IF not "%A:~0,1%"=="d" (
   echo フォルダをドロップしてください
   goto end
)
FOR %%A IN ("%~pn1") DO SET "InputFolder=%%~nxA"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

rem call :vp9 %1

rem call :fuif_lossy %1
rem call :flif_lossy %1

call :libaom_8bit %1

call :mozjpeg %1

call :libjpeg %1


rem call :guetzli %1

rem call :jpg_p %1

rem call :mozjpeg_optimize %1

rem call :mozjpeg %1

call :JPEG_2000 %1

call :JPEG_XR %1
call :bpg %1

goto end


:libjpeg
for /L %%H in (1,1,100) do (
    for %%i in ("%~dpn1\*.png") do (
          FOR /f "DELIMS=" %%A IN ('%timer% %magick% convert "%%i" -sampling-factor 1x1 -quality %%H "%OUTPUT_DIR%\%%~ni_libjpeg_yuv444_q%%H.jpg"') DO SET msec=%%A
          call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_libjpeg_yuv444_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_libjpeg_yuv444_q%%H.jpg" libjpeg q%%H
    )
   for %%c in ("%~dp1%InputFolder%_libjpeg_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:mozjpeg
for /L %%H in (1,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      if not exist "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_temp.tga" %magick% convert "%%i" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_temp.tga"
      FOR /f "DELIMS=" %%A IN ('%timer% %mozjpeg% -targa  -tune-ssim -q %%H -sample 1x1 -outfile "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_temp.tga"') DO SET msec=%%A
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_q%%H.jpg" mozjpeg q%%
   )
   for %%t in ("%~dpn1\*.tga") do del "%%t"
   for %%c in ("%~dp1%InputFolder%_mozjpeg_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:guetzli
for /L %%H in (84,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %guetzli% --quality %%H "%%i" "%OUTPUT_DIR%\%%~ni_guetzli_yuv444_q%%H.jpg"') DO SET msec=%%A
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_guetzli_yuv444_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_guetzli_yuv444_q%%H.jpg" guetzli q%%H
   )
   for %%c in ("%~dp1%InputFolder%_guetzli_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:JPEG_2000
for /L %%H in (100,-1,1) do (
   for %%i in ("%~dpn1\*.png") do (
      %magick% convert -strip "%%i" "%OUTPUT_DIR%\%%~ni_j2k_yuv444_temp.png"
      FOR /f "DELIMS=" %%A IN ('%timer% %opj_dir%opj_compress.exe -i "%OUTPUT_DIR%\%%~ni_j2k_yuv444_temp.png" -r %%H -o "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.j2k"') DO SET msec=%%A
      "%opj_dir%opj_decompress.exe" -i "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.j2k" -o "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.j2k" JPEG_2000 q%%H
      del "%OUTPUT_DIR%\%%~ni_j2k_yuv444_temp.png"
   )
   for %%c in ("%~dp1%InputFolder%_JPEG_2000_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:JPEG_XR
for /L %%H in (100,-1,1) do (
   for %%i in ("%~dpn1\*.png") do (
      if not exist "%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp" "%magick% convert" "%%i" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp"
      FOR /f "DELIMS=" %%A IN ('%timer% %JXR_dir%JXREncApp.exe -i "%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp" -q %%H -o "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.jxr"') DO SET msec=%%A
      "%JXR_dir%JXRDecApp.exe" -i "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.jxr" -o "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.bmp"
      %magick% convert "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.bmp" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.jxr" JPEG_XR q%%H
      del "%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp"
      del "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.bmp"
   )
   for %%c in ("%~dp1%InputFolder%_JPEG_XR_yuv444*.csv") do echo. >>"%%c"
)
exit /b)

:vp9
for /L %%H in (63,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+accurate_rnd" -an -pix_fmt yuvj444p -r 1 -vcodec vp9 -b:v 0 -qmin %%H -qmax %%H -threads 8 -an "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.ivf"') DO SET msec=%%A
      %ffmpeg% -y -i "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.ivf" -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+accurate_rnd" -an "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.ivf" vp9 q%%H
      if "%refimage_del%"=="1" del "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.png"
      if "%image_del%"=="1" del "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.ivf"
   )
   for %%c in ("%~dp1%InputFolder%_vp9_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:bpg
for /L %%H in (51,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %bpg_dir%bpgenc.exe -e x265 -q %%H -f 444 -o "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.bpg" "%%i"') DO SET msec=%%A
      "%bpg_dir%bpgdec.exe" -o "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.bpg"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.bpg" bpg q%%H "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.log"
   )
   for %%c in ("%~dp1%InputFolder%_bpg_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:flif_lossy
for /L %%H in (2,2,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %flif% -e -Q %%H "%%~i" "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.flif"') DO SET msec=%%A
      "%flif%" -d "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.flif" "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.flif" flif q%%H
      if "%refimage_del%"=="1" del "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.png"
      if "%image_del%"=="1" del "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.flif"
   )
   for %%c in ("%~dp1%InputFolder%_flif_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:fuif_lossy
for /L %%H in (2,2,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %fuif% -Q %%H "%%~i" "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.fuif"') DO SET msec=%%A
      "%fuif%" -d "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.fuif" "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.fuif" fuif q%%H
   )
   for %%c in ("%~dp1%InputFolder%_fuif_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:libaom_8bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+accurate_rnd" -r 1 -an -pix_fmt yuvj444p -strict -1 "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_temp.y4m"
      FOR /f "DELIMS=" %%A IN ('%timer% "%libaom_dir%aomenc.exe" --ivf --bit-depth^=8 --input-bit-depth^=8 --i444 --full-still-picture-hdr --passes^=2 --tile-columns^=3 --threads^=8 --end-usage^=q --cq-level^=%%H -o "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_temp.y4m"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf" -o - | %ffmpeg% -y -i - -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+accurate_rnd" -an "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf":primary -ab avif -ab miaf -new "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf" libaom_8bit q%%H
      del "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_temp.y4m"
      del "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf"
   )
   for %%c in ("%~dp1%InputFolder%_libaom_8bit_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:libaom_10bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+accurate_rnd" -r 1 -an -pix_fmt yuv444p10le -strict -1 "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_temp.y4m"
      FOR /f "DELIMS=" %%A IN ('%timer% "%libaom_dir%aomenc.exe" --ivf --bit-depth^=10 --input-bit-depth^=10 --i444 --full-still-picture-hdr --passes^=2 --tile-columns^=3 --threads^=8 --end-usage^=q --cq-level^=%%H -o "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_temp.y4m"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf" -o - | %ffmpeg% -y -i - -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+accurate_rnd" -an "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf":primary -ab avif -ab miaf -new "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.avif" libaom_10bit q%%H
      del "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_temp.y4m"
      del "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf"
   )
   for %%c in ("%~dp1%InputFolder%_libaom_10bit_yuv444*.csv") do echo. >>"%%c"
)
exit /b

:end
exit /b

:ssim
setlocal

FOR /f "DELIMS=" %%A IN ('%magick% identify -format %%w "%~1"') DO SET orig_w=%%A
FOR /f "DELIMS=" %%A IN ('%magick% identify -format %%h "%~1"') DO SET orig_h=%%A


SET Filesize=%~z3

FOR /f "DELIMS=" %%A IN ('%magick% compare -metric SSIM "%~1" "%~2" NUL 2^>^&1') DO SET "SSIM_RGB=%%A"
FOR /f "DELIMS=" %%A IN ('%magick% compare -metric PSNR "%~1" "%~2" NUL 2^>^&1') DO SET "PSNR_RGB=%%A"
if "%PSNR_RGB%"=="1.#INF" set PSNR_RGB=INF

:ffmpeg_label
FOR /f "DELIMS=" %%A IN ('%ffmpeg% -i "%~1" -i "%~2" -pix_fmt yuvj444p -lavfi psnr -f null NUL 2^>^&1 ^| find "Parsed_psnr"') DO SET "Parsed_psnr=%%A"
if "%Parsed_psnr%"=="" goto ffmpeg_label
for /f "tokens=5" %%I in ("%Parsed_psnr%") do set "PSNR_y=%%I"
for /f "tokens=8" %%I in ("%Parsed_psnr%") do set "PSNR_yuv=%%I"
set PSNR_y=%PSNR_y:~2%
set PSNR_yuv=%PSNR_yuv:~8%

:ffmpeg_label2
FOR /f "DELIMS=" %%A IN ('%ffmpeg% -i "%~1" -i "%~2" -pix_fmt yuvj444p -lavfi ssim -f null NUL 2^>^&1 ^| find "Parsed_ssim"') DO SET "Parsed_ssim=%%A"
if "%Parsed_ssim%"=="" goto ffmpeg_label2
for /f "tokens=5" %%I in ("%Parsed_ssim%") do set "SSIM_y=%%I"
for /f "tokens=11" %%I in ("%Parsed_ssim%") do set "SSIM_yuv=%%I"
set SSIM_y=%SSIM_y:~2%
set SSIM_yuv=%SSIM_yuv:~4%

echo WScript.Echo (%Filesize%*8)/(%orig_w%*%orig_h%)>"%TEMP%\%~n1_bpp.vbs"
FOR /f "DELIMS=" %%A IN ('cscript //nologo "%TEMP%\%~n1_bpp.vbs"') DO SET bpp_c=%%A
del "%TEMP%\%~n1_bpp.vbs"

if not "%butteraugli_set%"=="1" goto butteraugli_skip
pushd %butteraugli_dir%
FOR /f "DELIMS=" %%A IN ('%butteraugli_exe% "%~1" "%~2"') DO SET butteraugli=%%A
popd

:butteraugli_skip

SET /P X=%Filesize%,<NUL >>"%InputFolder%_%4_yuv444_Filesize.csv"
SET /P X=%bpp_c%,<NUL >>"%InputFolder%_%4_yuv444_bpp.csv"
SET /P X=%PSNR_y%,<NUL >>"%InputFolder%_%4_yuv444_PSNR_y.csv"
SET /P X=%PSNR_yuv%,<NUL >>"%InputFolder%_%4_yuv444_PSNR_yuv.csv"
SET /P X=%PSNR_RGB%,<NUL >>"%InputFolder%_%4_yuv444_PSNR_RGB.csv"
SET /P X=%SSIM_RGB%,<NUL >>"%InputFolder%_%4_yuv444_SSIM_RGB.csv"
SET /P X=%SSIM_y%,<NUL >>"%InputFolder%_%4_yuv444_SSIM_y.csv"
SET /P X=%SSIM_yuv%,<NUL >>"%InputFolder%_%4_yuv444_SSIM_yuv.csv"

if defined butteraugli SET /P X=%butteraugli%,<NUL >>"%InputFolder%_%4_yuv444_butteraugli.csv"
SET /P X=%msec%,<NUL >>"%InputFolder%_%4_yuv444_msec.csv"

endlocal
if "%image_del%"=="1" del "%~2"
if "%refimage_del%"=="1" del "%~3"
exit /b
