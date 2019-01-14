#!/bin/bash
#############################################################
PKGS_DIR="/home/nfdw/openssh_openssl"
#####################/etc/login.defs#########################
sed -i s/^PASS_MAX_DAYS/#PASS_MAX_DAYS/g /etc/login.defs
sed -i s/^PASS_MIN_DAYS/#PASS_MIN_DAYS/g /etc/login.defs
sed -i s/^PASS_MIN_LEN/#PASS_MIN_LEN/g /etc/login.defs
sed -i s/^PASS_WARN_AGE/#PASS_WARN_AGE/g /etc/login.defs
grep "^PASS_MAX_DAYS 180" /etc/login.defs &>/dev/null ||  echo "PASS_MAX_DAYS 180" >>/etc/login.defs
grep "^PASS_MIN_DAYS 1" /etc/login.defs &>/dev/null ||  echo "PASS_MIN_DAYS 1"   >>/etc/login.defs
grep "^PASS_MIN_LEN 8" /etc/login.defs &>/dev/null || echo "PASS_MIN_LEN 8"    >>/etc/login.defs
grep "^PASS_WARN_AGE 28" /etc/login.defs &>/dev/null || echo "PASS_WARN_AGE 28" >>/etc/login.defs
echo -e  "Modify /etc/login.defs........\033[32;1m[ok]\033[0m"

################/etc/pam.d/system-auth######################
grep "password    requisite     pam_cracklib.so minlen=8 ucredit=-2 lcredit=-1 dcredit=-4 ocredit=-1" /etc/pam.d/system-auth &>/dev/null || echo "password    requisite     pam_cracklib.so minlen=8 ucredit=-2 lcredit=-1 dcredit=-4 ocredit=-1" >>/etc/pam.d/system-auth
grep "auth        required      pam_tally2.so deny=5 unlock_time=180 even_deny_root_account audit" /etc/pam.d/system-auth &>/dev/null || echo "auth        required      pam_tally2.so deny=5 unlock_time=180 even_deny_root_account audit" >>/etc/pam.d/system-authh
printf "%-30s %-3s\n" /etc/login.defs `echo -e "\033[32;1m[ok]\033[0m"`

################/etc/profile################################
grep "TMOUT=300" /etc/profile  &>/dev/null || echo "TMOUT=300" >>/etc/profile
grep "Protocol 2" /etc/ssh/sshd_config &>/dev/null || echo "Protocol 2" >>/etc/ssh/sshd_config
grep "umask 022" /etc/profile &>/dev/null || echo "umask 022" >>/etc/profile
printf "%-30s %-3s\n" /etc/profile `echo -e "\033[32;1m[ok]\033[0m"`

################/etc/rstslog.conf################################
[ ! -f /.sh_history ] && touch /.sh_history &>/dev/nul
chmod 400 /etc/rsyslog.conf &>/dev/nul
printf "%-30s %-3s\n" /etc/rstslog.conf `echo -e "\033[32;1m[ok]\033[0m"`

################/etc/security/console.perms################################
sed -i s/^\<console/#\<console/g /etc/security/console.perms &>/dev/nul
sed -i s/^\<xconsole/#\<xconsole/g /etc/security/console.perms &>/dev/nul
printf "%-30s %-3s\n" /etc/security/console.perms `echo -e "\033[32;1m[ok]\033[0m"`

################/etc/logrotate.conf################################
sed -i s/^rotate/#rotate/g /etc/logrotate.conf &>/dev/nul
grep "rotate 28" /etc/logrotate.conf &>/dev/null || echo "rotate 28" >>/etc/logrotate.conf
printf "%-30s %-3s\n" /etc/logrotate.conf `echo -e "\033[32;1m[ok]\033[0m"`

#检测是否更改
#grep ^PASS /etc/login.defs
#grep cracklib /etc/pam.d/system-auth
#grep "1:180:28" /etc/shadow
#grep -i ^PermitRoot /etc/ssh/sshd_config 
#tail -n 1 /etc/profile
#grep "<*console>" /etc/security/console.perms
#ls -l  /.sh_history
#ls -l /etc/rsyslog.conf
#grep 28 /etc/logrotate.conf

################mkdir tar################################
yum -y install gcc make perl zlib zlib-devel pam pam-devel &>/dev/null
[! -d /soft/openssh ] && mkdir -p /soft/{zlib,openssh,openssl} 
tar -xf $PKGS_DIR/openssh-7.9p1.tar.gz -C  /soft/openssh
tar -xf $PKGS_DIR/openssl-1.0.2p.tar.gz -C  /soft/openssl
tar -xf $PKGS_DIR/zlib-1.2.11.tar.gz -C /soft/zlib/
systemctl stop sshd
for i in `rpm -qa | grep openssh` ;do rpm -e $i --nodeps ;done


################zlib################################
cd /soft/zlib/zlib-1.2.11
./configure --prefix=/usr/local/zlib  &>/dev/null
make && make install &>/dev/null
grep "/usr/local/zlib/lib" /etc/ld.so.conf.d/zlib.conf &>/dev/null || echo "/usr/local/zlib/lib" >> /etc/ld.so.conf.d/zlib.conf
ldconfig -v &>/dev/null

cd /soft/openssl/openssl-1.0.2p
./config shared zlib
make
make test
make install
mv /usr/bin/openssl /usr/bin/openssl.OFF
ln -s /usr/local/ssl/bin/openssl /usr/bin/openssl
ln -s /usr/local/ssl/include/openssl /usr/include/openssl
grep "/usr/local/ssl/lib" /etc/ld.so.conf.d/ssl.conf || echo "/usr/local/ssl/lib" >>/etc/ld.so.conf.d/ssl.conf
ldconfig -v
openssl version -a
mv /etc/ssh /etc/ssh.bak
cd /soft/openssh/openssh-7.9p1
./configure --prefix=/usr/local/openssh --sysconfdir=/etc/ssh --with-ssl-dir=/usr/local/ssl --mandir=/usr/share/man --with-zlib=/usr/local/zlib
make
make install
/usr/local/openssh/bin/ssh -V
\cp /soft/openssh/openssh-7.9p1/contrib/redhat/sshd.init /etc/init.d/sshd
chmod u+x /etc/init.d/sshd
chkconfig --add sshd
chkconfig --list|grep sshd
\cp /soft/openssh/openssh-7.9p1/sshd_config /etc/ssh/sshd_config
sed -i s#/usr/libexec/sftp-server#/usr/local/openssh/libexec/sftp-server#g /etc/ssh/sshd_config
\cp /usr/local/openssh/sbin/sshd /usr/sbin/sshd
\cp /usr/local/openssh/bin/* /usr/bin/
ssh -V
\cp /usr/local/openssh/bin/ssh-keygen /usr/bin/ssh-keygen
sed -i s/#PasswordAuthentication/PasswordAuthentication/g /etc/ssh/sshd_config
systemctl start sshd
#service sshd restart
systemctl is-active sshd
ss -lnt | grep 22

# cp /soft/openssl/openssl-1.0.2p/{libssl.so.1.0.0,libcrypto.so.1.0.0} /usr/lib64
#cd /usr/lib64
#ln -s libssl.so.1.0.0 libssl.so.10 
#ln -s libcrypto.so.1.0.0 libcrypto.so.10

