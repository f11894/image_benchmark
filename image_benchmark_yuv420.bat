set SSIM=C:\Software\SSIM\bin\SSIM.exe
set butteraugli_path=C:\Software\butteraugli\butteraugli.exe
set IMcon=C:\Software\ImageMagick\convert.exe
set ffmpeg=C:\Software\ffmpeg\ffmpeg.exe

set timer=C:\Software\timer\timer32.exe

set mkvextract="C:\Program Files\MKVToolNix\mkvextract.exe"

set flif=C:\Software\FLIF-0.3\flif.exe
set mozjpeg=C:\Software\mozjpeg\cjpeg.exe
set guetzli=C:\Software\guetzli\guetzli_windows_x86-64.exe

set bpg_dir=C:\Software\bpg-0.9.8-win64\
set bpg0.9.5_dir=C:\Software\bpg-0.9.5-win32\
set JXR_dir=C:\Software\JXREncApp\
set opj_dir=C:\Software\openjpeg-v2.3.0-windows-x64\bin\
set libaom_dir=C:\Software\aom_gcc\

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
for %%i in ("%~dpn1\*.png") do call "%~dp0alpha_crop.bat" "%%i"


call :libaom_8bit %1
pause


call :rav1e %1

pause

call :libaom %1

call :libjpeg %1

pause

call :heif %1
call :bpg %1

call :JPEG_2000 %1

call :guetzli %1

call :h264_qsv %1

call :x264 %1

call :libjpeg %1


call :webp %1



rem call :mozjpeg %1

rem call :guetzli %1

rem call :mozjpeg %1


call :JPEG_XR %1
call :vp9 %1
rem call :bpg %1
rem call :flif_lossy %1

goto end


:libjpeg
for /L %%H in (1,1,100) do (
    for %%i in ("%~dpn1\*.png") do (
          FOR /f "DELIMS=" %%A IN ('%timer% %IMcon% "%%i" -sampling-factor 2x2 -quality %%H "%TEMP%\%%~ni_libjpeg_yuv420_q%%H.jpg"') DO SET msec=%%A
          call :ssim "%%i" "%TEMP%\%%~ni_libjpeg_yuv420_q%%H.jpg" "%TEMP%\%%~ni_libjpeg_yuv420_q%%H.jpg" libjpeg q%%H
    )
   for %%c in ("%~dp1%InputFolder%_libjpeg*.csv") do echo. >>"%%c"
)
exit /b

:mozjpeg
for /L %%H in (1,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      if not exist "%TEMP%\%%~ni_mozjpeg_yuv420_temp.tga" magick convert "%%i" "%TEMP%\%%~ni_mozjpeg_yuv420_temp.tga"
      FOR /f "DELIMS=" %%A IN ('%timer% %mozjpeg% -targa  -tune-ssim -q %%H -sample 2x2 -outfile "%TEMP%\%%~ni_mozjpeg_yuv420_q%%H.jpg" "%TEMP%\%%~ni_mozjpeg_yuv420_temp.tga"') DO SET msec=%%A
      call :ssim "%%i" "%TEMP%\%%~ni_mozjpeg_yuv420_q%%H.jpg" "%TEMP%\%%~ni_mozjpeg_yuv420_q%%H.jpg" mozjpeg q%%
   )
   for %%t in ("%~dpn1\*.tga") do del "%%t"
   for %%c in ("%~dp1%InputFolder%_mozjpeg*.csv") do echo. >>"%%c"
)
exit /b

:guetzli
for /L %%H in (84,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %guetzli% --quality %%H "%%i" "%TEMP%\%%~ni_guetzli_yuv420_q%%H.jpg"') DO SET msec=%%A
      pause
      call :ssim "%%i" "%TEMP%\%%~ni_guetzli_yuv420_q%%H.jpg" "%TEMP%\%%~ni_guetzli_yuv420_q%%H.jpg" guetzli q%%H
   )
   for %%c in ("%~dp1%InputFolder%_guetzli*.csv") do echo. >>"%%c"
)
exit /b

