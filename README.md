<div align=center> 
<img src="https://github.com/ningpc/learn_ns2/raw/master/img/ns2.png" width = "60%"/>
</div>  

<div align=center> 
 由:lollipop:和:meat_on_bone:强力驱动
 </div>

NS2 [官方网站](https://www.isi.edu/nsnam/ns/) 已迁移至[wiki](http://nsnam.sourceforge.net/wiki/index.php/Main_Page) (部分翻译节选自wiki)
>NS is a discrete event simulator targeted at networking research. Ns provides substantial support for simulation of TCP, routing, and multicast protocols over wired and wireless (local and satellite) networks.  

- [Download](#download)
- [Installation](#installation)
- [Documents](#documents)
- [Demos](#demos)
- [Miscellaneous](#miscellaneous)
- [FAQ](#faq)
### Download
ns2 current release 2.35(released Nov 4 2011)  
推荐下载`allinone`包，包含所有必备包。
Download from sourceforge: [ns-allinone-2.35.tar.gz](https://sourceforge.net/projects/nsnam/) or my repo: [Here](source/ns-allinone-2.35.tar.gz)

**Package contains:** 
- Tcl release 8.5.10 (required component)
- Tk release 8.5.10 (required component)
- Otcl release 1.14 (required component)
- TclCL release 1.20 (required component)
- Ns release 2.35 (required component)
- Nam release 1.15 (optional component)
- Xgraph version 12 (optional component)
- CWeb version 3.4g (optional component)
- SGB version 1.0 (?) (optional component, builds sgblib for all UNIX type platforms)
- Gt-itm gt-itm and sgb2ns 1.1 (optional component)
- Zlib version 1.2.3 (optional, but required should Nam be used) 
### Installation
For Ubuntu-16.04.3

	something to add
	something to add
For Windows(cygwin)不推荐，暂无. 
### Documents
The NS Manual [PDF](https://www.isi.edu/nsnam/ns/doc/ns_doc.pdf) in isi or in my repo [here](doc/NS%20Manual%20%5Ben.2011%5D.pdf) or [HTML format](http://www.isi.edu/nsnam/ns/doc/index.html).

### Demos
**Unicast routing**
- **ns simple-dyn.tcl** in ns-2/tcl/ex: a simple demo to illustrate **link failure and recovery**; no dynamic routing is done to heal the failure.
- **ns simple-rtg.tcl** in ns-2/tcl/ex: a **dynamic routing** demo.
- **ns simple-eqp.tcl** in ns-2/tcl/ex: **equal cost multi-path routing** through two equal cost routes. 
**ns simple-eqp1.tcl** shows equal cost multi-path routing on a different dynamic topology.

**Multicast routing**
- **ns mcast.tcl** in ns-2/tcl/ex: a **multicast routing** demo. Comments in mcast.txt.
- **ns cmcast.tcl** in ns-2/tcl/ex/newmcast: **centralized multicast computation** for use in ``session-level'' simulations. Instead of using join messages and implementing multicast routing protocols in the individual routers, the multicast routing tables are implemented in a centralized fashion for the entire topology. PIM sparse mode shared trees and source-specific trees are supported. Comments in cmcast.txt. 
**ns cmcast-spt.tcl** uses source-specific trees.
**ns cmcast-100.tcl** creates a topology of 100 nodes and 950 edges. 10 members join the multicast group. One sender sends for 90 seconds.
- **ns detailedDM\*.tcl** in ns-2/tcl/ex/newmcast: Dense Mode protocol that adapts to network changes and works with LAN topologies (LANs created by the multi-link method). Note that this is the recommended version of the dense mode protocol in ns. Comments in detailedDM.txt.
- **ns mcast\*.tcl** in ns-2/tcl/ex/mcast*.tcl: multicast routing demos to illustrate the use of Centralized multicast and the dense mode protocols. Comments in mcast.txt

**Multicast transport**
- **ns simple-rtp.tcl** in ns-2/tcl/ex/newmcast: **RTP**. Black for data packets, green for RTCP reports, cream for join messages, purple for prune messages.
- **ns srm-demo.tcl** in ns-2/tcl/ex: an SRM (Scalable Reliable Multicast) demo. Comments in srm-demo.txt.
- Five tests demonstrate the behaviour of ns' **SRM** implementation: Scripts are: [here](https://www.isi.edu/nsnam/ns/ns-tests.html)

**Traffic** 
- **ns shuttle-mcast.tcl** in ns-2/tcl/ex: Example multicast traffic on a partial MBone topology
- **ns web-traffic.tcl** in ns-2/tcl/ex: Example small-scale web traffic
- **ns large-scale-web-traffic.tcl** in ns-2/tcl/exl: Example large-scale web traffic

**Other**
- **ns simple.tcl** in ns-2/tcl/ex: a simple **nam** demo.
- **ns rc.tcl** in ns-2/tcl/ex: **rate-based congestion control.**
- **ns tg.tcl** in ns-2/tcl/ex: traffic generation modules. Comments in tg.txt.
- **ns-2/tcl/ex/rbp_demo.tcl** Compres TCP with rate-based pacing against other variants.
- **ns mac-test.tcl** in ns-2/tcl/ex: tests for LANs, especially the MAC protocols. 
### Miscellaneous
[**Tcl/Tk**](tcl)  
[**nam**](nam)

#### FAQ
Q1: tclsh或ns编辑界面方向键^[[A、^[[D问题  
A1: 

	#解决方法一，安装rlwrap
	sudo apt-get install rlwrap
	rlwrap -c tclsh
	or
	rlwrap -c ns
	
	#解决方法二，安装tclreadline
	sudo apt-get install tcl-tclreadline
	vi ~/.tclshrc
	#无tclshrc新建即可，添加如下几行并保存。
	if {$tcl_interactive} {
	  package require tclreadline 
	  ::tclreadline::Loop
	}

Q2: ns-2.35/indep-utils/propagation/threshold.cc编译问题

	g++ threshold.cc -o threshold
	提示： iostream.h: 没有那个文件或目录
A2: 

	#include <math.h>
	#include <stdlib.h>
	#include <iostream>    //增加该头文件以引用输出函数
	#include <string.h>      //增加该头文件以引用'strcmp'函数
	using namespace std;  //增加命名空间的声明

如您有任何问题，请联系[weixinbuyi@163.com](mailto:weixinbuyi@163.com)  
Everything will be :ok_hand:.
