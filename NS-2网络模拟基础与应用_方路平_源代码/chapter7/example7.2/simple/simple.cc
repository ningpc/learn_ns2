#include "simple.h"

#include "simple_pkt.h"

#include <random.h>

#include <cmu-trace.h>

#include <iostream>

int HDR_SIMPLE_PKT::offset_;

static class SimpleHeaderClass : public PacketHeaderClass {

       public:

       simpleHeaderClass() : PacketHeaderClass("PacketHeader/Simple", sizeof(HDR_SIMPLE_PKT)) {

              bind_offset(&HDR_SIMPLE_PKT::offset_);

       }

} class_rtProtosimple_hdr;//要把分组头与OTcl接口绑定起来，在simple.cc中定义一个静态类


static class SimpleClass : public TclClass {

       public:

       simpleClass() : TclClass("Agent/Simple") {}

       TclObject* create(int argc, const char*const* argv) {

              assert(argc == 5);
              //创建C++Simple类的对象
              return (new Simple((nsaddr_t) Address::instance().str2addr(argv[4])));

       }

} class_rtProtosimple;

void Simple_PktTimer::expire(Event* e) {

      agent_->send_simple_pkt();         //一旦超时，便调用该函数发送Simple分组

      agent_->reset_simple_pkt_timer();  //重设定时器

}

Simple::Simple(nsaddr_t id) : Agent(PT_SIMPLE), pkt_timer_(this) {
      /*Agent/Simple类成员变量与C++ Simple类成员变量的绑定，其中在Agent/Simple类中变量 accessible_var_为布尔型*/
      bind_bool("accessible_var_", &accesible_var_);

      ra_addr_ = id;

}

