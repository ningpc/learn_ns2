#创建网络模拟对象
set ns [new Simulator]            ;#创建模拟器对象，每个模拟必须新建一个ns模拟器
#打开Trace文件记录模拟结果
set nf [open fast-recovery-out.nam w]
$ns namtrace-all $nf
set ftr [open fast-recovery-out.tr w]
$ns trace-all $ftr
#添加"finish"过程以关闭模拟器和Trace文件并启动Nam程序
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam fast-recovery-out.nam &   ;#"&"表示后台运行
    exit 0
}

#创建4个节点n0 ~ n4
foreach i "0 1 2 3" {
        set n$i [$ns node]
}
#创建节点间的链路,在n1 ~ n2之间设置一个带宽较小的链路
$ns duplex-link $n0 $n1 5Mb 20ms DropTail
$ns duplex-link $n1 $n2 0.5Mb 100ms DropTail
$ns duplex-link $n2 $n3 5Mb 20ms DropTail
#设置队列长度限制
$ns queue-limit $n1 $n2 5
#设置节点在Nam中的对齐方式
$ns duplex-link-op $n0 $n1 orient right
$ns duplex-link-op $n1 $n2 orient right
$ns duplex-link-op $n2 $n3 orient right
#设置队列在Nam中的显示方向
$ns duplex-link-op $n1 $n2 queuePos 0.5
#添加传输层TCP发送器Agent
set tcp [new Agent/TCP/Reno]
$ns attach-agent $n0 $tcp
#添加传输层TCP接收器Agent
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
#将收发两端连接起来
$ns connect $tcp $sink
#在连接好的TCP信道上增加业务流量，这里使用FTP
set ftp [new Application/FTP]
$ftp attach-agent $tcp
#设置监控变量，用于Nam演示时实时显示这些参数的值
$tcp set nam_tracevar_ true     ;#打开Nam的跟踪变量
$ns add-agent-trace $tcp tcp    ;#新增对TCP代理的跟踪并设置跟踪标签为"tcp"
$ns monitor-agent-trace $tcp    ;#监控跟踪对象
$tcp tracevar cwnd_             ;#设置需要监控的变量名，cwnd值
$tcp tracevar ssthresh_         ;#慢启动门限
$tcp tracevar maxseq_           ;#已发送的最大包序号
$tcp tracevar ack_              ;#已收到的最大确认序号
$tcp tracevar dupacks_          ;#重复ACK计数器
#设置标签、提示和调度模拟程序
$ns at 0.0 "$n0 label TCP"  ;#设置节点名字标签
$ns at 0.0 "$n3 label TCP"
$ns at 0.0 "$ns trace-annotate \"TCP Reno:Fast Recovery\"" ;#在演示窗口中输出信息
$ns at 0.1 "$ftp start"
$ns at 5.0 "$ftp stop"
$ns at 5.25 "finish"
#开始模拟
$ns run
