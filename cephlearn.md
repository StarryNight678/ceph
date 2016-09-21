

安装时指定日志盘
ceph-deploy osd  HOST:DISK[:JOURNAL]

ceph-deploy osd prepare 数据盘:日志盘

```
ceph-deploy osd prepare --zap-disk objStor02:/dev/sdd:/dev/sdb
```

在使用ceph-deploy osd prepare命令的对目标机器的磁盘进行格式化过程中，ceph-deploy命令可能会卡住，主要是由于linux内核没有获得最新的磁盘分区信息，在目标机器上进行partprobe命令即可告诉linux分区的变化。partporbe命令可能会失败，多尝试几次，直到成功为止，ceph-deploy就可以继续安装下去。
