set ns [new Simulator] 
set cir0       30000; # 设定策略用的参数CIR
set cir1       30000; # 同上
set pktSize    1000 ;#包大小
set NodeNb       20; # 设定源节点的数目
set NumberFlows 160 ; # 每个源节点上的数据流数目
set sduration   25; # 模拟持续时间

#定义NAM演示用数据流显示的颜色
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green
$ns color 4 Brown
$ns color 5 Yellow
$ns color 6 Black
#定义模拟结果记录文件                   
set Out [open Out.ns w];   # 该文件记录连接失败时的数据传输情况，具体结构见后
set Conn [open Conn.tr w]; # 该文件记录当前连接数
set tf   [open out.tr w];  # 跟踪Trace文件
$ns trace-all $tf    
set file2 [open out.nam w];# NAM跟踪文件
# $ns namtrace-all $file2 

#定义拓扑结构
set D    [$ns node]  ;#定义目的节点(节点0)
set Ed   [$ns node]  ;#定义边缘路由器节点（节点1）
set Core [$ns node]  ;#定义核心路由器节点(节点2)

#设定瓶颈链路，采用两条单项链路分别设定，不同方向采用不同的队列类型
set flink [$ns simplex-link $Core $Ed 10Mb 1ms dsRED/core] ;#核心路由器队列
$ns queue-limit  $Core $Ed  100
$ns simplex-link $Ed $Core 10Mb 1ms dsRED/edge             ;#边缘路由器队列
$ns duplex-link  $Ed   $D  10Mb   0.01ms DropTail          ;#边缘路由器与目的节点的链路

#生成其他20对业务源节点和边缘路由器节点
for {set j 1} {$j<=$NodeNb} { incr j } {
 set S($j) [$ns node]
 set E($j) [$ns node]
 $ns duplex-link  $S($j) $E($j)  6Mb   0.01ms DropTail    ;#源节点与边缘路由器的链路
 $ns simplex-link $E($j) $Core   6Mb   0.1ms dsRED/edge   ;#边缘到核心路由器的连接
 $ns simplex-link $Core  $E($j)  6Mb   0.1ms dsRED/core   ;#核心到边缘路由器的连接
 $ns queue-limit $S($j) $E($j) 100
}

#配置Diffserv参数
set qEdC    [[$ns link $Ed $Core] queue]                 ;#去边缘到核心路由器的队列实例并设定
$qEdC       meanPktSize 40                               ;#平均包大小
$qEdC   set numQueues_   1                               ;#物理队列数目
$qEdC    setNumPrec      2                               ;#虚拟队列数目
for {set j 1} {$j<=$NodeNb} { incr j } {
 #设定从目的节点到所有源节点的20条数据流所采用的策略
 $qEdC addPolicyEntry [$D id] [$S($j) id] TSW2CM 10 $cir0 0.02
}

$qEdC addPolicerEntry TSW2CM 10 11                        ;#设定从边缘到核心路由器链路队列所采用的策略
$qEdC addPHBEntry  10 0 0                                 ;#添加PHB表项
$qEdC addPHBEntry  11 0 1                                 ;#添加PHB表项
$qEdC configQ 0 0 10 30 0.1                               ;#设定该队列的参数
#上面五个参数分别是队列号、虚拟队列号、最小阈值minth、最大阈值maxth和maxp
$qEdC configQ 0 1 10 30 0.1                               ;#同上
#在模拟过程中输出策略和策略器表
$qEdC printPolicyTable                                    ;#输出策略表
$qEdC printPolicerTable                                   ;#输出策略器表
#对应地，设定从核心到边缘路由器节点链路队列所采用的策略
set qCEd    [[$ns link $Core $Ed] queue]                  ;#取队列实例
# set qCEd    [$flink queue]
$qCEd     meanPktSize $pktSize
$qCEd set numQueues_   1                                   ;#设定队列参数
$qCEd set NumPrec       2                                  ;#增加PHB表项
$qCEd addPHBEntry  10 0 0 
$qCEd addPHBEntry  11 0 1 
$qCEd setMREDMode RIO-D                                     ;#设定虚拟队列类型
$qCEd configQ 0 0 15 45  0.5 0.01                           ;#配置队列参数
$qCEd configQ 0 1 15 45  0.5 0.01

#同理，设定其他数据源节点相连的边缘路由器节点与核心节点线路的链路队列策略 
for {set j 1} {$j<=$NodeNb} { incr j } {
 set qEC($j) [[$ns link $E($j) $Core] queue]                ;#边缘到核心
 $qEC($j) meanPktSize $pktSize
 $qEC($j) set numQueues_   1
 $qEC($j) setNumPrec      2
 $qEC($j) addPolicyEntry [$S($j) id] [$D id] TSW2CM 10 $cir1 0.02
 $qEC($j) addPolicerEntry TSW2CM 10 11
 $qEC($j) addPHBEntry  10 0 0 
 $qEC($j) addPHBEntry  11 0 1 
# $qEC($j) configQ 0 0 20 40 0.02
 $qEC($j) configQ 0 0 10 20 0.1
 $qEC($j) configQ 0 1 10 20 0.1
#在模拟过程中输出策略和策略器表
$qEC($j) printPolicyTable
$qEC($j) printPolicerTable
#设定从核心到边缘路由器节点间链路队列的策略
 set qCE($j) [[$ns link $Core $E($j)] queue]
 $qCE($j) meanPktSize      40
 $qCE($j) set numQueues_   1
 $qCE($j) setNumPrec      2
 $qCE($j) addPHBEntry  10 0 0 
 $qCE($j) addPHBEntry  11 0 1 
# $qCE($j) configQ 0 0 20 40 0.02
 $qCE($j) configQ 0 0 10 20 0.1
 $qCE($j) configQ 0 1 10 20 0.1

}
#设定对数据流的监视选项
set monfile [open mon.tr w]         ;#监视文件
set fmon [$ns makeflowmon Fid]      ;#采用流标记创建一个数据流的监视对象
$ns attach-fmon $flink $fmon        ;#将监视对象与需要监视的链路关联
$fmon attach $monfile               ;#将监视记录文件与监视对象关联

