#P79 measure-delay.awk

BEGIN {
	#程序初始化，设定一变量记录目前最高处理分组的ID
	highest_packet_id=0;
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
	
	#记录目前最高的分组ID
	if(packet_id > highest_packet_id)
		highest_packet_id=packet_id;
	#记录分组的传送时间
	if(start_time[packet_id] == 0)
		start_time[packet_id]=time;
	#记录CBR(flow_id=2)的接收时间
	if(flow_id==2 && action!="d")
	{
		if(action=="r")
		{
			end_time[packet_id]=time;
		}
	}
	else
	{
		#把不是flow_id=2的分组或者flow_id=2但此分组被drop的时间设为-1
		end_time[packet_time]=-1;
	}
}

END {
	#当输入数据全部读取完后，开始计算有效分组的端到端延迟
	for(packet_id=0;packet_id<=highest_packet_id;packet_id++)
	{
		start=start_time[packet_id];
		end=end_time[packet_id];
		packet_duration=end-start;
		#只把接收时间大于传送时间的记录列出来
		if(start<end) printf("%f %f\n",start,packet_duration);
	}
}
