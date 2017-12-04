#文件名:example4.2.tcl         ;LAN模拟
set opt(tr) "out.tr"           ;#Trace文件名
set opt(namtr) "lantest.nam"   ;#Nam演示文件名
set opt(stop)  5               ;#定义运行时间
set opt(node)  8               ;#设定局域网中的节点数目
set opt(qszie) 100             ;#队列大小
set opt(bw)    10Mb            ;#局域网带宽
set opt(delay) 10ms            ;#时延
set opt(ll)    LL              ;#LL层协议
set opt(ifq)   Queue/DropTail  ;#队列类型
set opt(mac)   Mac/802_3       ;#MAC帧格式类型
set opt(chan)  Channel         ;#信道类型
set opt(tcp)   TCP/Reno        ;#TCP版本
set opt(sink)  TCPSink         ;#TCP接收器
set opt(app)   FTP             ;#应用层协议
#定义结束过程
proc finish {} {
    global ns opt trfd
    $ns flush-trace
    close $trfd
    exec nam lantest.nam &
    exit 0
}
#定义Trace过程
proc create-trace {} {
   global ns opt
   if [file exists $opt(tr)] {
      catch "exec rm -f $opt(tr) $opt(tr) -bw [glob $opt(tr) *]"
   }
   set trfd [open $opt(tr) w]
   $ns trace-all $trfd
   if {$opt(namtr)!=""} {
      $ns namtrace-all [open $opt(namtr) w]  
   }
   return $trfd
}
#定义LAN拓扑结果创建过程
proc create-topology {} {
    global ns opt
    global lan node source node0
    set num $opt(node)  ;#节点数目
    for {set i 0} {$i<$num} {incr i} {
    set node($i) [$ns node]    ;#建立LAN中的各个节点
    lappend nodelist $node($i) ;#将其加入到nodelist当中
    }
    #创建LanNode
    set lan [$ns newLan $nodelist $opt(bw) $opt(delay) \
    -llType $opt(ll) \
    -ifqType $opt(ifq) \
    -macType $opt(mac) \
    -chanType $opt(chan)]  ;#下面几个是参数args部分
   set node0 [$ns node]    ;#建立普通节点
   $ns duplex-link $node0 $node(0) 2Mb 2ms DropTail
   $ns duplex-link-op $node0 $node(0) orient right
}
##  主程序部分  ##
set ns [new Simulator]
set trfd [create-trace]    ;#设定trace
create-topology            ;#设定网络模拟拓扑
#创建三个TCP连接
set tcp0 [$ns create-connection TCP/Reno $node(7) TCPSink $node0 0]
$tcp0 set window_ 32
set ftp0 [$tcp0 attach-app FTP]
set tcp1 [$ns create-connection TCP/Reno $node(2) TCPSink $node0 0]
$tcp1 set window_ 32
set ftp1 [$tcp1 attach-app FTP]
set tcp2 [$ns create-connection TCP/Reno $node(4) TCPSink $node0 0]
$tcp2 set window_ 32
set ftp2 [$tcp1 attach-app FTP]
#调度运行
$ns at 0.0 "$ftp0 start"    ;#第一个数据发送
$ns at 0.0 "$ftp1 start"    ;#第二个数据发送
$ns at 0.0 "$ftp2 start"    ;#第三个数据发送
$ns at $opt(stop) "finish"
$ns run
