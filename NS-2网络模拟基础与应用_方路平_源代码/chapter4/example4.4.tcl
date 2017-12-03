#文件名:example4.4.tcl         
#设定模拟使用的一些参数
set val(chan) Channel/WirelessChannel    ;#信道类型
set val(prop) Propagation/TwoRayGround   ;#无线传播模式
set val(netif) Phy/WirelessPhy           ;#网络接口模型
set val(mac)   Mac/802_11                ;#MAC类型
set val(ifq)   Queue/DropTail/PriQueue   ;#接口队列类型
set val(ll)    LL                        ;#逻辑链路层类型
set val(ant)   Antenna/OmniAntenna       ;#天线类型
set val(ifqlen) 50                       ;#接口队列最大长度
set val(nn)   3                          ;#移动节点的数目
set val(rp)   DSDV                       ;#路由协议
set val(x)    500                        ;#移动拓扑的宽度
set val(y)    400                        ;#移动拓扑的长度
set val(stop) 150                        ;#模拟时间
#初始化模拟参数和跟踪对象
set ns [new Simulator]
set tracefd [open simple.tr w]
set windowVsTime2 [open win.tr w]
set namtrace [open simwrls.nam w]
$ns trace-all $tracefd
$ns namtrace-all-wireless $namtrace $val(x) $val(y)
#创建移动拓扑
set topo [new Topography]
#设定移动场景范围
$topo load_flatgrid $val(x) $val(y)
set chan [new $val(chan)]
#创建God对象
create-god $val(nn)
#创建$val(nn)个移动节点并将它们连接到信道
$ns node-config -adhocRouting $val(rp) \
                -llType       $val(ll) \
                -macType      $val(mac) \
                -ifqType      $val(ifq) \
                -ifqLen       $val(ifqlen) \
                -antType      $val(ant) \
                -propType     $val(prop) \
                -phyType      $val(netif) \
                -channel      $chan \
                -topoInstance $topo \
                -agentTrace   ON \
                -routerTrace  ON \
                -macTrace     ON \
                -movementTrace ON 
#创建移动节点
for {set i 0} {$i < $val(nn)} {incr i} {
    set node_($i) [$ns node]
}

#设置移动节点的初始位置
$node_(0) set X_ 5.0        ;#设定节点0的初始位置(5,5,0)
$node_(0) set Y_ 5.0
$node_(0) set Z_ 0.0
$node_(1) set X_ 490.0      ;#设定节点1的初始位置(490,285,0)
$node_(1) set Y_ 285.0
$node_(1) set Z_ 0.0
$node_(2) set X_ 150.0      ;#设定节点2的初始位置(150,240,0)
$node_(2) set Y_ 240.0
$node_(2) set Z_ 0.0
#设定移动模式
#第10s 节点0以3.0m/s速度向（250,250,0）移动，其余类推
$ns at 10.0 "$node_(0) setdest 250.0 250.0 3.0"
$ns at 15.0 "$node_(1) setdest 45.0 285.0 5.0"
$ns at 110.0 "$node_(0) setdest 480.0 300.0 5.0"
#在节点node_(0)和node_(1)之间创建TCP连接
set tcp [new Agent/TCP/Newreno]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns attach-agent $node_(0) $tcp
$ns attach-agent $node_(1) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 10.0 "$ftp start"
#定义统计窗口大小的过程
proc plotWindow {tcpSource file} {
     global ns
     set time 0.01
     set now [$ns now]
     set cwnd [$tcpSource set cwnd_]
     puts $file "$now $cwnd"
     $ns at [expr $now+$time] "plotWindow $tcpSource $file"
}
$ns at 10.1 "plotWindow $tcp $windowVsTime2"
#设置在nam中移动节点显示的大小，否则，nam中无法显示节点
for {set i 0} {$i<$val(nn)} {incr i} {
  $ns initial_node_pos $node_($i) 30
}
#模拟结束后重设节点
for {set i 0} {$i<$val(nn)} {incr i} {
  $ns at $val(stop) "$node_($i) reset";
}
#调度整个模拟过程的运行
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at 150.01 "puts \"end simulation\";$ns halt"
proc stop {} {  
    global ns tracefd namtrace
    $ns flush-trace
    close $tracefd
    close $namtrace
 }
$ns run
