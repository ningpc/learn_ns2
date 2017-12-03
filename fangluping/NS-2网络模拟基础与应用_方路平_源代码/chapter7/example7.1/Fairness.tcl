#本小节研究的是TCP流与UDP流竞争瓶颈链路带宽时的公平性问题
#改变的参数主要有UDP的发送率从一个非常小的值线性增大
#画图部分在finish中事项

set datafile Fairness.data
#运行Fairness1.tcl文件中的代码
source Fairness1.tcl
#接收参数
set scheduling [lindex $argv 0]
set cbrs [lindex $argv 1]
set tcps [lindex $argv 2]
set type [lindex $argv 3]
#实验类型:若type值为//Collapse",则表明做的是拥塞崩溃实验(见7.1.3),
#否则做的是公平性实验
if {$type=="Collapse"} {
   set bandwidth 128Kb
} else {
   set bandwidth 10Mb
}
set singlefile temp.tr
set label $type.$scheduling.$cbrs.$tcps
set psfile Fairness.ps

#运行模拟,调用Collapse.tcl文件
proc run_sim {bandwidth scheduling cbrs tcps singlefile datafile i} {
     set interval [expr $cbrs *0.0$i]
     puts "ns Collapse.tcl simple $interval $bandwidth $scheduling $cbrs $tcps"
     exec ns Collapse.tcl simple $interval $bandwidth $scheduling $cbrs $tcps 
     append $singlefile $datafile $cbrs $tcps
}
#exec rm -f $datafile
#当interval=0.00008时，CBR发送速率10Mb/s
#当interval=0.0008时，CBR发送速率1Mb/s
#发送间隔从0.01到0.09
for {set i 1} {$i<9} {incr i 1} {
     run_sim  $bandwidth $scheduling $cbrs $tcps $singlefile $datafile 00$i
}
for {set i 1} {$i<9} {incr i 1} {
     run_sim  $bandwidth $scheduling $cbrs $tcps $singlefile $datafile $i
}
finish