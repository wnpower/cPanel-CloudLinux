#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "██╗    ██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗███████╗██████╗     ██████╗ ██████╗ ███╗   ███╗"
echo "██║    ██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗   ██╔════╝██╔═══██╗████╗ ████║"
echo "██║ █╗ ██║██╔██╗ ██║██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝   ██║     ██║   ██║██╔████╔██║"
echo "██║███╗██║██║╚██╗██║██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗   ██║     ██║   ██║██║╚██╔╝██║"
echo "╚███╔███╔╝██║ ╚████║██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║██╗╚██████╗╚██████╔╝██║ ╚═╝ ██║"
echo " ╚══╝╚══╝ ╚═╝  ╚═══╝╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝"

echo ""
echo "         ####################### CloudLinux (cPanel) Installer #######################      "
echo ""
echo ""

if [ ! -d /usr/local/cpanel ]; then
	echo "cPanel no detectado, abortando."
	exit 0
fi

if [ ! -f /etc/redhat-release ]; then
        echo "CentOS no detectado, abortando."
        exit 0
fi

echo "Este script instala y configura CloudLinux. Hay que ejecutarlo 2 veces: la primera para que instale el Kernel de CloudLinux, luego el equipo se reinicia y se ejecuta por segunda vez para configurarlo (CTRL + C para abortar)"

sleep 10

echo "Detectando CloudLinux..."
CL=$(grep "CloudLinux" /etc/redhat-release > /dev/null && echo SI || echo NO)

if [ "$CL" = "NO" ]; then
	echo "CloudLinux no detectado, bajando instalador..."
	wget http://repo.cloudlinux.com/cloudlinux/sources/cln/cldeploy -O $CWD/cldeploy
	CL_INSTALL="$CWD/cldeploy"
	echo ""
	echo "Modo licencia por Key o por IP? [key/ip]"
	read CL_LICENCE_MODE
	if echo "$CL_LICENCE_MODE" | grep -iq "^key" ;then
		echo "Key: "
		read CL_LICENCE
		sh "$CL_INSTALL" -k "$CL_LICENCE"
	elif echo "$CL_LICENCE_MODE" | grep -iq "^ip" ;then
                sh "$CL_INSTALL" -i
	fi
	echo ""
	echo ""
	echo "######### REINICIAR PARA APLICAR EL NUEVO KERNEL? [y/n] #########"
	read REBOOT
	if echo "$REBOOT" | grep -iq "^y" ;then
        	echo "Reiniciando en 15 segundos..."
		sleep 15
		shutdown -rf now
	fi

else
	echo "Kernel de CloudLinux detectado, reconfigurar/configurar por primera vez? [y/n]"
	read CL_CONFIGURE
fi

if echo "$CL_CONFIGURE" | grep -iq "^y" ;then
	echo "Configurando CloudLinux..."
else
	echo "Abortando."
	exit 0
fi

echo "Instalando CageFS..."
yum clean all -y
yum install cagefs -y
cagefsctl --init

if [ -d /etc/sssd/ ]; then
	echo "Deshabilitando SSSD temporalmente..."
	service sssd stop
fi

cagefsctl --enable-all

if [ -d /etc/sssd/ ]; then
	echo "Reactivando SSSD..."
	service sssd start
	sleep 10
fi

if [ -d /etc/sssd/ ]; then
	echo "Deshabilitando SSSD temporalmente..."
	service sssd stop
fi

cagefsctl --update
cagefsctl --force-update

if [ -d /etc/sssd/ ]; then
	echo "Reactivando SSSD..."
	service sssd start
fi

echo ""
echo "CageFS configurado!"
sleep 2

echo ""
echo "Configurando Apache/PHP con mod_lsapi..."
yum erase ea-apache24-mod_ruid2 -y
yum install ea-apache24-mod_lsapi liblsapi liblsapi-devel ea-apache24-mod_suexec -y
/usr/bin/switch_mod_lsapi --setup
/usr/bin/switch_mod_lsapi --enable-global

