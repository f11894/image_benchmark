set butteraugli_path=C:\Software\butteraugli\butteraugli.exe
set magick=C:\Software\ImageMagick\magick.exe
set ffmpeg=C:\Software\ffmpeg\ffmpeg.exe
set ffmpeg_vmaf=C:\Software\ffmpeg_vmaf\ffmpeg.exe
set mp4box="C:\Program Files\GPAC\mp4box.exe"
set timer=C:\Software\timer\timer32.exe

set flif=C:\Software\FLIF-0.3\flif.exe
set mozjpeg=C:\Software\mozjpeg\cjpeg.exe
set guetzli=C:\Software\guetzli\guetzli_windows_x86-64.exe

set bpg_dir=C:\Software\bpg-0.9.8-win64\
set bpg0.9.5_dir=C:\Software\bpg-0.9.5-win32\
set JXR_dir=C:\Software\JXREncApp\
set opj_dir=C:\Software\openjpeg-v2.3.0-windows-x64\bin\
set libaom_dir=C:\Software\aom_gcc\
set SVT-AV1="C:\Software\SVT-AV1\SvtAv1EncApp.exe"

set "OUTPUT_DIR=%~dp1%~n1_output\"
set image_del=1
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
for %%i in ("%~dpn1\*.png") do call "%~dp0alpha_crop.bat" "%%i"

call :SVT-AV1 %1
call :libjpeg %1
call :libaom_8bit %1
call :rav1e %1
call :webp %1
call :heif %1

goto end

call :JPEG_2000 %1
rem call :mozjpeg %1

rem call :guetzli %1
call :JPEG_XR %1
call :vp9 %1
rem call :bpg %1

goto end


