#include "simple_rtable.h"

#include "ip.h"

simple_rtable::simple_rtable() { }

//print()函数把节点的路由表内容输出到trace文件中
void simple_rtable::print(Trace* out) {

       sprintf(out->pt_->buffer(), "P\tdest\tnext");

       out->pt_->dump();

      for (rtable_t::iterator it = rt_.begin(); it != rt_.end(); it++) {

             sprintf(out->pt_->buffer(), "P\t%d\t%d", (*it).first, (*it).second);

             out->pt_->dump();

      }

}

//clear()函数移除路由表的所有信息
void simple_rtable::clear() {

       rt_.clear();

}

//rm_entry()函数以一个目标地址为参数，删除对应的路由表项
void simple_rtable::rm_entry(nsaddr_t dest) {

       rt_.erase(dest);

}

//add_entry()函数以目标地址和下一跳地址为参数在路由表中添加一项
void simple_rtable::add_entry(nsaddr_t dest, nsaddr_t next) {

       rt_[dest] = next;

}

//lookup()函数以目标地址为参数，返回对应项的下一跳地址。如果不存在对应
//项,则返回IP_BROADCAST。
nsaddr_t simple_rtable::lookup(nsaddr_t dest) {

       rtable_t::iterator it = rt_.find(dest);

       if (it == rt_.end())

              return IP_BROADCAST;

       else

              return (*it).second;

}

//size()函数返回路由表项数
u_int32_t simple_rtable::size() {

       return rt_.size();

}