echo "Configurando php.inis..."
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^;memory_limit.*/memory_limit = 256M/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^memory_limit.*/memory_limit = 256M/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^enable_dl.*/enable_dl = off/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^expose_php.*/expose_php = off/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^disable_functions.*/disable_functions = apache_get_modules,apache_get_version,apache_getenv,apache_note,apache_setenv,disk_free_space,diskfreespace,dl,highlight_file,ini_alter,ini_restore,openlog,phpinfo,show_source,symlink,system,eval,debug_zval_dump/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^upload_max_filesize.*/upload_max_filesize = 16M/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^post_max_size.*/post_max_size = 16M/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^date.timezone.*/date.timezone = "America\/Argentina\/Buenos_Aires"/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^allow_url_fopen.*/allow_url_fopen = On/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^;max_execution_time.*/max_execution_time = 120/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^max_execution_time.*/max_execution_time = 120/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^;max_input_time.*/max_input_time = 120/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^max_input_time.*/max_input_time = 120/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^max_input_vars.*/max_input_vars = 2000/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^;default_charset = "UTF-8"/default_charset = "UTF-8"/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^default_charset = "UTF-8"/default_charset = "UTF-8"/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^error_reporting.*/error_reporting = "E_ALL \& \~E_DEPRECATED \& \~E_STRICT"/g'

echo "Configurando mod_lsapi..." 
sed -i 's/.*lsapi_enable_user_ini.*/lsapi_enable_user_ini\ On/' /etc/apache2/conf.d/lsapi.conf
sed -i 's/.*lsapi_user_ini_homedir.*/lsapi_user_ini_homedir\ On/' /etc/apache2/conf.d/lsapi.conf

service httpd restart

echo ""
echo "Apache/PHP configurado!"
sleep 2

echo ""
echo "Configurando SecureLink..."
sed -i '/^fs\.enforce_symlinksifowner.*/d' /etc/sysctl.conf
sed -i '/^fs\.protected_symlinks_create.*/d' /etc/sysctl.conf
sed -i '/^fs\.protected_hardlinks_create.*/d' /etc/sysctl.conf

echo "# CloudLinux SecureLink" >> /etc/sysctl.conf
echo "fs.enforce_symlinksifowner=1" >> /etc/sysctl.conf
echo "fs.protected_symlinks_create=1" >> /etc/sysctl.conf
echo "fs.protected_hardlinks_create=1" >> /etc/sysctl.conf

sysctl -p

echo ""
echo "SecureLink configurado!"
sleep 2

echo ""
echo "Instalando MySQL Governor..."
yum install governor-mysql -y
sed -i '/^fs\.suid_dumpable.*/d' /etc/sysctl.conf
echo "fs.suid_dumpable=1 # CloudLinux MySQL Governor" >> /etc/sysctl.conf
sysctl -p

/usr/share/lve/dbgovernor/mysqlgovernor.py --mysql-version 'mariadb101'
/usr/share/lve/dbgovernor/mysqlgovernor.py --install
sed -i 's/<lve\ use=.*/<lve\ use=\"all\"\/>/' /etc/container/mysql-governor.xml
service db_governor restart

echo ""
echo "MySQL Governor configurado!"
sleep 2

echo ""

if [ -d /etc/csf ]; then
	echo "Configurando CSF..."
	sed -i 's/^PT_USERMEM = .*/PT_USERMEM = "0"/g' /etc/csf/csf.conf
	sed -i 's/^PT_USERTIME = .*/PT_USERTIME = "0"/g' /etc/csf/csf.conf
	sed -i 's/^PT_USERPROC = .*/PT_USERPROC = "0"/g' /etc/csf/csf.conf

	csf -r

	echo "CSF configurado!"
	sleep 2
fi

whmapi1 update_featurelist featurelist=disabled lvephpsel=0 lvepythonsel=0 lverubysel=0

echo "Configurando limites DEFAULT..."
lvectl set default --speed=100% --io=1024 --nproc=60 --pmem=1024M --iops=1024 --maxEntryProcs=20

echo "Deshabilitando control de memoria de Apache..."
touch $CWD/wpwhmcookie.txt
SESS_CREATE=$(whmapi1 create_user_session user=root service=whostmgrd)
SESS_TOKEN=$(echo "$SESS_CREATE" | grep "cp_security_token:" | cut -d':' -f2- | sed 's/ //')
SESS_QS=$(echo "$SESS_CREATE" | grep "session:" | cut -d':' -f2- | sed 's/ //' | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g')

curl -sk "https://127.0.0.1:2087/$SESS_TOKEN/login/?session=$SESS_QS" --cookie-jar $CWD/wpwhmcookie.txt > /dev/null
curl -sk "https://127.0.0.1:2087/$SESS_TOKEN/scripts2/save_apache_mem_limits" --cookie $CWD/wpwhmcookie.txt --data 'newRLimitMem=disabled&restart_apache=on&btnSave=1' > /dev/null

echo ""
echo "###### Terminado! ######"

