#文件名: example4.1a.tcl
#处理命令行参数部分：
if {$argc==4} {                  ;#如果命令行输入的参数数目为4，获取参数到各变量中。
#argc是OTcl的保留变量与C语言中常用的argc意思基本一致。
set bandwidth [lindex $argv 0]   ;#第一个参数为带宽(链路带宽)
set delay [lindex $argv 1]       ;#第二个参数为链路延迟
set window [lindex $argv 2]      ;#第三个参数为窗口大小
set time [lindex $argv 3]        ;#第四个参数为模拟时间
} else {                         ;#如果参数输入不正确，给出提示信息并退出
       puts "            bandwidth" 
       puts "  n0---------------------------n1"
       puts " TCP_window         delay" 
       puts "Usage: $argv0 bandwidth delay window simulation_time"    
}
#创建网络模拟对象
set ns [new Simulator]            ;#创建模拟器对象，每个模拟必须新建一个ns模拟器
#打开Trace文件记录模拟结果
set nf [open out.nam w]
$ns namtrace-all $nf
set ftr [open slidewin.tr w]
$ns trace-all $ftr
#添加"finish"过程以关闭模拟器和Trace文件并启动Nam程序
proc finish {} {
    global ns nf
    $ns flush-trace
    close $nf
    exec nam out.nam &          ;#"&"表示后台运行
    exit 0
}
#创建两个节点
set n0 [$ns node]
set n1 [$ns node]
#在两个节点间创建一条链路，用到命令行输入的参数
#     链路对象   起点 终点  链路带宽  链路延时 队列类型
$ns duplex-link  $n0  $n1  $bandwidth $delay   DropTail
#设定Nam中显示时链路、节点的初始位置、可不设
$ns duplex-link-op $n0  $n1  orient left-right
#创建TCP连接
set tcp [$ns create-connection TCP/RFC793edu $n0 TCPSink $n1 1]
#set tcp [$ns create-connection TCP/Reno $n0 TCPSink $n1 1]
#设置TCP连接的属性，如窗口大小、包大小等
$tcp set window_      $window
$tcp set ssthresh_    60
$tcp set packetSize_  500
#在该TCP连接上加上FTP的应用层业务数据
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP
#模拟时间调度
$ns at 0.5 "$ftp start" ;#0.5s时开始发送ftp数据流
$ns at $time "finish"
set f0 [open cwndrecNoss.tr w]  ;#打开记录文件
#set f0 [open cwndrec.tr w]     
proc Record {} {                ;#定义记录过程
     global f0 tcp ns           ;#声明全局变量
     set intval 0.1             ;#设定记录间隔时间
     set now [$ns now]          ;#获取当前ns时间
     set cwnd [$tcp set cwnd_]  ;#获取当前cwnd值
     puts $f0 "$now $cwnd"      ;#将时间点和cwnd值记录到文件中
     $ns at [expr $now + $intval] "Record" ;#定时调用记录过程
}
$ns at 0.1 "Record"             ;#ns首次调用Record过程
#开始模拟
$ns run
