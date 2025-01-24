#!/bin/bash

REALM=DOMAIN.LOCAL
DOMAIN=domain.local
WORKGROUP=DOMAIN
SERVER=server.domain.local
SAMBA_IP=192.168.x.x
ADMIN_USER=administrator


echo $REALM
echo $DOMAIN
echo $WORKGROUP
echo $SERVER
echo $SAMBA_IP
echo $ADMIN_USER

apt update


DEBIAN_FRONTEND=noninteractive apt install -y samba winbind krb5-user libpam-krb5 libnss-winbind libpam-winbind vim openssh-server


# Enable user home directory creation:
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> /etc/pam.d/common-session


# Config KRB5.CONF
echo "
[libdefaults]
	default_realm = $REALM

# The following krb5.conf variables are only for MIT Kerberos.
	kdc_timesync = 1
	ccache_type = 4
	forwardable = true
	proxiable = true
		rdns = false


# The following libdefaults parameters are only for Heimdal Kerberos.
	fcc-mit-ticketflags = true

[realms]
		$REALM = {
				kdc = $SERVER
				admin_server = $SERVER
	}

[domain_realm]
	.$DOMAIN = $REALM
	$DOMAIN = $REALM" > /etc/krb5.conf


# Config PAM_WINBIND.CONF

echo "
# pam_winbind configuration file
#
# /etc/security/pam_winbind.conf
#
[global]
# request a cached login if possible
# (needs "winbind offline logon = yes" in smb.conf)
cached_login = yes" > /etc/security/pam_winbind.conf
	
	
# Config SMB.CONF	
echo "
	   [global]
	   workgroup = $WORKGROUP
	   realm = $REALM
	   server role = member server
	   security = ads

	   idmap config * : backend = tdb
	   idmap config * : range = 4000-299999
	   idmap config $REALM : schema_mode = rfc2307
	   idmap config $REALM : backend = rid
	   idmap config $REALM : range = 10000-4000000

	   winbind enum users = yes
	   winbind enum groups = yes
	   winbind use default domain = yes
	   winbind refresh tickets = yes
	   
	   winbind offline logon = yes
	   winbind request timeout = 10

	   template shell = /bin/bash

	   # User home directory
	   template homedir = /home/%D/%U" > /etc/samba/smb.conf
	   

# Config NSSWITCH.CONF
echo "
passwd:         files systemd winbind
group:          files systemd winbind
shadow:         files systemd
gshadow:        files systemd

hosts:          files mdns4_minimal [NOTFOUND=return] dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis" > /etc/nsswitch.conf


mv /etc/resolv.conf /etc/resolv.conf.bak


echo "
nameserver $SAMBA_IP
search $DOMAIN" > /etc/resolv.conf


net ads join -U $ADMIN_USER


systemctl restart smb winbind


# Enable manual user switching on Mint Cinnamon:
echo "
[Seat:*]
greeter-show-manual-login=true" > /etc/lightdm/lightdm.conf

# Allow domain homedir on apparmor, to enable snap applications usage.
echo "
@{HOMEDIRS}+=/home/$WORKGROUP/" >> /etc/apparmor.d/tunables/home.d/ubuntu


### Source:
# https://wiki.samba.org/index.php/PAM_Offline_Authentication
# https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member