#接下来创建TCP源、目的代理以及它们之间的连接
for {set i 1} {$i<=$NodeNb} { incr i } {
for {set j 1} {$j<=$NumberFlows} { incr j } {
set tcpsrc($i,$j) [new Agent/TCP/Newreno]  ;#创建TCP连接
set tcp_snk($i,$j) [new Agent/TCPSink]     ;#创建TCP接收者
set k [expr $i*1000 +$j];
$tcpsrc($i,$j) set fid_ $k                 ;#设定流标记fid
$tcpsrc($i,$j) set window_ 2000            ;#设定窗口大小
$ns attach-agent $S($i) $tcpsrc($i,$j)
$ns attach-agent $D $tcp_snk($i,$j)
$ns connect $tcpsrc($i,$j) $tcp_snk($i,$j) ;#连接源和目的代理
set ftp($i,$j) [$tcpsrc($i,$j) attach-source FTP];#在TCP连接中放置ftp业务数据
} }
# 准备一个随机数发生器
set rng1 [new RNG]
$rng1 seed 22

# 采用指数分布产生一个数据用于设定每个源节点的TCP传输时间间隔
set RV [new RandomVariable/Exponential]
$RV set avg_ 0.2
$RV use-rng $rng1 

# 采用Pareto模型产生一个随机数用于指定一个需要传输的文件大小
set RVSize [new RandomVariable/Pareto]
$RVSize set avg_ 10000 
$RVSize set shape_ 1.25
$RVSize use-rng $rng1
set t [$RVSize value]

# 设定传输开始时间和传送大小，会话的到达服从泊松过程
for {set i 1} {$i<=$NodeNb} { incr i } {
     set t [$ns now]
     for {set j 1} {$j<=$NumberFlows} { incr j } {
	 # 根据数据源及其流的属性设定下一次传输开始时间
	 $tcpsrc($i,$j) set sess $j
	 $tcpsrc($i,$j) set node $i
	 set t [expr $t + [$RV value]]  ;#产生随机时间
	 $tcpsrc($i,$j) set starts $t
         $tcpsrc($i,$j) set size [expr [$RVSize value]] ;#产生随机大小
  $ns at [$tcpsrc($i,$j) set starts] "$ftp($i,$j) send [$tcpsrc($i,$j) set size]" ;#调度传输
  $ns at [$tcpsrc($i,$j) set starts ] "countFlows $i 1" ;#数据流计数

}}
#初始化计数器
for {set j 1} {$j<=$NodeNb} { incr j } {
set Cnts($j) 0
}   

#定义一个每次连接终止时调用的过程 
Agent/TCP instproc done {} {                         ;#该过程为TCP代理的实例过程
global tcpsrc NodeNb NumberFlows ns RV ftp Out tcp_snk RVSize 
# 在$Out定义的文件中记录以下信息(每行包含) :     
# 节点、会话、开始时间、结束时间、持续时间、传输的包数、传输的字节数
# 重传字节数、吞吐量  
  set duration [expr [$ns now] - [$self set starts] ] 
  set i [$self set node] 
  set j [$self set sess] 
  set time [$ns now] 
  puts $Out "$i \t $j \t $time \t\
      $time \t $duration \t [$self set ndatapack_] \t\
      [$self set ndatabytes_] \t [$self set  nrexmitbytes_] \t\
      [expr [$self set ndatabytes_]/$duration ]"    
	  # 更新数据流的数目
      countFlows [$self set node] 0

}

#定义一个计算连接数目的递归过程，每0.2s将结果输出到$Conn定义的文件中
proc countFlows { ind sign } {
global Cnts Conn NodeNb
set ns [Simulator instance]
      if { $sign==0 } { set Cnts($ind) [expr $Cnts($ind) - 1] 
} elseif { $sign==1 } { set Cnts($ind) [expr $Cnts($ind) + 1] 
} else { 
  puts -nonewline $Conn "[$ns now] \t"
  set sum 0
  for {set j 1} {$j<=$NodeNb} { incr j } {
    puts -nonewline $Conn "$Cnts($j) \t"
    set sum [expr $sum + $Cnts($j)]
  }
  puts $Conn "$sum"
  puts $Conn ""
  $ns at [expr [$ns now] + 0.2] "countFlows 1 3"
puts "in count"
} }

#同样定义一个"finish"过程结束模拟
proc finish {} {
        global ns tf file2
        $ns flush-trace
        close $file2 
        exit 0
}         

$ns at 0.5 "countFlows 1 3"
$ns at [expr $sduration - 0.01] "$fmon dump"             ;#结束对队列的监视
$ns at [expr $sduration - 0.001] "$qCEd printStats"      ;#输出核心队列的统计数据
$ns at $sduration "finish"


$ns run


