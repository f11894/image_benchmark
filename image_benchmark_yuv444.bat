set butteraugli_path=C:\Software\butteraugli\butteraugli.exe
set magick="C:\Software\ImageMagick\magick.exe"
set ffmpeg="C:\Software\ffmpeg\ffmpeg.exe"
set mp4box="C:\Program Files\GPAC\mp4box.exe"

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
call :libjpeg %1
call :mozjpeg %1
call :guetzli %1

rem call :JPEG_2000 %1
rem call :JPEG_XR %1

rem call :vp9 %1
rem call :fuif_lossy %1
rem call :flif_lossy %1

call :libaom_8bit %1
rem call :bpg %1
rem call :heif  %1
call :Pik %1
call :Pik_fastmode %1

goto end


:libjpeg
for /L %%H in (1,1,100) do (
    for %%i in ("%~dpn1\*.png") do (
          FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%magick% convert '%%~i' -sampling-factor 1x1 -interlace jpeg -quality %%H '%OUTPUT_DIR%\%%~ni_libjpeg_yuv444_q%%H.jpg'}"') DO SET msec=%%A
          call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_libjpeg_yuv444_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_libjpeg_yuv444_q%%H.jpg" libjpeg %%H
    )
)
exit /b

:mozjpeg
for /L %%H in (1,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      if not exist "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_temp.tga" %magick% convert "%%~i" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_temp.tga"
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%mozjpeg% -targa  -tune-ssim -q %%H -sample 1x1 -outfile '%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_q%%H.jpg' '%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_temp.tga'}"') DO SET msec=%%A
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv444_q%%H.jpg" mozjpeg %%H
   )
   for %%t in ("%~dpn1\*.tga") do del "%%t"
)
exit /b

:guetzli
for /L %%H in (84,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%guetzli% --quality %%H '%%~i' '%OUTPUT_DIR%\%%~ni_guetzli_yuv444_q%%H.jpg'}"') DO SET msec=%%A
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_guetzli_yuv444_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_guetzli_yuv444_q%%H.jpg" guetzli %%H
   )
)
exit /b

:JPEG_2000
for /L %%H in (100,-1,1) do (
   for %%i in ("%~dpn1\*.png") do (
      %magick% convert -strip "%%~i" "%OUTPUT_DIR%\%%~ni_j2k_yuv444_temp.png"
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%opj_dir%opj_compress.exe -i '%OUTPUT_DIR%\%%~ni_j2k_yuv444_temp.png' -r %%H -o '%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.j2k'}"') DO SET msec=%%A
      "%opj_dir%opj_decompress.exe" -i "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.j2k" -o "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.png"
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_j2k_yuv444_q%%H.j2k" JPEG_2000 %%H
      del "%OUTPUT_DIR%\%%~ni_j2k_yuv444_temp.png"
   )
)
exit /b

:JPEG_XR
for /L %%H in (100,-1,1) do (
   for %%i in ("%~dpn1\*.png") do (
      if not exist "%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp" %magick% convert "%%~i" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp"
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{"%JXR_dir%JXREncApp.exe" -i '%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp' -q %%H -o '%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.jxr'}"') DO SET msec=%%A
      "%JXR_dir%JXRDecApp.exe" -i "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.jxr" -o "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.bmp"
      %magick% convert "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.bmp" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.png"
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.jxr" JPEG_XR %%H
      del "%OUTPUT_DIR%\%%~ni_jxr_yuv444_temp.bmp"
      del "%OUTPUT_DIR%\%%~ni_jxr_yuv444_q%%H.bmp"
   )
)
exit /b)

:vp9
for /L %%H in (63,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%ffmpeg% -y -i '%%~i' -vf "scale^=out_color_matrix^=bt601:out_range^=pc:flags^=+lanczos+accurate_rnd+bitexact" -an -pix_fmt yuv444p -r 1 -vcodec vp9 -b:v 0 -crf %%H -threads 8 -an '%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.ivf'}"') DO SET msec=%%A
      %ffmpeg% -y -i "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.ivf" -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.png"
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_vp9_yuv444_q%%H.ivf" vp9 %%H
   )
)
exit /b

:bpg
for /L %%H in (51,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%bpg_dir%bpgenc.exe -e x265 -q %%H -f 444 -o '%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.bpg' '%%~i'}"') DO SET msec=%%A
      "%bpg_dir%bpgdec.exe" -o "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.bpg"
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_bpg_yuv444_q%%H.bpg" bpg %%H
   )
)
exit /b

