juju add-model -c maas-controller --config default-series=jammy openstack

juju switch maas-controller:openstack







Ceph OSD
********
juju deploy -n 3 --series jammy --channel quincy/stable --config ceph-osd.yaml --constraints tags=compute ceph-osd



Mysql-Innodb-cluster
********************
juju deploy -n 3 --to lxd:0,lxd:1,lxd:2  --channel 8.0/stable mysql-innodb-cluster


Vault 
*****

juju deploy -n 3 --to lxd:0,lxd:1,lxd:2  --config vip=192.168.100.202 --channel 1.7/stable vault
juju deploy --channel 2.4/stable --config cluster_count=3 hacluster vault-hacluster
juju deploy --channel 8.0/stable mysql-router vault-mysql-router

juju add-relation vault-hacluster:ha vault:ha
juju add-relation vault-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation vault-mysql-router:shared-db vault:shared-db

juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 etcd
juju add-relation etcd:db vault:etcd
juju add-relation vault:certificates etcd:certificates




 





Keystone 
********

juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 --config vip=192.168.100.203  --channel yoga/stable keystone
juju deploy  --channel 2.4/stable --config cluster_count=3 hacluster keystone-hacluster
juju deploy --channel 8.0/stable mysql-router keystone-mysql-router


juju add-relation keystone-hacluster:ha keystone:ha
juju add-relation keystone-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation keystone-mysql-router:shared-db keystone:shared-db

juju add-relation keystone:certificates vault:certificates







Ceph Mon 
juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 --channel quincy/stable --config ceph-mon.yaml ceph-mon
juju deploy -n 3 --to lxd:0,lxd:1,lxd:2  --channel quincy/stable --config monitor-count=3 ceph-mon


juju add-relation ceph-mon:osd ceph-osd:mon






NTP 
juju deploy  ntp


Rbbitmq server
**************
juju deploy  -n 3 --to lxd:0,lxd:1,lxd:2   --channel 3.9/stable rabbitmq-server





Glance 
******

juju deploy -n 3 --to lxd:0,lxd:1,lxd:2  --config vip=192.168.100.201 --channel yoga/stable glance
juju deploy  --channel 2.4/stable --config cluster_count=3 hacluster glance-hacluster
juju add-relation glance-hacluster:ha glance:ha


juju deploy --channel 8.0/stable mysql-router glance-mysql-router
juju add-relation glance-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation glance-mysql-router:shared-db glance:shared-db


juju add-relation glance:identity-service keystone:identity-service
juju add-relation glance:certificates vault:certificates
juju add-relation glance:amqp rabbitmq-server:amqp
juju add-relation ceph-mon:client glance:ceph









Ceph Radosgw
************
juju deploy -n 3 --to lxd:0,lxd:1,lxd:2  --config vip=192.168.100.200 --channel quincy/stable ceph-radosgw
juju deploy  --channel 2.4/stable --config cluster_count=3 hacluster ceph-radosgw-hacluster
juju add-relation ceph-radosgw-hacluster:ha ceph-radosgw:ha

juju add-relation ceph-radosgw:mon ceph-mon:radosgw



Nova Compute 
************

juju deploy -n 3 --to 0,1,2 --channel zed/stable --config openstack-origin=cloud:jammy-yoga  --config config-flags=default_ephemeral_format=ext4 --config enable-live-migration=true --config enable-resize=true  --config migration-auth-type=ssh nova-compute


juju add-relation nova-compute:amqp rabbitmq-server:amqp
juju add-relation nova-compute:image-service glance:image-service

juju add-relation ceph-mon:client nova-compute:ceph

juju add-relation  ntp:juju-info nova-compute:juju-info
juju add-relation ceph-mon:client nova-compute:ceph
juju add-relation ceph-mon:client glance:ceph

juju add-relation rabbitmq-server:amqp nova-compute:amqp
juju add-relation glance:image-service nova-compute:image-service



Nova cloud controller
*********************
juju deploy -n 3 --to lxd:0,lxd:1,lxd:2  --channel yoga/stable  --config openstack-origin=cloud:jammy-yoga --config network-manager=Neutron --config vip=192.168.100.204 nova-cloud-controller
juju deploy --channel 2.4/stable  --config cluster_count=3 hacluster nova-cloud-controller-hacluster
juju add-relation nova-cloud-controller-hacluster:ha nova-cloud-controller:ha

juju deploy --channel 8.0/stable mysql-router ncc-mysql-router
juju add-relation ncc-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation ncc-mysql-router:shared-db nova-cloud-controller:shared-db


juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 memcached
juju add-relation memcached:cache nova-cloud-controller:memcache


juju add-relation nova-cloud-controller:identity-service keystone:identity-service
juju add-relation nova-cloud-controller:amqp rabbitmq-server:amqp

