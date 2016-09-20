
# **ceph cookbook**

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
