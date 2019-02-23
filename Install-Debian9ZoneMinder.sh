###################################################################################################$
# Author: Zewwy (Aemilianus Kehler)
# Date:   Feb 21, 2019
# Script: Install-Debian9ZoneMinder
# This script simplifies your Debian 9 ZoneMinder installation
#
# Required parameters:
#   This script and your debians server access to the internet :D
###################################################################################################$

####################################################################
# Variables
####################################################################
#MyLogoArray
declare -a MyLogoArray=(
    "              This script is brought to you by:              "
    "      ___         ___         ___         ___                "
    "     /  /\       /  /\       /__/\       /__/\        ___    "
    "    /  /::|     /  /:/_     _\_ \:\     _\_ \:\      /__/|   "
    "   /  /:/:|    /  /:/ /\   /__/\ \:\   /__/\ \:\    |  |:|   "
    "  /  /:/|:|__ /  /:/ /:/_ _\_ \:\ \:\ _\_ \:\ \:\   |  |:|   "
    " /__/:/ |:| //__/:/ /:/ //__/\ \:\ \:/__/\ \:\ \:\__|__|:|   "
    " \__\/  |:|/:\  \:\/:/ /:\  \:\ \:\/:\  \:\ \:\/:/__/::::\   "
    "     |  |:/:/ \  \::/ /:/ \  \:\ \::/ \  \:\ \::/\__\|~~\:\  "
    "     |  |::/   \  \:\/:/   \  \:\/:/   \  \:\/:/      \  \:\ "
    "     |  |:/     \  \::/     \  \::/     \  \::/        \__\/ "
    "     |__|/       \__\/       \__\/       \__\/               "
                )

ScriptName="Install-Debian9ZoneMinder; Cause this shit should have already been done."

red="           "$'\e[1;31m'
grn="           "$'\e[1;32m'
yel="           "$'\e[1;33m'
blu="           "$'\e[1;34m'
mag="           "$'\e[1;35m'
cyn="           "$'\e[1;36m'
end=$'\e[0m'

COLUMNS=$(tput cols)

LogPath=$(pwd)
LogFile="$LogPath/Install-DebianZoneMinder.log"
dt=$(date)
#######################################################################
# Functions
#######################################################################

Centeralize()
{
printf "%*s\n" $(((${#1}+$COLUMNS)/2)) "$1"
}

confirm ()
{
        read -p "$1 " answer
        case "$answer" in
                y|yes)
                return 1
                ;;
                n|no)
                return 2
                ;;
                *)
                confirm "$1"
                ;;
        esac

}

######################################################################
# Run Code
######################################################################

#################  Display My Logo ######################

for i in "${MyLogoArray[@]}"
do
   Centeralize "${grn}$i${end}"
done

################   Display Script Name #################

echo " "
Centeralize "$ScriptName"
echo " "
###   Check for root permissions   ###
if [[ $EUID -ne 0 ]]; then
   Centeralize  "${red}This script must be run as root!${end}"
   echo "$dt This script was stopped due to permissions, run this script as root!" >> $LogFile
   exit 1
fi

##############  Inject Backport repos ##################
# I decided to go with backport repo over iffy third party repos for stablity #

grep -hnr "stretch-backports" /etc/apt/sources.list > /dev/null
rslt=$?
        case $rslt in
                0)
                Centeralize "${grn}Appears Backports are already in Debians Sources.${end}"
                echo " "
                ;;
                1)
                Centeralize "${yel}Backports source repo missing, adding now...${end}"
                echo " "
                echo " " >> /etc/apt/sources.list
                echo "#These are the backport repos" >> /etc/apt/sources.list
                echo "deb http://deb.debian.org/debian stretch-backports main" >> //etc/apt/sources.list
                ;;
                *)
                echo "Umm what's in your sources?"
                ;;
        esac


################    Ask to update   #####################

confirm "System should be updated before moving on, update?"
   answer=$?
        case "$answer" in
                1)
                echo " "
                Centeralize "Updating Server... Please Wait."
                echo " "
                apt update >> $LogFile 2>> $LogFile
                apt upgrade >> $LogFile 2>> $LogFile
                apt dist-upgrade >> $LogFile 2>> $LogFile
                ;;
                2)
                echo " "
                Centeralize "I Hope you have your dependencies, else things may not work...."
                echo " "
                ;;
                *)
                echo "How'd this happen?"
                ;;
        esac

if [ $? -ne 0 ]
then
        Centeralize "${red}Something went during wrong the system updates, please check the logs.${end}"
        exit
fi

########### Past Updates, Install ZoneMiner  ######################

