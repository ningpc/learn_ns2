# 该过程针对Collapse.tcl文件的输出文件(temp.tr)生成能供绘图工具直接使用的数据格式文件
proc append { infile datafile cbrs tcps } {
	set awkCode {
		{
		if ($1=="stop-time") {time = $2;}
		if ($3=="packet-size") {size[$2] = $4;}
		if ($3=="total_packets_acked") {
                 packets[$2]+=$4;
                 goodput[1]+=(packets[$2]*size[$2]*8)/1000.0
              }             
              if ($3=="total_packets_received") {
                 packets[$2]+=$4;
                 goodput[0]+=(packets[$2]*size[$2]*8)/1000.0
              }
              if($1=="cbrs:"&&$3=="tcps:") {
                if($2+$4==0)
                  cbr_fraction=0;
                else
                  cbr_fraction=$2/($2+$4);
              }
		if ($3=="arriving_pkts"&&time>0) { 
			if ($2<$cbrs) {
			  cbrrate += (($4*size[0]*8)/time)/1000.0
			}
                    if ($2==$cbrs-1) {
                       printf "%8.2f %8.2f %8.2f %8.2f\n",cbrrate, \
                       goodput[0]/time,goodput[1]/time,cbr_fraction
                    }
		}
		}
	} 
	exec awk $awkCode cbrs=$cbrs $infile >> $datafile
}

#该过程对append函数的输出文件进行操作，按照Xgraph绘图软件输入的格式重新组合，然后绘图

proc finish { } {
	global datafile psfile

	set awkCode1 { {printf "%8.2f %8.2f\n", $1, $1} }
	set awkCode2 { $2!=0.00 {printf "%8.2f %8.2f\n", $1, $2} }
	set awkCode3 { $3!=0.00 {printf "%8.2f %8.2f\n", $1, $3} }
	set awkCode4 { $2+$3!=0.00{printf "%8.2f %8.2f\n", $1, $2+$3} }
	# cbr arrival vs. cbr goodput
	exec awk $awkCode2 $datafile | sort -n > chart
	# cbr arrival vs. tcp goodput
	exec awk $awkCode3 $datafile | sort -n > chart1
	# cbr arrival vs. cbr arrival
	exec awk $awkCode1 $datafile | sort -n > chart2
	# cbr arrival vs. aggregate goodput
	exec awk $awkCode4 $datafile | sort -n > chart3

	set f [open temp.rands w]
	puts $f "TitleText: $psfile"
	puts $f "Device: Postscript" 

	puts $f \"UdpArrivals
	flush $f
	exec cat chart2 >@ $f
	flush $f


	puts $f \n"UdpGoodput
	flush $f
	exec cat chart >@ $f
	flush $f

	puts $f \n"TcpGoodput
	flush $f
	exec cat chart1 >@ $f
	flush $f

	puts $f \n"AggregateGoodput
	flush $f
	exec cat chart3 >@ $f
	flush $f

	close $f
	puts "Calling xgraph..."
	exec xgraph -bb -tk -m -x UdpArrivals -y GoodputKbps temp.rands &
	exit 0
}

