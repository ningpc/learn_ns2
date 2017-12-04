#ifndef __simple_rtable_h__

#define __simple_rtable_h__

#include <trace.h>

#include <map>

typedef std::map<nsaddr_t, nsaddr_t> rtable_t;

//simple路由协议实现的路由表很简单，它仅仅存储了目的地址和下一跳地址信息，
//实现了基本的添加、删除路由信息等基本操作
//在这里使用了C++标准库的map数据结构，这样成员函数的实现就十分简单，只需要调用基本的map接口函数即可
class simple_rtable {

   rtable_t rt_;                            //路由表

   public:

   simple_rtable();                        //构造函数

   void print(Trace*);  
    
   void clear();                           //删除路由表的所有信息

   void rm_entry(nsaddr_t);                //删除对应的路由表项

   void add_entry(nsaddr_t, nsaddr_t);     //在路由表中添加一项

   nsaddr_t lookup(nsaddr_t);              //查找对应项的下一跳地址

   u_int32_t size();                       //返回路由表的项数

};

#endif