:heif
for /L %%H in (51,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%ffmpeg% -y -framerate 1 -i '%%~i' -pix_fmt yuv444p -vf scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact -crf %%H -tune ssim -preset veryslow -x265-params colormatrix=smpte170m:transfer=smpte170m:colorprim=smpte170m:range=full -f hevc '%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.h265'}"') DO SET msec=%%A
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.h265":primary -ab heic -new "%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.heic"
      chcp 932
      %ffmpeg% -i "%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.h265" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -pix_fmt rgb24 "%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.png"
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.heic" heif %%H
      del "%OUTPUT_DIR%\%%~ni_heif_yuv444_q%%H.h265"
   )
)
exit /b

:flif_lossy
for /L %%H in (2,2,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%flif% -e -Q %%H '%%~i' '%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.flif'}"') DO SET msec=%%A
      "%flif%" -d "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.flif" "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.png"
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_flif_yuv444_q%%H.flif" flif %%H
   )
)
exit /b

:fuif_lossy
for /L %%H in (2,2,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{%fuif% -Q %%H '%%~i' '%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.fuif'}"') DO SET msec=%%A
      "%fuif%" -d "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.fuif" "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.png"
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_fuif_yuv444_q%%H.fuif" fuif %%H
   )
)
exit /b

:libaom_8bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -r 1 -an -pix_fmt yuv444p -strict -1 "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_temp.y4m"
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{"%libaom_dir%aomenc.exe" --ivf --bit-depth=8 --input-bit-depth=8 --i444 --full-still-picture-hdr --passes=2 --tile-columns=2 --tile-rows=1 --threads=8 --end-usage=q --cq-level=%%H -o '%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf' '%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_temp.y4m'}"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf" -o - | %ffmpeg% -y -i - -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf":primary -brand avif -ab avif -ab miaf -ab MA1B -new "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.avif"
      chcp 932
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf" libaom_8bit %%H
      del "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_temp.y4m"
      del "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv444_q%%H.ivf"
   )
)
exit /b

:libaom_10bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=tv:flags=+lanczos+accurate_rnd+bitexact" -r 1 -an -pix_fmt yuv444p10le -strict -1 "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_temp.y4m"
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{"%libaom_dir%aomenc.exe" --ivf --bit-depth=10 --input-bit-depth=10 --i444 --full-still-picture-hdr --passes=2 --tile-columns=2 --tile-rows=1 --threads=8 --end-usage=q --cq-level=%%H -o '%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf' '%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_temp.y4m'}"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf" -o - | %ffmpeg% -y -i - -vf "scale=in_color_matrix=bt601:in_range=tv:flags=+lanczos+accurate_rnd+bitexact" -an "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf":primary -brand avif -ab avif -ab miaf -ab MA1B -new "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.avif"
      chcp 932
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.png" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.avif" libaom_10bit %%H
      del "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_temp.y4m"
      del "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv444_q%%H.ivf"
   )
)
exit /b

:Pik
for %%H in (3.0,2.9,2.8,2.7,2.6,2.5,2.4,2.3,2.2,2.1,2.0,1.9,1.8,1.7,1.6,1.5,1.4,1.3,1.2,1.1,1.0,0.9,0.8,0.7,0.6,0.5) do (
   for %%i in ("%~dpn1\*.png") do (
      pushd "%~1"
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{wsl /mnt/c/Users/ekusu/pik/build/cpik --distance %%H '%%~nxi' '%%~ni_pik_yuv444_q%%H.pik'}"') DO SET msec=%%A
      wsl /mnt/c/Users/ekusu/pik/build/dpik "%%~ni_pik_yuv444_q%%H.pik" "%%~ni_pik_yuv444_q%%H_temp.png"
      move "%%~ni_pik_yuv444_q%%H_temp.png" "%OUTPUT_DIR%\%%~ni_pik_yuv444_q%%H_temp.png"
      move "%%~ni_pik_yuv444_q%%H.pik" "%OUTPUT_DIR%\%%~ni_pik_yuv444_q%%H.pik"
      popd
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_pik_yuv444_q%%H_temp.png" "%OUTPUT_DIR%\%%~ni_pik_yuv444_q%%H.pik" pik %%H
   )
)
exit /b