:JPEG_2000
for /L %%H in (100,-1,1) do (
   for %%i in ("%~dpn1\*.png") do (
      set JPEG_2000_output="%TEMP%\%%~ni_j2k_yuv420_q%%H.j2k"
      set JPEG_2000_input_raw="%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.raw"
      set JPEG_2000_input="%%i"
      magick convert -strip "%%i" "%TEMP%\%%~ni_j2k_yuv420_temp.png"
      echo ImageSource^("%TEMP%\%%~ni_j2k_yuv420_temp.png",end=0^)>"%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.avs"
      echo ConvertToYV12^(matrix="PC.601",chromaresample="lanczos4"^)>>"%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.avs"
      %ffmpeg% -i "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.avs" -y -an -pix_fmt yuv420p "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.yuv"
      ren "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.yuv" %%~ni_j2k_yuv420_q%%H_temp.raw
      call :JPEG_2000_delayedexpansion %%H
      echo LWLibavVideoSource^("%TEMP%\%%~ni_j2k_yuv420_q%%H.j2k"^)>"%TEMP%\%%~ni_j2k_yuv420_q%%H_temp2.avs"
      echo ConvertToRGB24^(matrix="PC.601",chromaresample="lanczos4"^)>>"%TEMP%\%%~ni_j2k_yuv420_q%%H_temp2.avs"
      "%ffmpeg%" -i "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp2.avs" -y -an "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.png"
      call :ssim "%%i" "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_j2k_yuv420_q%%H.j2k" JPEG_2000 q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.png"
      del "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.avs"
      del "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp2.avs"
      del "%TEMP%\%%~ni_j2k_yuv420_q%%H_temp.raw"
      del "%TEMP%\%%~ni_j2k_yuv420_q%%H.j2k.lwi
      del "%TEMP%\%%~ni_j2k_yuv420_temp.png"
   )
   for %%c in ("%~dp1%InputFolder%_JPEG_2000*.csv") do echo. >>"%%c"
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
      if not exist "%TEMP%\%%~ni_jxr_yuv420_temp.bmp" "%IMcon%" "%%i" "%TEMP%\%%~ni_jxr_yuv420_temp.bmp"
      FOR /f "DELIMS=" %%A IN ('%timer% %JXR_dir%JXREncApp.exe -i "%TEMP%\%%~ni_jxr_yuv420_temp.bmp" -q %%H -d 1 -o "%TEMP%\%%~ni_jxr_yuv420_q%%H.jxr"') DO SET msec=%%A
      "%JXR_dir%JXRDecApp.exe" -i "%TEMP%\%%~ni_jxr_yuv420_q%%H.jxr" -o "%TEMP%\%%~ni_jxr_yuv420_q%%H.bmp"
      magick convert "%TEMP%\%%~ni_jxr_yuv420_q%%H.bmp" "%TEMP%\%%~ni_jxr_yuv420_q%%H.png"
      call :ssim "%%i" "%TEMP%\%%~ni_jxr_yuv420_q%%H.png" "%TEMP%\%%~ni_jxr_yuv420_q%%H.jxr" JPEG_XR q%%H
      del "%TEMP%\%%~ni_jxr_yuv420_q%%H.bmp"
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_jxr_yuv420_q%%H.png
      del "%TEMP%\%%~ni_jxr_yuv420_temp.bmp"
   )
   for %%c in ("%~dp1%InputFolder%_JPEG_XR*.csv") do echo. >>"%%c"
)
exit /b

:vp9
for /L %%H in (63,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% "%ffmpeg%" -y -i "%%~i" -vf scale^=out_color_matrix^=bt601:out_range^=pc:flags^=+accurate_rnd -an -pix_fmt yuvj420p -r 1 -vcodec vp9 -b:v 0 -qmin %%H -qmax %%H -threads 8 -an "%TEMP%\%%~ni_vp9_yuv420_q%%H.mkv"') DO SET msec=%%A
      %mkvextract% --ui-language en tracks "%TEMP%\%%~ni_vp9_yuv420_q%%H.mkv" 0:"%TEMP%\%%~ni_vp9_yuv420_q%%H.ivf"
      "%ffmpeg%" -y -i "%TEMP%\%%~ni_vp9_yuv420_q%%H.ivf" -vf scale=in_color_matrix=bt601:in_range=pc:flags=+accurate_rnd -an "%TEMP%\%%~ni_vp9_yuv420_q%%H_temp.png"
      call :ssim "%%i" "%TEMP%\%%~ni_vp9_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_vp9_yuv420_q%%H.ivf" vp9 q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_vp9_yuv420_q%%H_temp.png"
   )
   for %%c in ("%~dp1%InputFolder%_vp9*.csv") do echo. >>"%%c"
)
exit /b

