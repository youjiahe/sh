#!/bin/bash
####################################
NEO4J_HOME="/usr/local/neo4j"
NEO4J_TAR_DIR="/data/pkgs"
NEO4J_VER='3.4.0'
n1="10.92.205.126"
n2="10.92.205.127"
n3="10.92.205.128"
####################################
num=`ifconfig eth0 | awk -F"[ .]*" '/inet[^6]/{print $6}'`
hosts="$n1:5001,$n2:5001,$n3:5001"
yum -y install java-1.8.0-openjdk-devel java-1.8.0-openjdk iptables-services
echo
tar -xf ${NEO4J_TAR_DIR}/neo4j-enterprise-${NEO4J_VER}-unix.tar.gz 
mv neo4j-enterprise-${NEO4J_VER} ${NEO4J_HOME}
cd ${NEO4J_HOME}
sed -ir "/^#dbms\.mode=HA/s/#//" conf/neo4j.conf 
sed -ir "/^#ha\.server_id/c ha.server_id=$num" conf/neo4j.conf 
sed -ir "/^#ha.initial_hosts/c ha.initial_hosts=$hosts" conf/neo4j.conf 
sed -ir "/^#dbms.connector.http.listen_address=:7474/s/#//" conf/neo4j.conf 
sed -ir "/^#dbms.connectors.default_listen_address=0.0.0.0/s/#//" conf/neo4j.conf 
for port in 7474 7687 5001
do
   grep "\-\-dport $port" /etc/sysconfig/iptables || sed -ir "/--dport 22/a -A INPUT -p tcp -m state --state NEW -m tcp --dport $port -j ACCEPT" /etc/sysconfig/iptables
done
systemctl restart iptables
grep JAVA /etc/profile || echo 'export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.131-11.b12.el7.x86_64
export PATH=.:$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar'>> /etc/profile
bin/neo4j start
