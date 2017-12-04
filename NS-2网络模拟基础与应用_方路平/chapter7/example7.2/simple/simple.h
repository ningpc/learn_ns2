#ifndef __simple_h__

#define __simple_h__

// 下面包含一些需要的头文件

#include "simple_pkt.h" //数据包报头

#include "simple_rtable.h" 

#include <agent.h>  //代理基本类

#include <packet.h> //数据包类

#include <trace.h> //跟踪类，用于在跟踪文件里记录输出的仿真结果

#include <timer-handler.h> //计时器基本类，创建我们自定义的计时器

#include <random.h> //随机类，用于产生伪随机数

#include <classifier-port.h> //端口分类器类，用于淘汰向上层传输的数据包

#include <mobilenode.h>

#include "arp.h"

#include "ll.h"

#include "mac.h"

#include "ip.h"

#include "delay.h"

#define CURRENT_TIME Scheduler::instance().clock() //定义了一个用于得到当前仿真时间的宏

                                                                                      //通过一个调度类的实例完成

#define JITTER (Random::uniform()*0.5) //在0-0.5之间去随机数作为发送数据的延迟时间




class Simple_PktTimer;

//定义Simple 类的定义
class Simple : public Agent {


//友元类

friend class Simple_PktTimer;

/* Private members */ //封装了自身的地址、内状态、路由表、可变的Tcl

//定义私有成员变量和函数
protected:                                    //以及一个负责指定输出数量的计数器

nsaddr_t ra_addr_;      //自身地址

simple_state state_;    //内部状态变量

simple_rtable rtable_;  //路由表对象，simple_rtable类在7.2.3中详细介绍

int accesible_var_;     //在OTcl中可以访问的变量

u_int8_t seq_num_;      //计数器变量，用来把序列号赋给输出分组



MobileNode* node_; 
/*PortClassifier对象的指针dmux_,该Agent收到属于自己的数据分组，它将使用dmux_来把这个分
组传递给高层的应用*/

PortClassifier* dmux_; 
//定义了一个Trace对象的指针，用来把模拟过程中的路由表信息记录到跟踪文件中。
Trace* logtarget_; 
//用来创建一个发送simple分组的定时器对象
simple_PktTimer pkt_timer_;

//内联函数返回成员变量的值

inline nsaddr_t& ra_addr() { return ra_addr_; }

inline simple_state& state() { return state_; }

inline int& accessible_var() { return accesible_var_; }

//转发分组成员函数
void forward_data(Packet*); 
//当接收到分组为simple分组时，处理simple分组的成员函数
void recv_simple_pkt(Packet*);
//发送simple分组函数
void send_simple_pkt();
//调度定时器函数
void reset_simple_pkt_timer();


public: 


simple(nsaddr_t);   //构造函数

int command(int, const char*const*);

void recv(Packet*, Handler*); //收到数据分组时，处理数据分组成员函数

//void mac_failed(Packet*);


}; 

//Simple_PktTimer定时器类的定义
class Simple_PktTimer : public TimerHandler {

    public:

    //构造函数，调用基类的构造函数
    Simple_PktTimer(simple* agent) : TimerHandler() { 

    agent_ = agent;


    } 

    protected:


    Simple* agent_; 

    virtual void expire(Event* e);


}; 

#endif