:x264
for /L %%H in (52,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      echo ImageSource^("%%i",end=0^)>"%TEMP%\%%~ni_x264_yuv420_q%%H_temp.avs"
      echo ConvertToYV12^(matrix="PC.601"^)>>"%TEMP%\%%~ni_x264_yuv420_q%%H_temp.avs"
      FOR /f "DELIMS=" %%A IN ('%timer% %ffmpeg% -i "%TEMP%\%%~ni_x264_yuv420_q%%H_temp.avs" -y -r 1 -vcodec libx264 -crf %%H -threads 4 -an "%TEMP%\%%~ni_x264_yuv420_q%%H.h264"') DO SET msec=%%A
      echo LWLibavVideoSource^("%TEMP%\%%~ni_x264_yuv420_q%%H.h264"^)>"%TEMP%\%%~ni_x264_yuv420_q%%H_temp2.avs"
      echo ConvertToRGB24^(matrix="PC.601"^)>>"%TEMP%\%%~ni_x264_yuv420_q%%H_temp2.avs"
      "%ffmpeg%" -i "%TEMP%\%%~ni_x264_yuv420_q%%H_temp2.avs" -y -an "%TEMP%\%%~ni_x264_yuv420_q%%H_temp.png"
      call :ssim "%%i" "%TEMP%\%%~ni_x264_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_x264_yuv420_q%%H.h264" x264 q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_x264_yuv420_q%%H_temp.png"
      del "%TEMP%\%%~ni_x264_yuv420_q%%H_temp.avs"
      del "%TEMP%\%%~ni_x264_yuv420_q%%H_temp2.avs"
      del "%TEMP%\%%~ni_x264_yuv420_q%%H.h264.lwi"
      del "%TEMP%\%%~ni_x264_yuv420_q%%H.h264
   )
   for %%c in ("%~dp1%InputFolder%_x264*.csv") do echo. >>"%%c"
)
exit /b

:h264_qsv
for /L %%H in (52,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      echo ImageSource^("%%i",end=0^)>"%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp.avs"
      echo ConvertToYV12^(matrix="PC.601"^)>>"%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp.avs"
      FOR /f "DELIMS=" %%A IN ('%timer% %ffmpeg% -i "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp.avs" -y -r 1 -vcodec h264_qsv -q %%H -look_ahead 0 -an "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H.h264"') DO SET msec=%%A
      echo LWLibavVideoSource^("%TEMP%\%%~ni_h264_qsv_yuv420_q%%H.h264"^)>"%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp2.avs"
      echo ConvertToRGB24^(matrix="PC.601"^)>>"%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp2.avs"
      "%ffmpeg%" -i "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp2.avs" -y -an "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp.png"
      call :ssim "%%i" "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H.h264" h264_qsv q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp.png"
      del "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp.avs"
      del "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H_temp2.avs"
      del "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H.h264.lwi"
      del "%TEMP%\%%~ni_h264_qsv_yuv420_q%%H.h264"
   )
   for %%c in ("%~dp1%InputFolder%_h264_qsv*.csv") do echo. >>"%%c"
)
exit /b

:bpg
for /L %%H in (51,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %bpg_dir%bpgenc.exe -e x265 -m 9 -q %%H -f 420 -o "%TEMP%\%%~ni_bpg_yuv420_q%%H.bpg" "%%i"') DO SET msec=%%A
      "%bpg_dir%bpgdec.exe" -o "%TEMP%\%%~ni_bpg_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_bpg_yuv420_q%%H.bpg"
      call :ssim "%%i" "%TEMP%\%%~ni_bpg_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_bpg_yuv420_q%%H.bpg" bpg q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_bpg_yuv420_q%%H_temp.png
   )
   for %%c in ("%~dp1%InputFolder%_bpg*.csv") do echo. >>"%%c"
)
exit /b

