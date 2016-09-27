# ceph重点

## 安装时指定日志盘

	ceph-deploy osd  HOST:DISK[:JOURNAL]
	ceph-deploy osd prepare 数据盘:日志盘
	ceph-deploy osd prepare --zap-disk objStor02:/dev/sdd:/dev/sdb


在使用ceph-deploy osd prepare命令的对目标机器的磁盘进行格式化过程中，ceph-deploy命令可能会卡住，主要是由于linux内核没有获得最新的磁盘分区信息，在目标机器上进行partprobe命令即可告诉linux分区的变化。partporbe命令可能会失败，多尝试几次，直到成功为止，ceph-deploy就可以继续安装下去。

## 性能优化
[Ceph性能优化总结(v0.94)](http://xiaoquqi.github.io/blog/2015/06/28/ceph-performance-optimization-summary/)

- SSD
由于Journal在向数据盘写入数据时Block后续请求，所以Journal的加入并未呈现出想象中的性能提升，但是的确会对Latency有很大的改善。

- 软件优化

	Kernel pid max
	echo 4194303 > /proc/sys/kernel/pid_max

## 条带化

[条带化重要文章](http://www.cnblogs.com/sammyliu/p/4836014.html)

 在 RADOS 层，Ceph 本身没有条带的概念，因为一个object 是作为一个 文件整体性保存的。但是，RBD 可以控制向一个 object 的写入方式，默认是将一个 object 写满再去写下一个object；还可以通过指定 stripe_unit 和 stripe_count，来将 object 分成若干个条带即 strip。

 一个 RDB image 会被分为多个 object 来保存，从而使得对一个 image 的多个读写可以分在多个 object 进行，从而可以防止某个 image 非常大或者非常忙时单个节点称为性能瓶颈。还可以将 object 进一步条带化为多个条带（stripe unit）。条带（stripe）是 librados 通过 ODS 写入数据的基本单位。这么做的好处是在保持对象数目的同时，进一步减少可以同步读写的粒度（从 object 粒度减少到 stripe 粒度），从而提高读写效率。
 
Ceph 的条带化行为（如果划分条带和如何写入条带）受三个参数控制：
order：RADOS Object 的大小为 2^[order] bytes。默认的 oder 为 22，这时候对象大小为4MB。最小 4k，最大 32M，默认 4M.
stripe_unit：条带（stripe unit）的大小。每个 [stripe_unit] 的连续字节会被连续地保存到同一个对象中，client 写满 stripe unit 大小的数据后，接着去下一个 object 中写下一个 stripe unit 大小的数据。默认为 1，此时一个 stripe 就是一个 object。
stripe_count：在分别写入了 [stripe_unit] 个字节到 [stripe_count] 个对象后，ceph 又重新从一个新的对象开始写下一个条带，直到该对象达到了它的最大大小。这时候，ceph 转移到下 [stripe_unit] 字节。默认为 object site。

以下图为例：
1. RBD image 会被保存在总共 8 个 RADOS object （计算方式为 client data size 除以 2^[order]）中。
2. stripe_unit 为 object size 的四分之一，也就是说每个 object 包含 4 个 stripe。
3. stripe_count 为 4，即每个 object set 包含四个 object。这样，client 以 4 为一个循环，向一个 object set 中的每个 object 依次写入 stripe，写到第 16 个 stripe 后，按照同样的方式写第二个 object set。


![示例图片](http://images2015.cnblogs.com/blog/697113/201509/697113-20150925180305803-50366273.jpg)

默认的情况下，[stripe_unit] 等于 object size；stripe_count 为1。意味着 ceph client 在将第一个 object 写满后再去写下一个 object。要设置其他的 [stripe_unit] 值，需要Ceph v0.53 版本及以后版本对 STRIPINGV2 的支持以及使用 format 2 image 格式。


## 块设备的优势

![块](http://www.ssdfans.com/wp-content/uploads/2015/03/032415_1102_Ceph1.gif)

因为 Linux 显示文件系统的一个公共界面（通过虚拟文件系统交换机 [VFS]），Ceph 的用户透视图就是透明的。


Linux 虚拟系统文件交换器剖析
[VFS](http://www.ibm.com/developerworks/cn/linux/l-virtual-filesystem-switch/)


OpenStack 解决方案的核心和附加组件

![](http://www.ibm.com/developerworks/cn/cloud/library/cl-openstack-cloud/figure2.gif)

## cephfs和RBD区别


> CephFS is a filesystem, rbd is a block device.  CephFS is a lot like NFS;
> it's a filesystem shared over the network where different machines can
> access it all at the same time.  RBD is more like a hard disk image, shared
> over the network.  It's easy to put a normal filesystem (like ext2) on top
> of it and mount it on a computer, but if you mount the same RBD device on
> multiple computers at once then Really Bad Things are going to happen to
> the filesystem.
>
> In general, if you want to share a bunch of files between multiple
> machines, then CephFS is your best bet.  If you want to store a disk image,
> perhaps for use with virtual machines, then you want RBD.  If you want
> storage that is mostly compatible with Amazon's S3, then use radosgw.


RBD更适合云计算环境
提供2中类型image

- A Kernel module, part of the main line since 2010, that exposes block devices to a system (same way as iSCSI does)
- A QEMU driver to build virtual machine disks on top of RBD (attaching devices and booting from device)

亚马逊 [EFS](https://aws.amazon.com/cn/efs/) 与 [EBS](https://aws.amazon.com/cn/ebs/)

问：应该分别在什么情况下使用 Amazon EFS、Amazon Simple Storage Service (S3) 和 Amazon Elastic Block Store (EBS)？[亚马逊回答](https://aws.amazon.com/cn/efs/faq/)

 Amazon Web Services (AWS) 提供多种云存储服务来支持各种存储工作负载。

- Amazon EFS 是一项与 Amazon EC2 配合使用的文件存储服务。Amazon EFS 可以提供文件系统界面、文件系统访问语义（例如强一致性和文件锁定）以及可供多达数千个 Amazon EC2 实例同时访问的存储。数千个EC2可以同时连接一个文件系统.吞吐量大.价格贵.

- Amazon EBS 是一项与 Amazon EC2 配合使用的数据块级存储服务。对于需要从单个 EC2 实例低延迟访问数据的工作负载，Amazon EBS 可为其提供高性能服务。延迟低.价格便宜.

- Amazon S3 是一项对象存储服务。Amazon S3 通过可以在任何地方访问的 Internet API 来提供数据访问。