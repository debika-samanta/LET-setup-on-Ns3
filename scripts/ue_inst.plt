# Set working directory to that of script
script_dir = system("dirname ".ARG0)."/"
cd script_dir

# Output format PNG
set term png

# Graph and dataset settings
set y2tics
set datafile separator ','
set datafile missing
set output plotfile
set xlabel "Time (ms)"
set ylabel "Throughput (Mbps)"
set y2label "SINR (dBm)"
set title plottitle
plot plotdata_thr using (1000*$1):plotcol w l title "Throughput", \
     plotdata_sinr every 7 using (1000*$1):(10*log10(column(plotcol))) w l title "SINR" axes x1y2