:heif
for /L %%H in (51,-1,0) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% ffmpeg -y -framerate 1 -i "%%i" -pix_fmt yuv420p -vf "scale=out_color_matrix=smpte170m:out_range=pc:sws_flags=lanczos+accurate_rnd+bitexact+full_chroma_inp+full_chroma_int" -crf %%H -preset slower -x265-params "colormatrix=smpte170m:transfer=smpte170m:colorprim=smpte170m:range=full" -f hevc "%TEMP%\%%~ni_heif_yuv420_q%%H.h265"') DO SET msec=%%A
      MP4Box -add-image "%TEMP%\%%~ni_heif_yuv420_q%%H.h265":primary -ab heic -new "%TEMP%\%%~ni_heif_yuv420_q%%H.heic"
      chcp 932
      ffmpeg -i "%TEMP%\%%~ni_heif_yuv420_q%%H.h265" -sws_flags lanczos+accurate_rnd+bitexact+full_chroma_inp+full_chroma_int -pix_fmt rgb24 "%TEMP%\%%~ni_heif_ffmpeg_yuv420_q%%H.bmp"&&del "%TEMP%\%%~ni_heif_yuv420_q%%H.h265"
      rem "C:\Software\spibench-20170902\spibench.exe" -t 1 -b "%TEMP%\%%~ni_heif_yuv420_q%%H.bmp" -p high "C:\Software\MassiGra\iftwic.spi" "%TEMP%\%%~ni_heif_yuv420_q%%H.heic"
      rem call :ssim "%%i" "%TEMP%\%%~ni_heif_yuv420_q%%H.bmp" "%TEMP%\%%~ni_heif_yuv420_q%%H.heic" heif q%%H
      call :ssim "%%i" "%TEMP%\%%~ni_heif_ffmpeg_yuv420_q%%H.bmp" "%TEMP%\%%~ni_heif_yuv420_q%%H.heic" heif q%%H
   )
   for %%c in ("%~dp1%InputFolder%_heif*.csv") do echo. >>"%%c"
)
exit /b

:libaom_8bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      "%ffmpeg%" -y -i "%%~i" -vf scale=out_color_matrix=bt601:out_range=pc:flags=+accurate_rnd -r 1 -an -pix_fmt yuv420p -strict -1 "%TEMP%\%%~ni_libaom_8bit_yuv420_temp.y4m"
      FOR /f "DELIMS=" %%A IN ('%timer% "%libaom_dir%aomenc.exe" --ivf --bit-depth^=8 --input-bit-depth^=8 --full-still-picture-hdr --i420 --passes^=2 --tile-columns^=3 --threads^=8 --end-usage^=q --cq-level^=%%H -o "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H.ivf" "%TEMP%\%%~ni_libaom_8bit_yuv420_temp.y4m"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H.ivf" -o - | "%ffmpeg%" -y -i --vf scale=in_color_matrix=bt601:in_range=pc:flags=+accurate_rnd  -an "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H_temp.png"
      MP4Box -add-image "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H.ivf":primary -ab avif -ab miaf -new "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H.avif" libaom_8bit q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H_temp.png"
      del "%TEMP%\%%~ni_libaom_8bit_yuv420_temp.y4m"
      del "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H.ivf"
      del "%TEMP%\%%~ni_libaom_8bit_yuv420_q%%H.avif"
   )
   for %%c in ("%~dp1%InputFolder%_libaom_8bit*.csv") do echo. >>"%%c"
)
exit /b

