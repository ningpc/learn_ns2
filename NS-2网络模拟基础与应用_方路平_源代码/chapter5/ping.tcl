# 产生一个模拟器

set ns [new Simulator]

# 设定颜色
$ns color 1 Blue

$ns color 2 Red

 # 打开一个nam  
set nf [open out.nam w]

$ns namtrace-all $nf


# 结束函数
   proc finish {} {
           global ns nf

           $ns flush-trace

           close $nf

           exec nam out.nam &

           exit 0

   }

# 建立三个节点
   set n0 [$ns node]

   set n1 [$ns node]

   set n2 [$ns node]


# 建立链路
   $ns duplex-link $n0 $n1 1Mb 10ms DropTail

   $ns duplex-link $n1 $n2 1Mb 10ms DropTail

# 设定节点位置

   $ns duplex-link-op $n0 $n1 orient right

   $ns duplex-link-op $n1 $n2 orient right



# =========================== RTT ================================

# Define a 'recv' function for the class 'Agent/Ping'

   Agent/Ping instproc recv {from rtt} {

    $self instvar node_

    puts "node [$node_ id] received ping answer from $from with round-trip-time $rtt ms."

   }

# =========================== RTT ================================

# 建立 Ping0 的 agent
   set p0 [new Agent/Ping]
# 设定颜色为蓝色
   $p0 set class_ 1
# n0-node 为 Ping 协议
   $ns attach-agent $n0 $p0


# 建立 Ping1 的 agent
   set p1 [new Agent/Ping]
# 设定颜色为红色
   $p1 set class_ 2
# n2-node 为 Ping 协议
   $ns attach-agent $n2 $p1


# 连接两个节点协议
   $ns connect $p0 $p1

# 建立事件发生时间
   $ns at 0.2 "$p0 send"

   $ns at 0.4 "$p1 send"

   $ns at 0.6 "$p0 send"

   $ns at 0.6 "$p1 send"

   $ns at 1.0 "finish"

# 开始运行
   $ns run