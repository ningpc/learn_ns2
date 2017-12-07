#定义一些变量
set val(chan) Channel/WirelessChannel   ;#物理信道类型
set val(prop) Propagation/TwoRayGround  ;#设定无线传输模型
set val(netif) Phy/WirelessPhy          ;#网络接口模型
set val(mac)   Mac/802_11               ;#MAC层类型
set val(ifq)   Queue/DropTail/PriQueue  ;#接口队列类型
set val(ll)    LL                       ;#逻辑链路层类型
set val(ant)   Antenna/OmniAntenna      ;#天线模型
set val(x)     1000                     ;#设定拓扑范围
set val(y)     1000                     ;#设定拓扑范围
set val(cp)    ""                       ;#节点移动的模型文件
set val(sc)    ""
set val(ifqlen) 50                      ;#网络接口队列的大小
set val(nn)     3                       ;#靠靠靠
set val(seed)   0.0 
set val(stop)   1000.0                  ;#模拟的总时间
set val(tr)     exp.tr                  ;#设定Trace文件名
set val(rp)     DSDV                    ;#设定无线路由协议
set AgentTrace  ON
set RouterTrace ON
set MacTrace    OFF
#初始化全局变量
set ns [new Simulator]
$ns color 1 blue
$ns color 2 red
#打开Trace文件
$ns use-newtrace                        ;#使用新的Trace格式
set namfd [open nam-exp.tr w]
$ns namtrace-all-wireless $namfd $val(x) $val(y)
set tracefd [open $val(tr) w]
$ns trace-all $tracefd
#建立一个拓扑对象，一记录移动节点在拓扑内移动的情况
set topo [new Topography]
#拓扑的范围为1000m*1000m
$topo load_flatgrid $val(x) $val(y)
#创建物理信道对象
set chan [new $val(chan)]
#创建God对象
set god [create-god $val(nn)]
#设置移动节点的属性
$ns node-config -adhocRouting     $val(rp) \
                -llType           $val(ll) \
                -macType          $val(mac) \
                -ifqType          $val(ifq) \
                -ifqLen           $val(ifqlen) \
                -antType          $val(ant) \
                -propType         $val(prop) \
                -phyType          $val(netif) \
                -channel          $chan \
                -topoInstance      $topo \
                -agentTrace       ON \
                -routerTrace      ON \
                -macTrace         OFF \
                -movementTrace    OFF
for {set i 0} { $i < $val(nn)} {incr i} { ;#$val(nn)=3
             set node($i) [$ns node] ;#创建3个网络节点
             $node($i) random-motion 0 ;#节点不随机移动
}

#设定各移动节点的初始位置
#设定节点0的初始位置
$node(0) set X_ 350.0
$node(0) set Y_ 500.0
$node(0) set Z_ 0.0
#设定节点1的初始位置，1000*1000的场景，节点1位于中间
$node(1) set X_ 500.0
$node(1) set Y_ 500.0
$node(1) set Z_ 0.0
#设定节点2的初始位置
$node(2) set X_ 650.0
$node(2) set Y_ 500.0
$node(2) set Z_ 0.0
#在节点1和2之间最短的hop数为1
$god set-dist 1 2 1
#在节点0和2之间最短的hop数为2
$god set-dist 0 2 2
#在节点0和1之间最短的hop数为1
$god set-dist 0 1 1
set god [God instance]
#在模拟时间200s时，节点1开始从位置(500,500)移动到(500,900),速度为2.0 m/s
$ns at 200.0 "$node(1) setdest 500.0 900.0 2.0"
#在模拟时间500s时，节点1再从位置(500,900)移动到(500,100),速度为2.0 m/s
$ns at 500.0 "$node(1) setdest 500.0 100.0 2.0"
#在节点0和节点2建立一条CBR/UDP的连接，且在时间100s的时候开始传送
set udp(0) [new Agent/UDP]
$udp(0) set fid_ 1
$ns attach-agent $node(0) $udp(0)
set null(0) [new Agent/Null]
$ns attach-agent $node(0) $null(0)
set cbr(0) [new Application/Traffic/CBR]
$cbr(0) set packetSize_ 200
$cbr(0) set interval_ 2.0
$cbr(0) set random_ 1
$cbr(0) set maxpkts_ 10000
$cbr(0) attach-agent $udp(0)
$ns connect $udp(0) $null(0)
$ns at 100.0 "$cbr(0) start"
#在Nam中定义节点初始大小
for {set i 0} {$i < $val(nn)} {incr i} {
                   #只有定义了移动模型后，这个函数才能被调用
                   $ns initial_node_pos $node($i) 60
}

#定义节点模拟的结束时间
for {set i 0} {$i < $val(nn)} {incr i} {
                   $ns at $val(stop) "$node($i) reset"
}

$ns at $val(stop) "stop" ;#$val(stop)模拟时间结束，调用stop函数
$ns at $val(stop) "puts \"NS EXITING...\";$ns halt"
proc stop {} {
   global ns tracefd namfd
   $ns flush-trace
   close $tracefd
   close $namfd
}
puts $tracefd "M 0.0 nn $val(nn) x $val(x) rp $val(rp)" ;#写入节点数、模拟场景大小、路由协议routing protocol
puts $tracefd "M 0.0 sc $val(sc) cp $val(cp) seed $val(seed)"
puts $tracefd "M 0.0 prop $val(prop) ant $val(ant)"
puts "Starting Simulation..."
$ns run
