# Set working directory to that of script
script_dir = system("dirname ".ARG0)."/"
cd script_dir

# Output file format PNG
set term png

# Graph and dataset settings
set key autotitle columnhead
set datafile separator ','
set output plotfile
set xlabel "Number of UEs"
set ylabel "Cumulative Throughput"
set title plottitle

# Plot the curves
plot for [i = 2:*] plotdata using 1:i smooth cnorm