:Pik_fastmode
for %%H in (3.0,2.9,2.8,2.7,2.6,2.5,2.4,2.3,2.2,2.1,2.0,1.9,1.8,1.7,1.6,1.5,1.4,1.3,1.2,1.1,1.0,0.9,0.8,0.7,0.6,0.5) do (
   for %%i in ("%~dpn1\*.png") do (
      pushd "%~1"
      FOR /f "tokens=3" %%A IN ('PowerShell Measure-Command "{wsl /mnt/c/Users/ekusu/pik/build/cpik --distance %%H --fast '%%~nxi' '%%~ni_pik_fastmode_yuv444_q%%H.pik'}"') DO SET msec=%%A
      wsl /mnt/c/Users/ekusu/pik/build/dpik "%%~ni_pik_fastmode_yuv444_q%%H.pik" "%%~ni_pik_fastmode_yuv444_q%%H_temp.png"
      move "%%~ni_pik_fastmode_yuv444_q%%H_temp.png" "%OUTPUT_DIR%\%%~ni_pik_fastmode_yuv444_q%%H_temp.png"
      move "%%~ni_pik_fastmode_yuv444_q%%H.pik" "%OUTPUT_DIR%\%%~ni_pik_fastmode_yuv444_q%%H.pik"
      popd
      call :ssim "%%~i" "%OUTPUT_DIR%\%%~ni_pik_fastmode_yuv444_q%%H_temp.png" "%OUTPUT_DIR%\%%~ni_pik_fastmode_yuv444_q%%H.pik" pik_fastmode %%H
   )
)
exit /b

:end
exit /b

:ssim
setlocal
for %%i in (%magick%) do pushd "%%~dpi"
FOR /f "DELIMS=" %%A IN ('.\magick.exe identify -format %%w "%~1"') DO SET orig_w=%%A
FOR /f "DELIMS=" %%A IN ('.\magick.exe identify -format %%h "%~1"') DO SET orig_h=%%A
SET Filesize=%~z3
FOR /f "DELIMS=" %%A IN ('.\magick.exe compare -metric SSIM "%~1" "%~2" NUL 2^>^&1') DO SET "SSIM_RGB=%%A"
FOR /f "DELIMS=" %%A IN ('.\magick.exe compare -metric PSNR "%~1" "%~2" NUL 2^>^&1') DO SET "PSNR_RGB=%%A"
popd
if "%PSNR_RGB%"=="1.#INF" set PSNR_RGB=INF

:ffmpeg_label
for %%i in (%ffmpeg%) do pushd "%%~dpi"
FOR /f "DELIMS=" %%A IN ('.\ffmpeg.exe -i "%~1" -i "%~2" -pix_fmt yuvj444p -lavfi psnr -f null NUL 2^>^&1 ^| find "Parsed_psnr"') DO SET "Parsed_psnr=%%A"
popd
if "%Parsed_psnr%"=="" goto ffmpeg_label
for /f "tokens=5" %%I in ("%Parsed_psnr%") do set "PSNR_y=%%I"
for /f "tokens=8" %%I in ("%Parsed_psnr%") do set "PSNR_yuv=%%I"
set PSNR_y=%PSNR_y:~2%
set PSNR_yuv=%PSNR_yuv:~8%

:ffmpeg_label2
for %%i in (%ffmpeg%) do pushd "%%~dpi"
FOR /f "DELIMS=" %%A IN ('.\ffmpeg.exe -i "%~1" -i "%~2" -pix_fmt yuvj444p -lavfi ssim -f null NUL 2^>^&1 ^| find "Parsed_ssim"') DO SET "Parsed_ssim=%%A"
popd
if "%Parsed_ssim%"=="" goto ffmpeg_label2
for /f "tokens=5" %%I in ("%Parsed_ssim%") do set "SSIM_y=%%I"
for /f "tokens=11" %%I in ("%Parsed_ssim%") do set "SSIM_yuv=%%I"
set SSIM_y=%SSIM_y:~2%
set SSIM_yuv=%SSIM_yuv:~4%

FOR /f "DELIMS=" %%A IN ('PowerShell ^(%Filesize%*8^)/^(%orig_w%*%orig_h%^)') DO SET bpp_c=%%A

if not "%butteraugli_set%"=="1" goto butteraugli_skip
pushd %butteraugli_dir%
FOR /f "DELIMS=" %%A IN ('%butteraugli_exe% "%~1" "%~2"') DO SET "butteraugli=,%%A"
set butteraugli_column=,butteraugli
popd

:butteraugli_skip
if not exist "%InputFolder%_%~4_yuv444_csv" mkdir "%InputFolder%_%~4_yuv444_csv"
if not exist "%InputFolder%_%~4_yuv444_csv\%~n1_%~4_yuv444.csv" echo quality,Filesize,bpp,msec,PSNR_y,PSNR_yuv,PSNR_RGB,SSIM_RGB,SSIM_y,SSIM_yuv%butteraugli_column%>"%InputFolder%_%~4_yuv444_csv\%~n1_%~4_yuv444.csv"
echo %~5,%Filesize%,%bpp_c%,%msec%,%PSNR_y%,%PSNR_yuv%,%PSNR_RGB%,%SSIM_RGB%,%SSIM_y%,%SSIM_yuv%%butteraugli%>>"%InputFolder%_%~4_yuv444_csv\%~n1_%~4_yuv444.csv"

endlocal
if "%image_del%"=="1" del "%~2"
if "%refimage_del%"=="1" del "%~3"
exit /b
