#这个文件实现了实验要求的场景配置，参数设置并生成供进一步分析的输出文件
source setRed.tcl    ;#首先执行setRed.tcl文件中的内容
#set packetsize 512 
set packetsize 1500
#该过程创建一个简单的包含6个节点的网络拓扑，返回路由器r1到r2的link对象
proc create_testnet5 {queuetype bandwidth} {
        global ns s1 s2 r1 r2 s3 s4
        set s1 [$ns node]
        set s2 [$ns node]
        set r1 [$ns node]
        set r2 [$ns node]
        set s3 [$ns node]
        set s4 [$ns node]
        $ns duplex-link $s1 $r1 10Mb 2ms DropTail
        $ns duplex-link $s2 $r1 10Mb 3ms DropTail
        $ns duplex-link $s3 $r2 10Mb 10ms DropTail
        $ns duplex-link $s4 $r2  $bandwidth 5ms DropTail
        #queuetype决定，值为RED或CBQ/WRR
        $ns simplex-link $r1 $r2 1.5Mb 3ms $queuetype
        $ns simplex-link $r2 $r1 1.5Mb 3ms DropTail
        set redlink [$ns link $r1 $r2]
        [[$ns link $r2 $r1] queue] set limit_ 100
        [[$ns link $r1 $r2] queue] set limit_ 100
        return $redlink
}
#创建队列类型对象，设置对象属性
#注意队列对象与队列类型对象的不同
proc make_queue {cl qt qlim} {  ;#CBQClass queuetype qlimit
         set q [new Queue/$qt]
         $q set limit_ $qlim
         $cl install-queue $q
}
#配置CBQ/WRR对象参数，并将该对象插入瓶颈链路中
proc create_flat {link qtype qlim number} {
        set topclass_ [new CBQClass]
        $topclass_ setparams none 0 0.98 auto 8 2 0
        #将CBQClass对象插入link对象
        $link insert $topclass_
        set share [expr 100./$number]
        for {set i 0} {$i<$number} {incr i 1} {
                set cls [new CBQClass]
                $cls setparams $topclass_ true .$share auto 1 1 0
                make_queue $cls $qtype $qlim
                $link insert $cls  ;#CBQ/WRR对象插入链路
                $link bind $cls $i
        }
}
# 该过程创建了一个流监控器，并把它附加在瓶颈链路redlink上，流统计信息放入文件
#data.f中，dump命令转储流监控内容到Tcl通道。
proc create_flowstats {redlink stoptime } {
        global ns r1 r2 r1fm flowfile
        #检查文件data.f句柄赋给变量flowfile,下面对文件的操作就是对变量flowfile的操作
        set flowfile data.f
        set r1fm [$ns makeflowmon Fid] ;#创建一个流监视器对象
        set flowdesc [open $flowfile w] 
        $r1fm attach $flowdesc          ;#将监测记录文件与监测器对象相关联
        $ns attach-fmon $redlink $r1fm  ;#将监测对象瓶颈链路redlink关联
        $ns at $stoptime "$r1fm dump;close $flowdesc"
}
#该过程的主要功能是创建节点间的TCP或UDP连接
#该过程最终被new_cbr和new_tcp 调用，通过传入不同的参数分别创建
#s2与s4的UDP连接和s1与s3的连接
proc create-connection-list {s_type source d_type dest pktClass} {
     global ns
     set s_agent [new Agent/UDP]
     set d_agent [new Agent/$d_type]
     $s_agent set fid_ $pktClass
     $d_agent set fid_ $pktClass
     $ns attach-agent $source $s_agent
     $ns attach-agent $dest $d_agent
     $ns connect $s_agent $d_agent
     set cbr [new Application/Traffic/$s_type]
     $cbr attach-agent $s_agent
     return [list $cbr $d_agent] 
}
# new_cbr过程创建了一个CBR源端/目的端应用并为其创建调度
# 使用LossMonitor不仅用于流量的接收，同时也对接收的数据进行统计，如接收比特数、丢失分组数等。
proc new_cbr { startTime source dest pktSize fid dump interval file stoptime } {
        global ns
        set cbrboth [create-connection-list CBR $source LossMonitor $dest $fid]
        set cbr [lindex $cbrboth 0]
        $cbr set packetSize_ $pktSize
        $cbr set interval_ $interval
        set cbrsnk [lindex $cbrboth 1]
        $ns at $startTime "$cbr start"
	if {$dump == 1 } {
              #向输出文件写入关于分组大小的信息
		puts $file "fid $fid packet-size $pktSize"
		$ns at $stoptime "printCbrPkts $cbrsnk $fid $file"
	}
} 

