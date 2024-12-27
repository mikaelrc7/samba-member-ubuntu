=Script para ingresso do linux no domínio (Ubuntu 24.04):=

* Permite logon com usuários do domínio, incluindo cache para logon offline.

* Testado no Linux Mint 22 Cinnamon

* Ajustar variáveis para o domínio escolhido

<pre>	
#!/bin/bash

REALM=TRUSTDC.LOCAL
DOMAIN=trustdc.local
WORKGROUP=TRUSTDC
SERVER=samba-mikael.trustdc.local
SAMBA_IP=192.168.16.41
ADMIN_USER=administrator


echo $REALM
echo $DOMAIN
echo $WORKGROUP
echo $SERVER
echo $SAMBA_IP
echo $ADMIN_USER

apt update

#apt upgrade -y

DEBIAN_FRONTEND=noninteractive apt install -y samba winbind krb5-user libpam-krb5 libnss-winbind libpam-winbind vim openssh-server


# Adicionar linha para criar o diretório home automaticamente no login do usuário samba:
echo "session required pam_mkhomedir.so skel=/etc/skel/ umask=0077" >> /etc/pam.d/common-session


# Configuracao KRB5.CONF
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


# Configuracao PAM_WINBIND.CONF

echo "
# pam_winbind configuration file
#
# /etc/security/pam_winbind.conf
#
[global]
# request a cached login if possible
# (needs "winbind offline logon = yes" in smb.conf)
cached_login = yes" > /etc/security/pam_winbind.conf
	
	
# Configuracao SMB.CONF	
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
	   # As duas linhas seguintes são necessárias para habilitar o login offline com usuários do dominio
	   winbind offline logon = yes
	   winbind request timeout = 10

	   template shell = /bin/bash

	   # User home directory
	   template homedir = /home/%D/%U" > /etc/samba/smb.conf
	   

# Configuracao NSSWITCH.CONF
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


# Ajustar troca de usuário no cinnamon:
#sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nomodeset"/g' /etc/default/grub

echo "
[Seat:*]
greeter-show-manual-login=true" > /etc/lightdm/lightdm.conf



####################################################################

### Executar os seguintes comandos para executar o script:
	
### Baixar esse arquivo

### chmod +x ~/Downloads/samba-member.sh
 
### sudo sh ~/Downloads/samba-member.sh

### Inserir senha do usuário administrador quando solicitada

### Ao finalizar a execução, reiniciar a máquina

####################################################################

### Fontes:
# https://wiki.samba.org/index.php/PAM_Offline_Authentication
# https://wiki.samba.org/index.php/Setting_up_Samba_as_a_Domain_Member



</pre>
