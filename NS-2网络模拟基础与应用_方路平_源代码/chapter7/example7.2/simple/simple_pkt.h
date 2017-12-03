#ifndef __simple_pkt_h__

#define __simple_pkt_h__

#include <packet.h>

#define HDR_SIMPLE_PKT(p) hdr_simple_pkt::access(p)
//定义simple协议的分组头结构

struct hdr_simple_pkt {

    nsaddr_t pkt_src_; // 生成此分组的节点地址

    u_int16_t pkt_len_; // 分组长度 (in bytes)

    u_int8_t pkt_seq_num_; // 分组序列号

	//返回相应的变量
    inline nsaddr_t& pkt_src() { return pkt_src_; }

    inline u_int16_t& pkt_len() { return pkt_len_; }

    inline u_int8_t& pkt_seq_num() { return pkt_seq_num_; }
	//静态变量offset_代表此分组头在分组中的偏移量

    static int offset_;

    inline static int& offset() { return offset_; }

   /* 通过access函数访问simple协议分组的分组头，该函数返回hdr_simple_pkt结构的指针*/
    inline static hdr_simple_pkt* access(const Packet* p) {

           return (hdr_simple_pkt*)p->access(offset_);

    }

};

#endif