#
#new_tcp过程创建了一个CBR源端/目的端应用并为其创建调度
proc new_tcp { startTime source dest window fid dump size file stoptime } {
        global ns
        #调用create-connection过程，创建TCP连接
        set tcp [$ns create-connection TCP/Sack1 $source TCPSink/Sack1/DelAck $dest $fid]
        #设定TCP连接的相关属性值
        $tcp set window_ $window
	 $tcp set tcpTick_ 0.01
        if {$size > 0}  {$tcp set packetSize_ $size }
        #创建FTP应用模拟器对象，并与源代理绑定
        set ftp [$tcp attach-source FTP]
        $ns at $startTime "$ftp start" ;#启动FTP应用模拟器
        #结束时，调用printTcpPkts过程输出相关数据到文件$file中，此过程在后面有介绍
        $ns at $stoptime "printTcpPkts $tcp $fid $file"
        #向输出文件写入关于分组大小的信息
        if {$dump == 1 } {puts $file "fid $fid packet-size [$tcp set packetSize_]"}
}
#过程printCbrPkts的定义，npkts_是LossMonitor对象的状态变量
#功能是向输出文件中写入每个UDP流收到的包
#输入参数:LossMonitor代理对象、UDP流标识号、输出文件句柄
proc printCbrPkts { cbrsnk fid file } {
        puts $file "fid $fid total_packets_received [$cbrsnk set npkts_]"
}
#过程printTcpPkts的定义，ack_是最高可见的ACK号码
#功能是向输出文件中写入每个TCP流的流标识号和最高可见的ACK号码（实际收到的不带重复的分组个数）
#输入参数:LossMonitor代理对象、UDP流标识号、输出文件句柄
proc printTcpPkts { tcp fid file } {
        puts $file "fid $fid total_packets_acked [$tcp set ack_]"
}
#模拟结束时，finish_ns 过程关闭输出文件
#模拟结束时，调用此函数
proc finish_ns {f} {
     global ns
     $ns instvar scheduler_
     $scheduler_ halt
     close $f
     puts "simulation complete"
}

