#P77 measure-drop.awk

BEGIN {
	#程序初始化，设定一变量记录分组被丢弃的数目
	fsDrops=0;
	numFs=0;
}

{
	#将Trace文件中一条记录的各个字段赋值给新的变量
	action=$1;
	time=$2;
	node_1=$3;
	node_2=$4;
	src=$5;
	flow_id=$8;
	node_1_address=$9;
	node_2_address=$10;
	seq_no=$11;
	packet_id=$12;
	#统计从n1送出的分组数
	if(node_1==1 && node_2==2 && action=="+")
		numFs++;
	#统计flow_id为2，且被丢弃的分组
	if(flow_id==2 && action=="d")
		fsDrops++;
}

END {
	printf("number of packet sent:%d lost:%d\n",numFs,fsDrops);
	printf("the loss rate of packets is:%f\n",fsDrops/numFs);
}