

安装时指定日志盘
ceph-deploy osd  HOST:DISK[:JOURNAL]

ceph-deploy osd prepare 数据盘:日志盘

```
ceph-deploy osd prepare --zap-disk objStor02:/dev/sdd:/dev/sdb
```