:libaom_10bit
for /L %%H in (50,-2,0) do (
   for %%i in ("%~dpn1\*.png") do (
      "%ffmpeg%" -y -i "%%~i" -vf scale=out_color_matrix=bt601:out_range=tv:flags=+accurate_rnd -r 1 -an -pix_fmt yuv420p10le -strict -1 "%TEMP%\%%~ni_libaom_10bit_yuv420_temp.y4m"
      FOR /f "DELIMS=" %%A IN ('%timer% "%libaom_dir%aomenc.exe" --ivf --bit-depth^=10 --input-bit-depth^=10 --i420 --full-still-picture-hdr --passes^=2 --tile-columns^=3 --threads^=8 --end-usage^=q --cq-level^=%%H -o "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H.ivf" "%TEMP%\%%~ni_libaom_10bit_yuv420_temp.y4m"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H.ivf" -o - | "%ffmpeg%" -y -i -  -vf scale=in_color_matrix=bt601:in_range=tv:flags=+accurate_rnd  -an "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H_temp.png"
      MP4Box -add-image "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H.ivf":primary -ab avif -ab miaf -new "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H.avif" libaom_10bit q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H_temp.png"
      del "%TEMP%\%%~ni_libaom_10bit_yuv420_temp.y4m"
      del "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H.ivf"
      del "%TEMP%\%%~ni_libaom_10bit_yuv420_q%%H.avif"
   )
   for %%c in ("%~dp1%InputFolder%_libaom_10bit*.csv") do echo. >>"%%c"
)
exit /b

:rav1e
for /L %%H in (255,-10,5) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('ffmpeg -y -i "%%~i" -vf scale^=out_color_matrix^=bt601:out_range^=pc:flags^=+accurate_rnd -an -pix_fmt yuv420p -strict -1 -f yuv4mpegpipe - ^| timer64 "C:\Software\rav1e\rav1e.exe" --quantizer %%H  -s 0 - -o "%TEMP%\%%~ni_rav1e_yuv420_q%%H.ivf"') DO SET msec=%%A
      "%libaom_dir%aomdec.exe" "%TEMP%\%%~ni_rav1e_yuv420_q%%H.ivf" -o - | "%ffmpeg%" -i - -vf scale=in_color_matrix=bt601:in_range=pc:flags=+accurate_rnd -an "%TEMP%\%%~ni_rav1e_yuv420_q%%H_temp.png"
      MP4Box -add-image "%TEMP%\%%~ni_rav1e_yuv420_q%%H.ivf":primary -ab avif -ab miaf -new "%TEMP%\%%~ni_rav1e_yuv420_q%%H.avif"
      chcp 932
      call :ssim "%%i" "%TEMP%\%%~ni_rav1e_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_rav1e_yuv420_q%%H.avif" rav1e q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_rav1e_yuv420_q%%H_temp.png"
   )
   for %%c in ("%~dp1%InputFolder%_rav1e*.csv") do echo. >>"%%c"
)
exit /b

:webp
for /L %%H in (1,1,100) do (
    for %%i in ("%~dpn1\*.png") do (
          FOR /f "DELIMS=" %%A IN ('%timer% %IMcon% "%%i" -quality %%H "%TEMP%\%%~ni_webp_yuv420_q%%H.webp"') DO SET msec=%%A
          "%IMcon%" "%TEMP%\%%~ni_webp_yuv420_q%%H.webp" "%TEMP%\%%~ni_webp_yuv420_q%%H.png"
          call :ssim "%%i" "%TEMP%\%%~ni_webp_yuv420_q%%H.png" "%TEMP%\%%~ni_webp_yuv420_q%%H.webp" webp q%%H
          if "%refimage_del%"=="1" del "%TEMP%\%%~ni_webp_yuv420_q%%H.png"    )
   for %%c in ("%~dp1%InputFolder%_webp*.csv") do echo. >>"%%c"
)
for %%c in ("%~dp1%InputFolder%_webp*.csv") do echo. >>"%%c"

exit /b

:flif_lossy
for /L %%H in (1,1,100) do (
   for %%i in ("%~dpn1\*.png") do (
      FOR /f "DELIMS=" %%A IN ('%timer% %flif% -e -Q %%H %1 "%TEMP%\%%~ni_flif_yuv420_q%%H.flif"') DO SET msec=%%A
      "%flif%" -d "%TEMP%\%%~ni_flif_yuv420_q%%H.flif" "%TEMP%\%%~ni_flif_yuv420_q%%H_temp.png"
      call :ssim "%%i" "%TEMP%\%%~ni_flif_yuv420_q%%H_temp.png" "%TEMP%\%%~ni_flif_yuv420_q%%H.flif" flif q%%H
      if "%refimage_del%"=="1" del "%TEMP%\%%~ni_flif_yuv420_q%%H_temp.png
   )
   for %%c in ("%~dp1%InputFolder%_flif*.csv") do echo. >>"%%c"
)
for %%c in ("%~dp1%InputFolder%_flif*.csv") do echo. >>"%%c"
exit /b

:end
exit /b

:ssim
setlocal

FOR /f "DELIMS=" %%A IN ('identify -format %%w "%~1"') DO SET orig_w=%%A
FOR /f "DELIMS=" %%A IN ('identify -format %%h "%~1"') DO SET orig_h=%%A


SET Filesize=%~z3

