#产生一个仿真的对象
set ns [new Simulator]
#针对不同的数据流定义不同的颜色，这事Nam显示时使用的
$ns color 1 blue
$ns color 2 red
#打开一个Nam Trace文件
set nf [open out.nam w]
$ns namtrace-all $nf
#打开一个Trace文件，用来记录分组传送的过程
set nd [open out.tr w]
$ns trace-all $nd
#定义一个结束的程序
proc finish {} {
     global ns nf nd
     $ns flush-trace
     close $nf
     close $nd
     exec nam out.nam &
     exit 0
}
#创建四个网络节点
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
#创建双向链路，把节点连接起来
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 1.7Mb 20ms DropTail
#设定n2到ns3之间队列大小为10个分组大小
$ns queue-limit $n2 $n3 10
#设定节点的位置，这是要给Nam用的
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n2 $n3 orient right
#观测n2到n3之间队列的变化，这是要给Nam用的
$ns duplex-link-op $n2 $n3 queuePos 0.5
#建立一条TCP的连接
set tcp [new Agent/TCP]
$tcp set class_ 2
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
#在NAM中，TCP的连接会以蓝色表示
$tcp set fid_ 1
#在TCP连接之上建立FTP应用程序
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP
#建立一条UDP的连接
set udp [new Agent/UDP]
$ns attach-agent $n1 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
#在Nam中,UDP的连接会以红色表示
$udp set fid_ 2
#在UDP连接之上建立CBR应用程序
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1mb
$cbr set random_ false
#设定FTP和CBR数据传送开始和结束时间
$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 4.0 "$ftp stop"
$ns at 4.5 "$cbr stop"
#在模拟环境中，5s后调用finish函数来结束模拟
$ns at 5.0 "finish"
#执行模拟
$ns run