Centeralize "Installing ZoneMinder now... Please Wait"
echo " "
apt -y install zoneminder vlc-plugin-base php7.0-gd >> $LogFile 2>> $LogFile
if [ $? -ne 0 ]
then
        Centeralize "${red}Something went wrong during the ZoneMinder install, please check the logs.${end}"
        exit
fi
if [ $? -eq 0 ]
then
        Centeralize "${grn}Install of ZoneMinder succesful... Configuring${end}"
        echo " "
fi

############## ZoneMinder Installed, finalzing steps ##################

### Set conf permissions ###
chmod 740 /etc/zm/zm.conf >> $LogFile 2>> $LogFile
if [ $? -eq 0 ]
then
        echo "$dt /etc/zm/zm.conf permissions set to 740." >> $LogFile
else
        Centeralize "${red}Something went wrong setting the permission to 740 on /etc/zm/zm.conf.${end}"
        echo " "
        echo "Something went wrong setting the permission to 740 on /etc/zm/zm.conf." >> $LogFile
        exit
fi


chown root:www-data /etc/zm/zm.conf >> $LogFile 2>> $LogFile
if [ $? -eq 0 ]
then
        echo "$dt /etc/zm/zm.conf owner set to root:www-data" >> $LogFile
else
        Centeralize "${red}Something went wrong setting the owner of /etc/zm/zm.conf.${end}"
        echo "Something went wrong setting the owner of /etc/zm/zm.conf" >> $LogFile
        exit
fi

### Set service boot ###
systemctl enable zoneminder.service >> $LogFile 2>> $LogFile
if [ $? -eq 0 ]
then
        echo "$dt ZoneMinder service has been set to start at boot." >> $LogFile
else
        Centeralize "${red}Something went wrong enabling service at boot.${end}"
        echo " "
        echo "Something went wrong setting the zm boot service." >> $LogFile
        exit
fi

### Add www-data to video group ###
adduser www-data video >> $LogFile 2>> $LogFile
if [ $? -eq 0 ]
then
        echo "$dt www-data to video group." >> $LogFile
else
        Centeralize "${red}Something went wrong adding www-data to video group.${end}"
        echo " "
        echo "Something went wrong adding www-data to video group." >> $LogFile
        exit
fi


### Configure Apache ###
a2enmod cgi >> $LogFile 2>> $LogFile
if [ $? -eq 0 ]
then
        echo "$dt Apache configured to use cgi" >> $LogFile
else
        Centeralize "${red}Something went wrong enabling Apache CGI.${end}"
        echo " "
        echo "$dt Something went wrong enabling Apache CGI." >> $LogFile
        exit
fi

a2enmod rewrite >> $LogFile 2>> $LogFile
if [ $? -eq 0 ]
then
        echo "$dt Apache rewrite module has been enabled." >> $LogFile
else
        Centeralize "${red}Something went wrong enabling Apache rewrite.${end}"
        echo " "
        echo "$dt Something went wrong enabling the Apache rewrite module." >> $LogFile
        exit
fi

a2enconf zoneminder >> $LogFile 2>> $LogFile
if [ $? -eq 0 ]
then
        echo "$dt Apache ZoneMiner plugin enabled." >> $LogFile
else
        Centeralize "${red}Something went wrong enabling the Apache ZoneMinder Plugin.${end}"
        echo "Something went wrong enabling the Apache ZoneMinder Plugin." >> $LogFile
        exit
fi

### add timezone to PHP?? unno w/e ###
Centeralize "You know, PHP TimeZone stuff...."
echo " "
sed -i "s/;date.timezone =/date.timezone = $(sed 's/\//\\\//' /etc/timezone)/g" /etc/php/7.0/apache2/php.ini

### change owner on zonminder dir, again unno just following the guides ###
Centeralize "You know, share dir owner stuff...."
echo " "
chown -R www-data:www-data /usr/share/zoneminder/

### Finally restart Apache ###
Centeralize "Restart Apache..."
echo " "
service apache2 restart

mysql_secure_installation

Centeralize "${grn}SQL Server Config Completed${end}"
echo " "
Centeralize "${blu}Creating zm SQL Account.${end}"
Centeralize "Please enter the SQL admin password you just created."
mysql -uroot -p < /usr/share/zoneminder/db/zm_create.sql
Centeralize "${blu}Granting zm SQL Account permissions on ZM DB.${end}"
Centeralize "Please enter the SQL admin password you just created."
mysql -uroot -p -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';"
Centeralize "${blu}Reload SQL service.${end}"
Centeralize "Please enter the SQL admin password you just created."
mysqladmin -uroot -p reload
Centeralize "${grn}Installation Completed, starting ZM service.${end}"
service zoneminder start
