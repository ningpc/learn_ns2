#该文件的主要功能是设置r1到r2之间两条单向链路的相关属性
#流监控命令只能作用于单向链路
# 使用自定义set_Red_Oneway过程配置的RED参数
proc set_Red { node1 node2 } {
	set_Red_Oneway $node1 $node2
	set_Red_Oneway $node2 $node1
}

proc set_Red_Oneway { node1 node2 } {
        global ns
        [[$ns link $node1 $node2] queue] set mean_pktsize_ 1000 ;#分组大小的平均值
        [[$ns link $node1 $node2] queue] set bytes_ true        ;#开启字节模式
        [[$ns link $node1 $node2] queue] set wait_ false        ;#可以连续无间隔丢包
        [[$ns link $node1 $node2] queue] set maxthresh_ 20      ;#队列平均分组数的最大值
}

