<h1>cPanel CloudLinux Installer</h1>
<p>Este script instala y configura CloudLinux con los par&aacute;metros recomendados por WNPower</p>
<p>Este script requiere que se ejecute dos veces:</p>
<ol>
<li>La primera instala los paquetes b&aacute;sicos de CloudLinux y el kernel customizado de CloudLinux (al finalizar reinicia el servidor para aplicar los cambios)</li>
<li>Una vez reiniciado hay que ejecutarlo una segunda vez para que configure todos los servicios de CloudLinux</li>
</ol>
<p>wget&nbsp;https://raw.githubusercontent.com/imorandinwnp/cPanel-CloudLinux/master/install_cloudlinux.sh&nbsp;&amp;&amp; bash install_cloudlinux.sh</p>
<p><em>NOTA: Ten&eacute; la licencia activa antes de iniciar el instalador:&nbsp;https://cln.cloudlinux.com/</em></p>
<h3>Tareas que realiza</h3>
<ul>
<li>Instala CloudLinux <strong>sobre cPanel (en modo licenciamiento por Key o por IP, pregunta durante la instalaci&oacute;n)</strong></li>
<li>Instala y configura CageFS:&nbsp;<a href="https://docs.cloudlinux.com/index.html?cagefs.html">https://docs.cloudlinux.com/index.html?cagefs.html</a></li>
<li>Configura Apache con mod_lsapi:&nbsp;<a href="https://docs.cloudlinux.com/index.html?apache_mod_lsapi.html">https://docs.cloudlinux.com/index.html?apache_mod_lsapi.html</a></li>
<li>Configura todos los php.ini con los par&aacute;metros recomendados</li>
<li>Configura SecureLink:&nbsp;<a href="https://www.cloudlinux.com/getting-started-with-cloudlinux-os/41-security-features/933-activating-securelink">https://www.cloudlinux.com/getting-started-with-cloudlinux-os/41-security-features/933-activating-securelink</a></li>
<li>Instala y configura MySQL Governor:&nbsp;<a href="https://docs.cloudlinux.com/index.html?mysql_governor.html">https://docs.cloudlinux.com/index.html?mysql_governor.html</a></li>
<li>Configura par&aacute;metros de CSF&nbsp;</li>
</ul>