FOR /f "DELIMS=" %%A IN ('compare -metric SSIM "%~1" "%~2" NUL 2^>^&1') DO SET SSIM_RGB=%%A

:ffmpeg_label
echo ImageSource^("%~1",end=0^) >"%TEMP%\%~n1_yuv.avs"
echo ConvertToYV24(matrix="Rec601")>>"%TEMP%\%~n1_yuv.avs"
echo ImageSource^("%~2",end=0^) >"%TEMP%\%~n2_yuv.avs"
echo ConvertToYV24(matrix="Rec601")>>"%TEMP%\%~n2_yuv.avs"

FOR /f "DELIMS=" %%A IN ('ffmpeg -i "%TEMP%\%~n1_yuv.avs" -i "%TEMP%\%~n2_yuv.avs" -lavfi psnr -f null NUL 2^>^&1 ^| find "Parsed_psnr"') DO SET Parsed_psnr=%%A
if "%Parsed_psnr%"=="" goto ffmpeg_label
for /f "tokens=5" %%I in ("%Parsed_psnr%") do set PSNR_y=%%I
for /f "tokens=8" %%I in ("%Parsed_psnr%") do set PSNR_yuv=%%I
set PSNR_y=%PSNR_y:~2%
set PSNR_yuv=%PSNR_yuv:~8%

:ffmpeg_label2
FOR /f "DELIMS=" %%A IN ('ffmpeg -i "%TEMP%\%~n1_yuv.avs" -i "%TEMP%\%~n2_yuv.avs" -lavfi ssim -f null NUL 2^>^&1 ^| find "Parsed_ssim"') DO SET Parsed_ssim=%%A
if "%Parsed_ssim%"=="" goto ffmpeg_label2
for /f "tokens=5" %%I in ("%Parsed_ssim%") do set SSIM_y=%%I
for /f "tokens=11" %%I in ("%Parsed_ssim%") do set SSIM_yuv=%%I
set SSIM_y=%SSIM_y:~2%
set SSIM_yuv=%SSIM_yuv:~4%

del "%TEMP%\%~n1_yuv.avs"
del "%TEMP%\%~n2_yuv.avs

FOR /f "DELIMS=" %%A IN ('compare -metric PSNR "%~1" "%~2" NUL 2^>^&1') DO SET PSNR_RGB=%%A
if "%PSNR_RGB%"=="1.#INF" set PSNR_RGB=INF

echo WScript.Echo (%Filesize%*8)/(%orig_w%*%orig_h%)>"%TEMP%\%~n1_bpp.vbs"
FOR /f "DELIMS=" %%A IN ('cscript //nologo "%TEMP%\%~n1_bpp.vbs"') DO SET bpp_c=%%A
del "%TEMP%\%~n1_bpp.vbs"

if not "%butteraugli_set%"=="1" goto butteraugli_skip
pushd %butteraugli_dir%
FOR /f "DELIMS=" %%A IN ('%butteraugli_exe% "%~1" "%~2"') DO SET butteraugli=%%A
popd

:butteraugli_skip

SET /P X=%Filesize%,<NUL >>"%InputFolder%_%4_Filesize.csv"
SET /P X=%bpp_c%,<NUL >>"%InputFolder%_%4_bpp.csv"
SET /P X=%PSNR_y%,<NUL >>"%InputFolder%_%4_PSNR_y.csv"
SET /P X=%PSNR_yuv%,<NUL >>"%InputFolder%_%4_PSNR_yuv.csv"
SET /P X=%PSNR_RGB%,<NUL >>"%InputFolder%_%4_PSNR_RGB.csv"
SET /P X=%SSIM_RGB%,<NUL >>"%InputFolder%_%4_SSIM_RGB.csv"
SET /P X=%SSIM_y%,<NUL >>"%InputFolder%_%4_SSIM_y.csv"
SET /P X=%SSIM_yuv%,<NUL >>"%InputFolder%_%4_SSIM_yuv.csv"

if defined butteraugli SET /P X=%butteraugli%,<NUL >>"%InputFolder%_%4_butteraugli.csv"
SET /P X=%msec%,<NUL >>"%InputFolder%_%4_msec.csv"

endlocal
if "%image_del%"=="1" del %2
if "%image_del%"=="1" del %3
exit /b
