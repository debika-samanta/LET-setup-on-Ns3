# Set working directory to that of script
script_dir = system("dirname ".ARG0)."/"
cd script_dir
set output '../figs/rem.png'
set term png
set view map
set xlabel "X"
set ylabel "Y"
set cblabel "SINR (dB)"
set title "Radio Environment Map (REM)"
plot "../data/rem.out" using ($1):($2):(10*log10($4)) with image title ""