# 红帽文档阅读

[redhat ceph 文档](https://access.redhat.com/documentation/en/red-hat-ceph-storage/)

## 发布说明

- 通过Ansible进行安装
- OSD BLUESTORE技术预览

## 安装说明

在redhat上安装ceph

- 全局设置

>[global]
fsid = <cluster-id>
mon initial members = <monitor_host_name>[, <monitor_host_name>]
mon host = <ip-address>[, <ip-address>]
public network = <network>[, <network>]
cluster network = <network>[, <network>]
auth cluster required = cephx
auth service required = cephx
auth client required = cephx
osd journal size = <n>
filestore xattr use omap = true
osd pool default size = <n> # Write an object n times.
osd pool default min size = <n> # Allow writing n copy in a
degraded state.
osd pool default pg num = <n>
osd pool default pgp num = <n>
osd crush chooseleaf type = <n>

- osd设置

	- 创建osd默认目录

	mkdir /var/lib/ceph/osd/ceph-0

	- 准备作为硬盘的osd,挂载到创建的目录上.

	># parted /dev/sdb mklabel gpt
	# parted /dev/sdb mkpart primary 1 10000
	# parted /dev/sdb mkpart primary 10001 15000
	# mkfs -t xfs /dev/sdb1
	# mount -o noatime /dev/sdb1 /var/lib/ceph/osd/ceph-0
	# echo "/dev/sdb1 /var/lib/ceph/osd/ceph-0 xfs defaults,noatime
	1 2" >> /etc/fstab

## 管理员指导手册

- 用户管理

	[ceph_user@admin-node my-cluster]$ ceph osd df
	ID WEIGHT  REWEIGHT SIZE   USE    AVAIL  %USE  VAR  
	 0 0.03999  1.00000 39508M  8082M 31426M 20.46 1.00 
	 1 0.03999  1.00000 39508M  8081M 31427M 20.45 1.00 
	 2 0.03999  1.00000 39508M  8081M 31427M 20.45 1.00 
	              TOTAL   115G 24244M 94281M 20.45      
	MIN/MAX VAR: 1.00/1.00  STDDEV: 0.00
	[ceph_user@admin-node my-cluster]$ 

- 显示规则

	ceph osd crush rule list
	ceph osd crush rule ls

- pool 快照

	[ceph_user@admin-node ~]$ ceph osd pool mksnap test snap_test
	created pool test snap snap_test
	[ceph_user@admin-node ~]$ 

	- 删除pool快照

	ceph osd pool rmsnap <pool>  <snap-name>