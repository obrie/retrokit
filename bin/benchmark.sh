sysbench --test=cpu --num-threads=4 run > pre-benchmark.txt
sysbench --test=cpu --num-threads=4 run > post-benchmark.txt
vcgencmd measure_temp