int Simple::command(int argc, const char*const* argv) {

      if (argc == 2) {
             //启动simple代理的start OTcl命令实现
             if (strcasecmp(argv[1], "start") == 0) {

                    pkt_timer_.resched(0.0);

                    return TCL_OK;

             }
             //print_rtable命令实现，将路由表信息写入trace文件中
             else if (strcasecmp(argv[1], "print_rtable") == 0) {

                    if (logtarget_ != 0) {

                           sprintf(logtarget_->pt_->buffer(), "P %f _%d_ Routing Table", CURRENT_TIME, ra_addr());

                           logtarget_->pt_->dump();

                           rtable_.print(logtarget_);

                    }

                    else {

                           fprintf(stdout, "%f _%d_ If you want to print this routing table,

                           you must create a trace file in your tcl script", CURRENT_TIME, ra_addr());

                    }

                    return TCL_OK;

             }

      }

       else if (argc == 3) {

      // 获得对应 dmux，把分组发送至高层

             if (strcmp(argv[1], "port-dmux") == 0) {

                    dmux_ = (PortClassifier*)TclObject::lookup(argv[2]);

                    if (dmux_ == 0) {

                           fprintf(stderr, "%s: %s lookup of %s failed\n", __FILE__, argv[1], argv[2]);

                      return TCL_ERROR;

                    }

                    return TCL_OK;

             }

             else if (strcmp(argv[1], "log-target") == 0 || strcmp(argv[1], "tracetarget") == 0) {

                    logtarget_ = (Trace*)TclObject::lookup(argv[2]);

                    if (logtarget_ == 0)

                           return TCL_ERROR;

                     return TCL_OK;

             }

      }

      // Pass the command to the base class

      return Agent::command(argc, argv);

}

void Simple::recv(Packet* p, Handler* h) {

       struct hdr_cmn* ch = HDR_CMN(p); //获取指向公共分组头的指针

       struct hdr_ip* ih = HDR_IP(p);   //获取指向IP分组头的指针
	   /*检查分组是否是Simple代理自己产生的分组，如果不是，则检查是否存在路由环路，如果
	   存在，则丢弃该分组;如果该分组是该代理自己产生的分组，将IP分组头加入该分组*/

       if (ih->saddr() == ra_addr()) {

             // 如果路由发生环路，则丢弃该分组

             if (ch->num_forwards() > 0) {

                    drop(p, DROP_RTR_ROUTE_LOOP);

                    return;

             }

             // 如果该分组是该代理自己产生的分组，将IP分组头加入该分组

             else if (ch->num_forwards() == 0)

                    ch->size() += IP_HDR_LEN;      //#define IP_HDR_LEN      20   in <ip.h>

      }

       // 假设分组类型为协议Simple的分组，则调用recv_simple_pkt()函数进行处理

      if (ch->ptype() == PT_SIMPLE)

             recv_simple_pkt(p);

      // 否则，将对分组进行转发(除非TTL的值为0)

      else {

             ih->ttl_--;
			 //当TTL的值为0时，丢弃该分组
             if (ih->ttl_ == 0) {

                    drop(p, DROP_RTR_TTL);

                    return;

             }
             //否则转发该分组
             forward_data(p);

      }

}

void Simple::recv_simple_pkt(Packet* p) {

       struct hdr_ip* ih = HDR_IP(p); //获取指向IP分组头的指针
       //获取指向Simple分组头的指针
       struct hdr_simple_pkt* ph = HDR_SIMPLE_PKT(p);

       //确保分组发送方的端口和接收方端口都为Simple协议的端口号RT_PORT

      assert(ih->sport() == RT_PORT);

      assert(ih->dport() == RT_PORT);

       /* 对Simple分组的处理，这里只是简单地释放资源，如果要对Simple分组作别的操作，可以在这里添加相应的代码 */

      Packet::free(p);

}

void Simple::send_simple_pkt() {
      
      //为分组分配一个分组空间
      Packet* p = allocpkt();
      //分别获取common,IP和Simple分组头的指针
      struct hdr_cmn* ch = HDR_CMN(p);

      struct hdr_ip* ih = HDR_IP(p);

      struct hdr_simple_pkt* ph = HDR_SIMPLE_PKT(p);
	  //给Simple分组头的各项属性赋值，各项属性含义详见7.2.2

      ph->pkt_src() = ra_addr();

      ph->pkt_len() = 7;

      ph->pkt_seq_num() = seq_num_++;
	  //给common分组头的各项属性赋值，各项属性含义详见6.4.1

      ch->ptype() = PT_SIMPLE;

      ch->direction() = hdr_cmn::DOWN;

      ch->size() = IP_HDR_LEN + ph->pkt_len();

      ch->error() = 0;

      ch->next_hop() = IP_BROADCAST;

      ch->addr_type() = NS_AF_INET;

      //给IP分组头的各项属性赋值
      ih->saddr() = ra_addr();

      ih->daddr() = IP_BROADCAST;

      ih->sport() = RT_PORT;

      ih->dport() = RT_PORT;

      ih->ttl() = IP_DEF_TTL;

      Scheduler::instance().schedule(target_, p, JITTER);

}

void Simple::reset_simple_pkt_timer() {
//调用定时器的成员函数resched()重置超时时间为5.0s,详细内容参看6.3节
       pkt_timer_.resched((double)5.0);

}

void Simple::forward_data(Packet* p) {
      //获取commom、IP分组头的指针

      struct hdr_cmn* ch = HDR_CMN(p);

      struct hdr_ip* ih = HDR_IP(p);
	  //如果数据分组的目的地址是本节点，则通过端口分类器传给上层应用代理

      if (ch->direction() == hdr_cmn::UP &&

          ((u_int32_t)ih->daddr() == IP_BROADCAST || ih->daddr() == ra_addr())) {

          dmux_->recv(p, 0);

          return;

     }

     else {

         ch->direction() = hdr_cmn::DOWN;

         ch->addr_type() = NS_AF_INET;
		 /*如果目的地址是广播地址，将分组common头部的下一跳地址赋为IP_BROADCAST*/

         if ((u_int32_t)ih->daddr() == IP_BROADCAST)

             ch->next_hop() = IP_BROADCAST;
			 //否则,从路由表中查找下一跳地址

         else {
		        /*调用simple_rtable的成员函数lookup()查找下一跳地址，rtable_为simple_rtable类对象，后面有详细介绍*/

             nsaddr_t next_hop = rtable_.lookup(ih->daddr());

             if (next_hop == IP_BROADCAST) {

                 debug("%f: Agent %d can not forward a packet destined to %d\n",

                     CURRENT_TIME,

                     ra_addr(),

                     ih->daddr());

                 drop(p, DROP_RTR_NO_ROUTE);

                 return;

             }

             else

                 ch->next_hop() = next_hop;

         }

         Scheduler::instance().schedule(target_, p, 0.0);

     }

}

