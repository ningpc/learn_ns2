#文件名:example4.3b.tcl         ;多播路由模拟
set ns [new Simulator]
$ns multicast
$ns color 1 Blue
$ns color 2 Red
set file1 [open out.tr w]
$ns trace-all $file1
set file2 [open out.nam w]
$ns namtrace-all $file2
proc finish {} {          ;#定义结束过程
    global ns file1 file2
    $ns flush-trace
    close $file1
    close $file2
    exec nam out.nam &
    exit 0
}
for {set i 1} {$i<7} {incr i} {
    set n($i) [$ns node]          ;#创建节点
}
$ns duplex-link $n(1) $n(2) 0.3Mb 10ms DropTail  ;#创建链路
$ns duplex-link $n(2) $n(3) 0.3Mb 10ms DropTail 
$ns duplex-link $n(3) $n(4) 0.3Mb 15ms DropTail
$ns duplex-link $n(2) $n(5) 0.3Mb 15ms DropTail
$ns duplex-link $n(2) $n(4) 0.3Mb 10ms DropTail
$ns duplex-link $n(4) $n(6) 0.3Mb 15ms DropTail
$ns duplex-link $n(4) $n(5) 0.3Mb 10ms DropTail
$ns duplex-link $n(5) $n(6) 0.3Mb 10ms DropTail

$ns duplex-link-op $n(1) $n(2) orient left-up
$ns duplex-link-op $n(2) $n(3) orient left-up
$ns duplex-link-op $n(3) $n(4) orient right-up
$ns duplex-link-op $n(2) $n(5) orient up-right
$ns duplex-link-op $n(2) $n(4) orient up
$ns duplex-link-op $n(4) $n(6) orient right-up
$ns duplex-link-op $n(5) $n(4) orient left-up
$ns duplex-link-op $n(5) $n(6) orient up

#分配一个多播组地址
set group [Node allocaddr]
#配置多播协议
DM set CacheMissMode dvmrp  ;#这里设定为dvmrp
set mproto DM
set mrthandle [$ns mrtproto $mproto]
#设定代理
set udp1 [new Agent/UDP]
set udp2 [new Agent/UDP]
$ns attach-agent $n(1) $udp1
$ns attach-agent $n(2) $udp2
#设定CBR流量并配置多播地址参数
set src1 [new Application/Traffic/CBR]
$src1 attach-agent $udp1
$udp1 set dst_addr_ $group
$udp1 set dst_port_ 0
$src1 set random_ false

set src2 [new Application/Traffic/CBR]
$src2 attach-agent $udp2
$udp2 set dst_addr_ $group
$udp2 set dst_port_ 1
$src2 set random_ false

#创建接收器代理
set rcvr [new Agent/LossMonitor]
#控制节点何时加入和离开多播组
$ns at 0.6 "$n(3) join-group $rcvr $group"
$ns at 1.3 "$n(4) join-group $rcvr $group"
$ns at 1.6 "$n(5) join-group $rcvr $group"
$ns at 1.9 "$n(4) leave-group $rcvr $group"
$ns at 2.3 "$n(6) join-group $rcvr $group"
$ns at 3.5 "$n(3) leave-group $rcvr $group"
$ns at 0.4 "$src1 start"
$ns at 2.0 "$src2 start"
$ns at 6.0 "finish"
$ns run
