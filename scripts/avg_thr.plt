# Set working directory to that of script
script_dir = system("dirname ".ARG0)."/"
cd script_dir

# Output file format is PNG
set term png

# Style for bar chart
set style data histogram
set style histogram cluster gap 1
set style fill solid

# Graph and dataset related settings
set key autotitle columnhead
set datafile separator ','
set output plotfile
set xlabel "Speed (m/s)"
set ylabel "Throughput (Mbps)"
set title plottitle

# Plot the histogram
plot for [i=2:*] plotdata using i:xtic(1)
