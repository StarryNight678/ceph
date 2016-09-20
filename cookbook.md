
# **ceph cookbook**



可靠性 纠删码 缓存

rbd接口

## 块设备
每一个块设备分布在多个ceph节点上.
librbd库,RBD原生支持Linux内核.

## 特性
1)	可靠性,性能
2)	完整和增量快照
3)	自动精简配置
4)	写时复制克隆
5)	动态调整大小
6)	内存内缓存

块设备可以和Cinder(块存储)和Glance(镜像)组件对接.

检查内核对RBD支持

    sudo modprobe rbd


    rbd create rbd1 --size 10240


## Openstack
Glance后端存储

Glance将虚拟机镜像存储在RBD中

Cinder的后端块存储

Cinder将卷建在Ceph中
Nova将卷挂载到虚拟机上



## 对象存储

ceph可以跟身份管理服务,keystone集成
任何被keystone验证通过的用户都将获得RGW的访问权限.




owncloud + S3 私有云存储




## 	使用ceph文件系统


libcephfs 原生支持linux内核驱动,可以直接使用文件挂载方式
允许直接与Rados交互,作为HDFS的替代品.



ceph FUSE 时为了较早版本的linux系统,或者有些程序依赖.通过客户端方便的挂载文件系统.

可以将cephfs导出为NFS,进行挂载.

windows平台,可以挂载为本地磁盘


##	监控集群


操作个管理Ceph集群


#	深入ceph
- 扩展性
- 搞可用性
- 身份验证和授权
- CRUSH map
- 动态管理
- ceph存储池



### CRUSH map


ceph cluster map
monitor 通过维护cluster map 来实现功能.
cluster map包括:
1)	monitor map
2)	osd map
3)	PG map
4)	CRUSH map
5)	MDS map



monitor map

```
[ceph_user@admin-node ~]$ ceph mon dump
dumped monmap epoch 3
epoch 3
fsid ec3c5aae-83f4-4bcb-ac02-bea56023d421
last_changed 2016-09-20 17:31:46.361085
created 0.000000
0: 192.168.0.133:6789/0 mon.node1
1: 192.168.0.134:6789/0 mon.node2
2: 192.168.0.135:6789/0 mon.node3
[ceph_user@admin-node ~]$
```

[ceph_user@admin-node ~]$ ceph osd dump
ceph pg dump
ceph osd crush dump
ceph mds dump

## OSD读写顺序
主OSD是唯一接收客户写操作的OSD,客户读操作时,默认从OSD读取.
可以设置读亲和性(read affinity)来改变这种行为.


## PG状态
clean对象已经复制了规定的份数
degraded 副本未达到规定的数目
backfill 新的OSD加入集群,CRUSH将现有的一部分PG分配给她
stale pg处于未知状态 monitor 在pg改变后没有收到更新.
remapped pg的acting set 变化后,数据从旧的acting set 迁移到新的acting set需要一段时间才能提供服务.


##	ceph生产计划和性能调优
1)	性能调优
2)	纠删码
3)	缓存分层
4)	日志盘



## 日志盘
每一个写操作分为两步:
1.	请求写个对象,先将对象写入到 PG acting set 对应的日志盘中
2.	发送写确认请求给客户端,日志同步到数据盘

SSD作为日志盘.
在SSD上建立多个逻辑分区.每个逻辑分区映射到一个OSD数据盘.
日志分区不能超过SSD的上限.

1、每块硬盘理论上最多可以包含四个主分区，用特殊软件或有意去修改MBR方法达到更多主分区都是非标准的，也没有必要。
2、扩展分区可有可无，但是要分逻辑分区则必须先划分扩展分区。
3、每个扩展分区理论上最多可以包含64个逻辑分区。
硬盘的分区由主分区、扩展分区和逻辑分区组成：主分区(注意扩展分区也是一个主分区)的最大个数是四个，其个数是由硬盘的主引导记录MBR(Master Boot Recorder)决定的，MBR存放启动管理程序(如GRUB)和分区表记录。扩展分区下又可以包含多个逻辑分区 --- 所以主分区范围是从1-4，逻辑分区是从5开始的。
SSD和OSD的比例为1:4
PCIE和NVME可以达到1:12或1:18
如果SSD出现问题,关联的OSD也将出问题.


PG PGP数目应保持一致


8.1	纠删码
8.2	缓存分层
两种模式
1.	回写模式,写立即收到确认回复
2.	只读模式,只服务读操作

为存储池是在



##	ceph虚拟存储管理器


##	ceph内存分析
低层次PG和对象恢复工具
ceph-objectstore-tool














## 磁盘性能测试

```
清除缓存
echo 3> /proc/sys/vm/drop_caches
direct 表示绕过磁盘缓存,获得真实效果

写属性
dd if=/dev/zero of=/home/ceph_user/filetest bs=1M count=1000 oflag=direct

读属性
dd if=/home/ceph_user/filetest of=/dev/null  bs=1M count=1000 oflag=direct
```
不同标志性能差异比较大

>[ceph_user@node1 ~]$ dd if=/dev/zero of=/home/ceph_user/filetest bs=1M count=1000
1000+0 records in
1000+0 records out
1048576000 bytes (1.0 GB) copied, 5.68634 s, 184 MB/s
[ceph_user@node1 ~]$ dd if=/dev/zero of=/home/ceph_user/filetest bs=1M count=1000 oflag=direct
1000+0 records
1000+0 records out
1048576000 bytes (1.0 GB) copied, 0.894945 s, 1.2 GB/s
[ceph_user@node1 ~]$


## 网络性能测试

### 启动服务器端
-s启动服务器 -p 指定端口监听
```
iperf -s -p 6900
```
### 启动客户端

nod1指定服务器的名称
```
iperf -c node1 -p 6900
```

## rados bench工具

- 10s写测试

```
rados bench -p rbd 10 write --no-cleanup
```

- 10s 顺序测试

```
rados bench -p rbd 10  write seq

rados bench -p test 10  rand

```


- load-gen 工具


    rados -p test load-gen --num-objects 50 --run-length 3

- 块设备基准测试


    rbd bench-write block-device1 --io-total 5368709200

## 清理特定的pool
    for obj in `rados -p rbd ls`;
    do
      rados -p rbd rm  $obj
    done


 FIO 做Ceph RBD 基准测试
```
yum install -y fio

```