:libjpeg
for /L %%H in (1,1,100) do (
    for %%i in ("%~dpn1\*.png") do (
          FOR /f "DELIMS=" %%A IN ('%timer% %magick% convert "%%i" -sampling-factor 2x2 -interlace jpeg -quality %%H "%OUTPUT_DIR%\%%~ni_libjpeg_yuv420_q%%H.jpg"') DO SET msec=%%A
          %magick% convert "%OUTPUT_DIR%\%%~ni_libjpeg_yuv420_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_libjpeg_yuv420_q%%H.png"
          call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_libjpeg_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_libjpeg_yuv420_q%%H.jpg" libjpeg q%%H
    )
   for %%c in ("%~dp1%InputFolder%_libjpeg_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:mozjpeg
for /L %%H in (1,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      if not exist "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv420_temp.tga" %magick% convert "%%i" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv420_temp.tga"
      FOR /f "DELIMS=" %%A IN ('%timer% %mozjpeg% -targa  -tune-ssim -q %%H -sample 2x2 -outfile "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv420_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv420_temp.tga"') DO SET msec=%%A
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv420_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_mozjpeg_yuv420_q%%H.jpg" mozjpeg q%%
   )
   for %%t in ("%~dpn1\*.tga") do del "%%t"
   for %%c in ("%~dp1%InputFolder%_mozjpeg_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:guetzli
for /L %%H in (84,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %guetzli% --quality %%H "%%i" "%OUTPUT_DIR%\%%~ni_guetzli_yuv420_q%%H.jpg"') DO SET msec=%%A
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_guetzli_yuv420_q%%H.jpg" "%OUTPUT_DIR%\%%~ni_guetzli_yuv420_q%%H.jpg" guetzli q%%H
   )
   for %%c in ("%~dp1%InputFolder%_guetzli_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:JPEG_2000
for /L %%H in (100,-1,1) do (
   for %%i in ("%~dpn1\*.png") do (
      set JPEG_2000_output="%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H.j2k"
      set JPEG_2000_input_raw="%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H_temp.raw"
      set JPEG_2000_input="%%i"
      %ffmpeg% -i "%%i" -y -an -pix_fmt yuv420p -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" "%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H_temp.yuv"
      ren "%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H_temp.yuv" %%~ni_j2k_yuv420_q%%H_temp.raw
      call :JPEG_2000_delayedexpansion %%H
      %ffmpeg% -i "%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H.j2k" -y -an -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+lanczos+accurate_rnd+bitexact" "%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H.j2k" JPEG_2000 q%%H
      del "%OUTPUT_DIR%\%%~ni_j2k_yuv420_q%%H_temp.raw"
   )
   for %%c in ("%~dp1%InputFolder%_JPEG_2000_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:JPEG_2000_delayedexpansion
FOR /f "DELIMS=" %%A IN ('identify -format %%w %JPEG_2000_input%') DO SET orig_w=%%A
FOR /f "DELIMS=" %%A IN ('identify -format %%h %JPEG_2000_input%') DO SET orig_h=%%A
FOR /f "DELIMS=" %%A IN ('%timer% %opj_dir%opj_compress.exe -i %JPEG_2000_input_raw% -F %orig_w%^,%orig_h%^,3^,8^,u@1x1:2x2:2x2 -mct 0 -r %1 -o %JPEG_2000_output%') DO SET msec=%%A
exit /b

:JPEG_XR
for /L %%H in (100,-1,1) do (
   for %%i in ("%~dpn1\*.png") do (
      if not exist "%OUTPUT_DIR%\%%~ni_jxr_yuv420_temp.bmp" %magick% convert "%%i" "%OUTPUT_DIR%\%%~ni_jxr_yuv420_temp.bmp"
      FOR /f "DELIMS=" %%A IN ('%timer% %JXR_dir%JXREncApp.exe -i "%OUTPUT_DIR%\%%~ni_jxr_yuv420_temp.bmp" -q %%H -d 1 -o "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.jxr"') DO SET msec=%%A
      "%JXR_dir%JXRDecApp.exe" -i "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.jxr" -o "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.bmp"
      %magick% convert "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.bmp" "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.jxr" JPEG_XR q%%H
      del "%OUTPUT_DIR%\%%~ni_jxr_yuv420_temp.bmp"
      del "%OUTPUT_DIR%\%%~ni_jxr_yuv420_q%%H.bmp"
   )
   for %%c in ("%~dp1%InputFolder%_JPEG_XR_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:vp9
for /L %%H in (63,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an -pix_fmt yuvj420p -r 1 -vcodec vp9 -b:v 0 -qmin %%H -qmax %%H -threads 8 -an "%OUTPUT_DIR%\%%~ni_vp9_yuv420_q%%H.ivf"') DO SET msec=%%A
      %ffmpeg% -y -i "%OUTPUT_DIR%\%%~ni_vp9_yuv420_q%%H.ivf" -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an "%OUTPUT_DIR%\%%~ni_vp9_yuv420_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_vp9_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_vp9_yuv420_q%%H.ivf" vp9 q%%H
   )
   for %%c in ("%~dp1%InputFolder%_vp9_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:bpg
for /L %%H in (51,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %bpg_dir%bpgenc.exe -e x265 -m 9 -q %%H -f 420 -o "%OUTPUT_DIR%\%%~ni_bpg_yuv420_q%%H.bpg" "%%i"') DO SET msec=%%A
      "%bpg_dir%bpgdec.exe" -o "%OUTPUT_DIR%\%%~ni_bpg_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_bpg_yuv420_q%%H.bpg"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_bpg_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_bpg_yuv420_q%%H.bpg" bpg q%%H
   )
   for %%c in ("%~dp1%InputFolder%_bpg_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:heif
for /L %%H in (51,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %ffmpeg% -y -framerate 1 -i "%%i" -pix_fmt yuv420p -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -crf %%H -tune ssim -preset veryslow -x265-params "colormatrix=smpte170m:transfer=smpte170m:colorprim=smpte170m:range=full" -f hevc "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.h265"') DO SET msec=%%A
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.h265":primary -ab heic -new "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.heic"
      chcp 932
      %ffmpeg% -i "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.h265" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -pix_fmt rgb24 "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.png"
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.heic" heif q%%H
      del "%OUTPUT_DIR%\%%~ni_heif_yuv420_q%%H.h265"
   )
   for %%c in ("%~dp1%InputFolder%_heif_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:libaom_8bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -r 1 -an -pix_fmt yuv420p -strict -1 "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_temp.y4m"
      FOR /f "DELIMS=" %%A IN ('%timer% "%libaom_dir%aomenc.exe" --ivf --bit-depth^=8 --input-bit-depth^=8 --full-still-picture-hdr --i420 --passes^=2 --tile-columns^=3 --threads^=8 --end-usage^=q --cq-level^=%%H -o "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.ivf" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_temp.y4m"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.ivf" -o - | %ffmpeg% -y -i - -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.ivf":primary -ab avif -ab miaf -new "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.avif" libaom_8bit q%%H
      del "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_temp.y4m"
      del "%OUTPUT_DIR%\%%~ni_libaom_8bit_yuv420_q%%H.ivf"
   )
   for %%c in ("%~dp1%InputFolder%_libaom_8bit_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:libaom_10bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      %ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=tv:flags=+lanczos+accurate_rnd+bitexact" -r 1 -an -pix_fmt yuv420p10le -strict -1 "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_temp.y4m"
      FOR /f "DELIMS=" %%A IN ('%timer% "%libaom_dir%aomenc.exe" --ivf --bit-depth^=10 --input-bit-depth^=10 --i420 --full-still-picture-hdr --passes^=2 --tile-columns^=3 --threads^=8 --end-usage^=q --cq-level^=%%H -o "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.ivf" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_temp.y4m"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.ivf" -o - | %ffmpeg% -y -i -  -vf "scale=in_color_matrix=bt601:in_range=tv:flags=+lanczos+accurate_rnd+bitexact"  -an "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.ivf":primary -ab avif -ab miaf -new "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.avif" libaom_10bit q%%H
      del "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_temp.y4m"
      del "%OUTPUT_DIR%\%%~ni_libaom_10bit_yuv420_q%%H.ivf"
   )
   for %%c in ("%~dp1%InputFolder%_libaom_10bit_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:rav1e
for /L %%H in (255,-10,5) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%ffmpeg% -y -i "%%~i" -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an -pix_fmt yuv420p -strict -1 -f yuv4mpegpipe - ^| timer64 "C:\Software\rav1e\rav1e.exe" --quantizer %%H --tune psnr -s 0 - -o "%OUTPUT_DIR%\%%~ni_rav1e_yuv420_q%%H.ivf"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_rav1e_yuv420_q%%H.ivf" -o - | %ffmpeg% -i - -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an "%OUTPUT_DIR%\%%~ni_rav1e_yuv420_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_rav1e_yuv420_q%%H.ivf":primary -ab avif -ab miaf -new "%OUTPUT_DIR%\%%~ni_rav1e_yuv420_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_rav1e_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_rav1e_yuv420_q%%H.avif" rav1e q%%H
   )
   for %%c in ("%~dp1%InputFolder%_rav1e_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:SVT-AV1
for /L %%H in (62,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      set SVT-AV1_input="%%i"
      set SVT-AV1_input_yuv="%%~dpni.yuv"
      set SVT-AV1_output="%OUTPUT_DIR%\%%~ni_SVT-AV1_yuv420_q%%H.ivf"
      call :SVT-AV1_delayedexpansion %%H
      "%libaom_dir%aomdec.exe" "%OUTPUT_DIR%\%%~ni_SVT-AV1_yuv420_q%%H.ivf" -o - | %ffmpeg% -i - -vf "scale=in_color_matrix=bt601:in_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an "%OUTPUT_DIR%\%%~ni_SVT-AV1_yuv420_q%%H.png"
      %mp4box% -add-image "%OUTPUT_DIR%\%%~ni_SVT-AV1_yuv420_q%%H.ivf":primary -ab avif -ab miaf -new "%OUTPUT_DIR%\%%~ni_SVT-AV1_yuv420_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_SVT-AV1_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_SVT-AV1_yuv420_q%%H.avif" SVT-AV1 q%%H
   )
   for %%c in ("%~dp1%InputFolder%_SVT-AV1_yuv420*.csv") do echo. >>"%%c"
)
exit /b

:SVT-AV1_delayedexpansion
FOR /f "DELIMS=" %%A IN ('identify -format %%w %SVT-AV1_input%') DO SET orig_w=%%A
FOR /f "DELIMS=" %%A IN ('identify -format %%h %SVT-AV1_input%') DO SET orig_h=%%A
%ffmpeg% -y -i %SVT-AV1_input% -vf "scale=out_color_matrix=bt601:out_range=pc:flags=+lanczos+accurate_rnd+bitexact" -an -pix_fmt yuv420p -strict -1 -f rawvideo %SVT-AV1_input_yuv%
FOR /f "DELIMS=" %%A IN ('%timer% %SVT-AV1% -i %SVT-AV1_input_yuv% -enc-mode 0 -w %orig_w% -h %orig_h% -n 1 -fps 1 -rc 0 -q %~1 -b %SVT-AV1_output%') DO SET msec=%%A
del %SVT-AV1_input_yuv%
exit /b

:webp
for /L %%H in (1,1,100) do (
    for %%i in ("%~dpn1\*.png") do (
          FOR /f "DELIMS=" %%A IN ('%timer% %magick% convert "%%i" -quality %%H "%OUTPUT_DIR%\%%~ni_webp_yuv420_q%%H.webp"') DO SET msec=%%A
          %magick% convert "%OUTPUT_DIR%\%%~ni_webp_yuv420_q%%H.webp" "%OUTPUT_DIR%\%%~ni_webp_yuv420_q%%H.png"
          call :ssim "%%i" "%OUTPUT_DIR%\%%~ni_webp_yuv420_q%%H.png" "%OUTPUT_DIR%\%%~ni_webp_yuv420_q%%H.webp" webp q%%H
    )
   for %%c in ("%~dp1%InputFolder%_webp_yuv420*.csv") do echo. >>"%%c"
)
for %%c in ("%~dp1%InputFolder%_webp_yuv420*.csv") do echo. >>"%%c"

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
FOR /f "DELIMS=" %%A IN ('%ffmpeg% -r 1 -i "%~1" -r 1 -i "%~2" -pix_fmt yuvj444p -lavfi psnr -f null NUL 2^>^&1 ^| find "Parsed_psnr"') DO SET Parsed_psnr=%%A
if "%Parsed_psnr%"=="" goto ffmpeg_label
for /f "tokens=5" %%I in ("%Parsed_psnr%") do set PSNR_y=%%I
for /f "tokens=8" %%I in ("%Parsed_psnr%") do set PSNR_yuv=%%I
set PSNR_y=%PSNR_y:~2%
set PSNR_yuv=%PSNR_yuv:~8%

:ffmpeg_label2
FOR /f "DELIMS=" %%A IN ('%ffmpeg% -r 1 -i "%~1" -r 1 -i "%~2" -pix_fmt yuvj444p -lavfi ssim -f null NUL 2^>^&1 ^| find "Parsed_ssim"') DO SET Parsed_ssim=%%A
if "%Parsed_ssim%"=="" goto ffmpeg_label2
for /f "tokens=5" %%I in ("%Parsed_ssim%") do set SSIM_y=%%I
for /f "tokens=11" %%I in ("%Parsed_ssim%") do set SSIM_yuv=%%I
set SSIM_y=%SSIM_y:~2%
set SSIM_yuv=%SSIM_yuv:~4%

:ffmpeg_label3
pushd "C:\Software\ffmpeg_vmaf\model"
FOR /f "tokens=6" %%A IN ('%ffmpeg% -loglevel quiet -r 1 -i "%~2" -pix_fmt yuv420p -f yuv4mpegpipe - ^| %ffmpeg_vmaf% -r 1 -i - -r 1 -i "%~1" -filter_complex "libvmaf=model_path=vmaf_v0.6.1.pkl" -an -f null NUL 2^>^&1 ^| find "VMAF score"') DO SET VMAF=%%A
popd
if "%VMAF%"=="" goto ffmpeg_label3

FOR /f "DELIMS=" %%A IN ('PowerShell ^(%Filesize%*8^)/^(%orig_w%*%orig_h%^)') DO SET bpp_c=%%A

if not "%butteraugli_set%"=="1" goto butteraugli_skip
pushd %butteraugli_dir%
FOR /f "DELIMS=" %%A IN ('%butteraugli_exe% "%~1" "%~2"') DO SET butteraugli=%%A
popd

:butteraugli_skip

SET /P X=%Filesize%,<NUL >>"%InputFolder%_%4_yuv420_Filesize.csv"
SET /P X=%bpp_c%,<NUL >>"%InputFolder%_%4_yuv420_bpp.csv"
SET /P X=%PSNR_y%,<NUL >>"%InputFolder%_%4_yuv420_PSNR_y.csv"
SET /P X=%PSNR_yuv%,<NUL >>"%InputFolder%_%4_yuv420_PSNR_yuv.csv"
SET /P X=%PSNR_RGB%,<NUL >>"%InputFolder%_%4_yuv420_PSNR_RGB.csv"
SET /P X=%SSIM_RGB%,<NUL >>"%InputFolder%_%4_yuv420_SSIM_RGB.csv"
SET /P X=%SSIM_y%,<NUL >>"%InputFolder%_%4_yuv420_SSIM_y.csv"
SET /P X=%SSIM_yuv%,<NUL >>"%InputFolder%_%4_yuv420_SSIM_yuv.csv"
SET /P X=%VMAF%,<NUL >>"%InputFolder%_%4_yuv420_VMAF.csv"

if defined butteraugli SET /P X=%butteraugli%,<NUL >>"%InputFolder%_%4_yuv420_butteraugli.csv"
SET /P X=%msec%,<NUL >>"%InputFolder%_%4_yuv420_msec.csv"

endlocal
if "%image_del%"=="1" del "%~2"
if "%refimage_del%"=="1" del "%~3"
exit /b
