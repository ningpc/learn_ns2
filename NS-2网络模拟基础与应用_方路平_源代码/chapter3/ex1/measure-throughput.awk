#P79 measure-throughput.awk

BEGIN {
	init=0;
	i=0;
}

{
	#将Trace文件中一条记录的各个字段赋值给新的变量
	action=$1;
	time=$2;
	node_1=$3;
	node_2=$4;
	src=$5;
	pktsize=$6;
	flow_id=$8;
	node_1_address=$9;
	node_2_address=$10;
	seq_no=$11;
	packet_id=$12;

	#计算node_2从接收第一个分组的时间到当前时间内接收到的数据总量
	if(action=="r" && node_1==2 && node_2==3 && flow_id==2)
	{	
		pkt_byte_sum[i+1]=pkt_byte_sum[i]+pktsize;
		if(init==0)
			{
				start_time=time;
				init=1;
			}
		end_time[i]=time;
		i=i+1;
	}
}

END {
	#把第一条记录的throughput设为零，以表示传输开始
	printf("%.6f\t%.6f\n",end_time[0],0);
	#计算不同时刻的吞吐量
	for(j=1;j<i;j++)
	{
		th=pkt_byte_sum[j]/(end_time[j]-start_time)*8/1000;
		printf("%.6f\t%.6f\n",end_time[j],th);
	}
	#把最后一跳记录的throughput设为零，以表示传输结束
	printf("%.6f\t%.6f\n",end_time[i-1],0);
}