#该过程用于对流监控的输出文件(data.f)进行分析，并将统计结果写入输出文件
#输入参数:输入文件、输出文件、CBR流的流数量和TCP流的流数量
# data.f中文件格式如下，共计17列:
# time fid($2) c=forced/unforced type class src dest pktA (即$8)byteA CpktD CbyteD
#    TpktA TbyteA TCpktD TCbyteD TpktD TbyteD pktD(即$18) byteD
# A:arrivals D:drops C:category(forced/unforced) T:totals 
#
# 输出格式: class # arriving_packets # dropped_packets # 
#即：流标识符#到达接收端的分组数目(可能包含重复)#丢弃的分组数目
#$8：此数据流到达接收节点的分组数 $18:此数据流丢弃的分组数，包括早期监测丢弃的分组数
proc finish_flowstats { infile outfile cbrs tcps} {
      set awkCode {
                #以下是awk代码
           BEGIN{
                #变量初始化操作,arrivals变量统计分组的到达数，drops变量统计分组的丢弃数
                arrivals=0;
                drops=0;
                prev=-1;
           }
           {
              if(prev==-1) {
                 arrivals+=$8;
                 drops+=$18;
                 prev=$2;
              }
              else if($2==prev){
                arrivals+=$8;
                drops+=$18;
              }
              else {
                 printf "class %d arriving_pkts %d dropped_pkts %d\n",prev,arrivals,drops;
                 prev=$2;
                 arrivals=$8
                 drops=$18;
              }
           }
          END{
            printf "class %d arriving_pkts %d dropped_pkts %d\n",prev,arrivals,drops;
         }
      }
     puts $outfile "cbrs: $cbrs tcps: $tcps"
    #在Tcl代码中执行$awkCode代表的awk代码，并将输出结果存入输出文件中
     exec awk $awkCode $infile >@ $outfile
}
#下面过程显示模拟中止时间
proc printstop { stoptime file } {
        puts $file "stop-time $stoptime"
}
#该过程通过调用前面的过程，按照给定参数创建并配置一个实验网络
#参数：CBR流发送频率、节点s4到r2的带宽、输出文件(temp.tr)、瓶颈链路队列调度算法、CBR流的个数、TCP流的个数
proc test_simple { interval bandwidth datafile scheduling cbrs tcps} {
	global ns s1 s2 r1 r2 s3 s4  flowfile packetsize
	set testname simple
	set stoptime 100.1
	set printtime 100.0
	set qtype RED
       set qlim 100
       #创建模拟器对象
       set ns [new Simulator]
       #根据不同的队列调度算法创建不同的链路，并设置队列对象参数
       if {$scheduling=="wrr"} {
           #调用create_testnet5过程创建网络拓扑，其中r1到r2链路的队列类型为CBQ/WRR
           set xlink [create_testnet5 CBQ/WRR $bandwidth]
           #调用create_flat过程设置CBQ/CRR对象的参数
           create_flat $xlink DropTail $qlim [expr $cbrs+$tcps]
       } elseif {$scheduling=="fifo"} {
           #调用create_testnet5过程创建网络拓扑，其中r1到r2链路的队列类型为RED
           set xlink [create_testnet5 RED $bandwidth]
           #调用set_Red_Oneway过程设置r1到r2链路参数
           set_Red_Oneway $r1 $r2
       }
	#在瓶颈链路上创建流监控对象
	create_flowstats $xlink $printtime
	set f [open $datafile w]
	$ns at $stoptime "printstop $printtime $f"
       #调用new_cbr过程和new_tcp过程创建CBR应用和TCP应用
       for {set i 0} {$i<$cbrs} {incr i 1} {
           new_cbr 1.4 $s2 $s4 100 $i 1 $interval $f $printtime
       }
       for {set i $cbrs} {$i<$cbrs+$tcps} {incr i 1} {
           new_tcp 0.0 $s1 $s3 100 $i 1 $packetsize $f $printtime
       }
       #模拟结束后分析输出结果，统计信息放入文件(data.f)中
       $ns at $stoptime "finish_flowstats $flowfile $f $cbrs $tcps"
       $ns at $stoptime "finish_ns $f"
	puts seed=[ns-random 0]
	$ns run
}

#该脚本文件的主程序，该脚本文件还要被其他脚本调用，调用格式为
#exec ns Collapse.tcl simple $interval $bandwidth $scheduling $cbrs $tcps
#输入参数个数错误，显示错误信息
if { $argc < 2 || $argc > 6} {
        puts stderr {usage: ns $argv [ arguments ]}
        exit 1
} elseif { $argc == 2 } {
        set testname [lindex $argv 0]
        set interval [lindex $argv 1] 
	set bandwidth 128Kb
	set datafile Collapse.tr
        puts "interval: $interval"
} elseif { $argc == 3 } {
        set testname [lindex $argv 0]
        set interval [lindex $argv 1] 
	set bandwidth [lindex $argv 2]
	set datafile Fairness.tr
        puts "interval: $interval"
} elseif { $argc == 6} {
        set testname [lindex $argv 0]
        set interval [lindex $argv 1] 
	set bandwidth [lindex $argv 2]
      set scheduling [lindex $argv 3]
            set cbrs [lindex $argv 4]
            set tcps [lindex $argv 5]
	set datafile temp.tr
      puts "interval: $interval"
}
if { "[info procs test_$testname]" != "test_$testname" } {
        puts stderr "$testname: no such test: $testname"
}
#调用过程test_simple
test_$testname $interval $bandwidth $datafile $scheduling $cbrs $tcps
#以上分析了Collapse.tcl的代码，其中定义了许多过程，这样做的好处是有利于代码
#的复用，节约了编程时间。在写比较复杂的Tcl脚本程序时，这种方法值得借鉴
