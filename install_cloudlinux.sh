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
	rm -f /var/cpanel/nocloudlinux # BORRO FLAG QUE DEJA EL INSTALADOR DE CPANEL
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

echo "Instalando LVE Manager..."
yum install lvemanager -y

echo "Instalando CageFS..."
echo "Desactivando Shell Fork Bomb Protection..."
/usr/local/cpanel/bin/install-login-profile --uninstall limits
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

echo "Activando rsync..."
cagefsctl --addrpm rsync
cagefsctl --update

echo "Activando permisos para wget y curl..."
# NO TIENE PERMISOS DE EJECUCION PARA TODOS POR DEFAULT, SE LE DA PERMISOS
chmod 755 /usr/bin/wget
chmod 755 /usr/bin/curl 

cagefsctl --update
cagefsctl --force-update

rm -f /etc/cagefs/exclude/excluded_users
awk -F':' '/wheel/{print $4}' /etc/group | while read ADMIN_USER
do
        echo "Deshabilitando CageFS para $ADMIN_USER..."
        cagefsctl --disable $ADMIN_USER
        echo "$ADMIN_USER" >> /etc/cagefs/exclude/excluded_users
done
chmod 600 /etc/cagefs/exclude/excluded_users

if [ -d /etc/sssd/ ]; then
	echo "Reactivando SSSD..."
	service sssd start
fi

echo ""
echo "CageFS configurado!"
sleep 2

echo ""
echo "Configurando Apache/PHP con mod_lsapi..."
whmapi1 php_set_default_accounts_to_fpm default_accounts_to_fpm=0 # DESACTIVAR FPM SI LO TENIA DE ANTES
yum erase ea-apache24-mod_ruid2 -y
yum install ea-apache24-mod_lsapi liblsapi liblsapi-devel ea-apache24-mod_suexec -y
/usr/bin/switch_mod_lsapi --setup
/usr/bin/switch_mod_lsapi --enable-global

echo "Configurando php.inis..."
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^;memory_limit.*/memory_limit = 1024M/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^memory_limit.*/memory_limit = 1024M/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^enable_dl.*/enable_dl = Off/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^expose_php.*/expose_php = Off/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^disable_functions.*/disable_functions = apache_get_modules,apache_get_version,apache_getenv,apache_note,apache_setenv,disk_free_space,diskfreespace,dl,exec,highlight_file,ini_alter,ini_restore,openlog,passthru,phpinfo,popen,posix_getpwuid,proc_close,proc_get_status,proc_nice,proc_open,proc_terminate,shell_exec,show_source,symlink,system,eval,debug_zval_dump/g'
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
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^error_reporting.*/error_reporting = E_ALL \& \~E_DEPRECATED \& \~E_STRICT/g'
find /opt/ /etc/ \( -name "php.ini" -o -name "local.ini" \) | xargs sed -i 's/^display_errors.*/display_errors = On/g'

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
sed -i '/^fs\.protected_hardlinks_allow_gid.*/d' /etc/sysctl.conf
sed -i '/^fs\.protected_symlinks_allow_gid.*/d' /etc/sysctl.conf

echo "# CloudLinux SecureLink" >> /etc/sysctl.conf
echo "fs.enforce_symlinksifowner=1" >> /etc/sysctl.conf
echo "fs.protected_symlinks_create=1" >> /etc/sysctl.conf
echo "fs.protected_hardlinks_create=1" >> /etc/sysctl.conf

LINKSAFE_GID=$(getent group linksafe | cut -d':' -f3)

echo "fs.protected_hardlinks_allow_gid = $LINKSAFE_GID" >> /etc/sysctl.conf
echo "fs.protected_symlinks_allow_gid = $LINKSAFE_GID" >> /etc/sysctl.conf

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

MYSQLVER=$(grep "mysql-version" /var/cpanel/cpanel.config | cut -d'=' -f2 | sed 's/\.//')
MYSQLVENDOR=$(echo $MYSQLVER | grep "^5.*" > /dev/null && echo mysql || echo mariadb)

/usr/share/lve/dbgovernor/mysqlgovernor.py --mysql-version "$MYSQLVENDOR$MYSQLVER"
/usr/share/lve/dbgovernor/mysqlgovernor.py --install
sed -i 's/<lve\ use=.*/<lve\ use=\"all\"\/>/' /etc/container/mysql-governor.xml
service db_governor restart

mv /usr/lib/systemd/system/mysqld.service /usr/lib/systemd/system/mysqld.service.bak # BUG https://forums.cpanel.net/threads/multiple-mysql-processes.572331/
mv /usr/lib/systemd/system/mariadb.service /usr/lib/systemd/system/mariadb.service.bak # BUG https://forums.cpanel.net/threads/multiple-mysql-processes.572331/

systemctl daemon-reload

/scripts/restartsrv_mysql

mysql_upgrade

whmapi1 configureservice service=db_governor enabled=1 monitored=1

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
lvectl set default --speed=100% --io=2048 --nproc=45 --vmem=0 --pmem=1024M --iops=768 --maxEntryProcs=30

echo "Deshabilitando control de memoria de Apache..."
touch $CWD/wpwhmcookie.txt
SESS_CREATE=$(whmapi1 create_user_session user=root service=whostmgrd)
SESS_TOKEN=$(echo "$SESS_CREATE" | grep "cp_security_token:" | cut -d':' -f2- | sed 's/ //')
SESS_QS=$(echo "$SESS_CREATE" | grep "session:" | cut -d':' -f2- | sed 's/ //' | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g')

curl -sk "https://127.0.0.1:2087/$SESS_TOKEN/login/?session=$SESS_QS" --cookie-jar $CWD/wpwhmcookie.txt > /dev/null
curl -sk "https://127.0.0.1:2087/$SESS_TOKEN/scripts2/save_apache_mem_limits" --cookie $CWD/wpwhmcookie.txt --data 'newRLimitMem=disabled&restart_apache=on&btnSave=1' > /dev/null

echo "Configurando opciones LVE Manager..."
sed -i '/^lve_enablepythonapp/d' /var/cpanel/cpanel.config
sed -i '/^lve_enablerubyapp/d' /var/cpanel/cpanel.config
sed -i '/^lve_hideextensions/d' /var/cpanel/cpanel.config
sed -i '/^lve_hideuserstat/d' /var/cpanel/cpanel.config
sed -i '/^lve_showinodeusage/d' /var/cpanel/cpanel.config

echo "lve_enablepythonapp=0" >> /var/cpanel/cpanel.config
echo "lve_enablerubyapp=0" >> /var/cpanel/cpanel.config
echo "lve_hideextensions=1" >> /var/cpanel/cpanel.config
echo "lve_hideuserstat=0" >> /var/cpanel/cpanel.config
echo "lve_showinodeusage=1" >> /var/cpanel/cpanel.config

echo "Desactivando vestigios de alt-php..."
sed -i 's/yes/no/g' /opt/alt/alt-php-config/alt-php.cfg
/opt/alt/alt-php-config/multiphp_reconfigure.py

echo "Desactivando JailShell por default (para que use Bash)..."
whmapi1 set_tweaksetting key=jaildefaultshell value=0

echo "Desactivando PHP Selector..."
cloudlinux-selector set --interpreter php --selector-status=disabled --json

echo "Configurando PAM..."
sed -i "s/.*pam_lve.so.*/session\trequired\tpam_lve.so\t500\t1\twheel/" /etc/pam.d/sshd

echo ""
echo "###### Terminado! ######"