juju add-relation nova-cloud-controller:cloud-compute nova-compute:cloud-compute
juju add-relation nova-cloud-controller:certificates vault:certificates
juju add-relation placement:placement nova-cloud-controller:placement


juju add-relation glance:image-service nova-cloud-controller:image-service



Placement
*********

juju deploy  -n 3 --to lxd:0,lxd:1,lxd:2 --config vip=192.168.100.205  --channel yoga/stable placement

juju deploy  --channel 2.4/stable --config cluster_count=3 hacluster placement-hacluster
juju add-relation placement-hacluster:ha placement:ha

juju deploy --channel 8.0/stable mysql-router placement-mysql-router
juju add-relation placement-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation placement-mysql-router:shared-db placement:shared-db

juju add-relation placement:identity-service keystone:identity-service
juju add-relation placement:placement nova-cloud-controller:placement
juju add-relation placement:certificates vault:certificates





Neutron
*******

juju deploy -n 3 --to lxd:0,lxd:1,lxd:2  --channel 22.09/stable ovn-central
juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 --config vip=192.168.100.206 --channel yoga/stable --config neutron.yaml neutron-api

juju deploy  --channel 2.4/stable  --config cluster_count=3 hacluster neutron-api-hacluster
juju add-relation neutron-api-hacluster:ha neutron-api:ha


juju deploy --channel yoga/stable neutron-api-plugin-ovn
juju deploy --channel 22.09/stable --config neutron.yaml ovn-chassis

juju deploy --channel 8.0/stable mysql-router neutron-api-mysql-router
juju add-relation neutron-api-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation neutron-api-mysql-router:shared-db neutron-api:shared-db


juju add-relation neutron-api-plugin-ovn:neutron-plugin neutron-api:neutron-plugin-api-subordinate
juju add-relation neutron-api-plugin-ovn:ovsdb-cms ovn-central:ovsdb-cms
juju add-relation ovn-chassis:ovsdb ovn-central:ovsdb

juju add-relation neutron-api:certificates vault:certificates
juju add-relation neutron-api-plugin-ovn:certificates vault:certificates
juju add-relation ovn-central:certificates vault:certificates
juju add-relation ovn-chassis:certificates vault:certificates

juju add-relation nova-cloud-controller:neutron-api neutron-api:neutron-api

juju add-relation  ovn-chassis:nova-compute nova-compute:neutron-plugin
juju add-relation keystone:identity-service neutron-api:identity-service


juju add-relation rabbitmq-server:amqp neutron-api:amqp

Cinder
******

juju deploy -n 3 --to lxd:0,lxd:1,lxd:2 --config vip=192.168.100.207  --channel yoga/stable --config cinder.yaml cinder

juju deploy  --channel 2.4/stable --config cluster_count=3 hacluster cinder-hacluster
juju add-relation cinder-hacluster:ha cinder:ha



juju deploy --channel 8.0/stable mysql-router cinder-mysql-router
juju add-relation cinder-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation cinder-mysql-router:shared-db cinder:shared-db


juju add-relation cinder:cinder-volume-service nova-cloud-controller:cinder-volume-service
juju add-relation cinder:identity-service keystone:identity-service
juju add-relation cinder:amqp rabbitmq-server:amqp

juju add-relation cinder:certificates vault:certificates


juju deploy --channel yoga/stable cinder-ceph
juju add-relation cinder-ceph:storage-backend cinder:storage-backend
juju add-relation cinder-ceph:ceph ceph-mon:client
juju add-relation cinder-ceph:ceph-access nova-compute:ceph-access
juju add-relation  nova-compute:ceph      nova-compute:ceph-access
 

juju add-relation cinder:image-service glance:image-service









OpenStack dashboard
*******************



juju deploy  -n 3 --to lxd:0,lxd:1,lxd:2 --config vip=192.168.100.208  --channel yoga/stable openstack-dashboard

juju deploy  --channel 2.4/stable --config cluster_count=3 hacluster openstack-dashboard-hacluster
juju add-relation openstack-dashboard-hacluster:ha openstack-dashboard:ha

juju deploy --channel 8.0/stable mysql-router openstack-dashboard-mysql-router
juju add-relation openstack-dashboard-mysql-router:db-router mysql-innodb-cluster:db-router
juju add-relation openstack-dashboard-mysql-router:shared-db openstack-dashboard:shared-db

juju add-relation openstack-dashboard:identity-service keystone:identity-service
juju add-relation openstack-dashboard:certificates vault:certificates

common issues: 
nova-api-metadata stops. 
SSH to the server and sudo systemctl start nova-api-metadata
need to find the reason for this



jaigei8fae8ieWie
http://192.168.100.208/horizon