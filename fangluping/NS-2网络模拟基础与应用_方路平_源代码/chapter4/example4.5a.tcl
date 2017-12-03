#文件名:example4.5a.tcl;DropTail队列管理模拟 
#模拟前的准备工作，变量定义等
set ns [new Simulator]
set nf [open out.nam w]
$ns namtrace-all $nf
set tf [open out.tr w]
set windowVsTime [open win w]
set param [open parameters w]
$ns trace-all $tf
#定义一个'finsh'过程
proc finish {} {  
    global ns nf tf windowVsTime param
    $ns flush-trace
    close $nf
    close $tf
    close $windowVsTime
    close $param
    exec nam out.nam &
    exit 0
 }
#创建目的节点和瓶颈链路
set n2 [$ns node]
set n3 [$ns node]
$ns duplex-link $n2 $n3 0.7Mb 20ms DropTail       ;#标注1
set NumbSrc 3                                     ;#设定数据源节点的数目
set Duration 50                                   ;#设定模拟周期时间
#创建源节点
for {set j 1} {$j<=$NumbSrc} {incr j} {
set S($j) [$ns node]
}
#创建一个随机数发生器，用于指定各源节点ftp数据发送时间和设定瓶颈链路时延
set rng [new RNG]                                 ;#创建一个随机数对象
$rng seed 2                                       ;#设定种子
#生成一个随机变量作为设定ftp开始时间的参数
set RVstart [new RandomVariable/Uniform]         ;#设定随机变量类型
$RVstart set min_ 0                              ;#设定最小值
$RVstart set max_ 7                              ;#设定最大值
$RVstart use-rng $rng                            ;#使用刚才使用的随机数对象和种子
#使用随机数来设定每个数据源的ftp开始时间
for {set i 1} {$i<=$NumbSrc} {incr i} {
  set startT($i) [expr [$RVstart value]]         ;#产生一个实际使用的随机数
  set dly($i) 1
  puts $param "startT($i) $startT($i) sec"                   ;#输出当前随机数的值
}
#创建源节点与瓶颈节点的链路
for {set j 1} {$j<=$NumbSrc} {incr j} {
  $ns duplex-link $S($j) $n2 10Mb $dly($j)ms DropTail ;#设定时延和队列类型
  $ns queue-limit $S($j) $n2 20                       ;#设定队列大小
}
#创建各节点在nam中的演示位置
$ns duplex-link-op $S(2) $n2 orient right
$ns duplex-link-op $n2 $n3 orient right
$ns duplex-link-op $n2 $S(1) orient left-up
$ns duplex-link-op $S(3) $n2 orient right-up
#将瓶颈链路的队列大小设定为100
$ns queue-limit $n2 $n3 100
#设定TCP Sources
for {set j 1} {$j<=$NumbSrc} {incr j} {
    set tcp_src($j) [new Agent/TCP/Reno]
    $tcp_src($j) set window_ 8000
}
#设定TCP Destinations
for {set j 1} {$j<=$NumbSrc} {incr j} {
    set tcp_src($j) [new Agent/TCP/Reno]
    $tcp_src($j) set window_ 8000 
}
#设定TCP Destinations
for {set j 1} {$j<=$NumbSrc} {incr j} {
    set tcp_snk($j) [new Agent/TCPSink]
}
#连接三条数据通路
for {set j 1} {$j<=$NumbSrc} {incr j} {
    $ns attach-agent $S($j) $tcp_src($j)
    $ns attach-agent $n3 $tcp_snk($j)
    $ns connect $tcp_src($j) $tcp_snk($j)
}
#产生FTP sources
for {set j 1} {$j<=$NumbSrc} {incr j} {
    set ftp($j) [$tcp_src($j) attach-source FTP]    
}
#设定TCP数据源的包大小
for {set j 1} {$j<=$NumbSrc} {incr j} {
    $tcp_src($j) set packetSize_ 552
}
#调度三个FTP源的发送和停止发送事件
for {set i 1} {$i<=$NumbSrc} {incr i} {
$ns at $startT($i) "$ftp($i) start"
$ns at $Duration "$ftp($i) stop"
} 
#定义一个绘制实时窗口大小的Tcl过程
proc plotWindow {tcpSource file k} {
    global ns NumbSrc
    set time 0.03                                           ;#设定取样时间间隔为0.03
    set now [$ns now]
    set cwnd [$tcpSource set cwnd_]                         ;#获取当前TCP窗口大小cwnd_
    if {$k==1} {
       puts -nonewline $file "$now\t$cwnd\t"              ;#第一个TCP源时，输出第一列、第二列
    } else {
       if {$k<$NumbSrc} {
       puts -nonewline $file "$cwnd\t"}               
   }
   if {$k==$NumbSrc} {                                      ;#最后一个TCP源时，文件中的记录换行
   puts -nonewline $file "$cwnd \n"}
   $ns at [expr $now+$time] "plotWindow $tcpSource $file $k" ;#定时递归调用自身
}
#绘制过程在0.1s时第一次调用，对每个TCP源都调用一次
for {set j  1} {$j<=$NumbSrc} {incr j} {
  $ns at 0.1 "plotWindow $tcp_src($j) $windowVsTime $j"
}
#打开队列跟踪文件并实时监视
$ns monitor-queue $n2 $n3 [open queue.tr w] 0.05            ;#标注2
[$ns link $n2 $n3] queue-sample-timeout
#调度整个模拟过程的运行
$ns at 0.0 "$n2 label n2"
$ns at 0.0 "$S(1) label S(1)"
$ns at 0.0 "$S(2) label S(2)"
$ns at 0.0 "$S(3) label S(3)"
$ns at [expr $Duration] "finish"
$ns run
