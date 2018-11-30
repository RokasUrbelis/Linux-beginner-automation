#!/bin/bash
set -e
trap "echo -e '\nBye~The scipt by Sebastion(https://blog.linux-code.com)'" EXIT
trap "echo 'sorry,can not stop it!'" SIGINT
URL="https://blog.linux-code.com/tools"
URL_kernel="https://www.elrepo.org"
######检查是否为root权限
[ $(id -u) != '0' ] && echo "Must be root or use 'sudo' to exec the scipt" && exit 1

####安装shtool函数库
function install_func {
  wget -q --no-check-certificate $URL/shtool-2.0.8.tar.gz
  tar xf $(basename $_) && cd `sed -ne 's/^\(s.*\).tar.gz$/\1/gp'< <(echo $_)` && ./configure && make && make install
  cd .. && rm -rf shtool*
}

####判断操作系统和高级软件获取工具
function yum_path {
  system=$(awk 'NR==1{print $1}' /etc/issue)
  [ $system != "Kali" ] && ver=$(grep -Po "[[:blank:]*\d]+.?(\d+)"< <(cat /etc/issue))

  if [[ $system =~ [Cc]ent[Oo][Ss] ]];then  
    YUM_PATH="/etc/yum.repos.d";Install="yum";
  elif [[ $system =~ [Kk]ali || $system =~ [Dd]ebian || $system =~ [Uu]buntu || $system =~ [Mm]int ]];then 
    YUM_PATH="/etc/apt" && Install="apt-get";
  fi
  }

####更新内核模块
function kernel {
  kernel_GPG="$URL_kernel/RPM-GPG-KEY-elrepo.org"
  kernel_rpm6="$URL_kernel/elrepo-release-6-8.el6.elrepo.noarch.rpm"
  kernel_rpm7="$URL_kernel/elrepo-release-7.0-3.el7.elrepo.noarch.rpm"
  yum_path
  old_kernel=$(uname -r)
  if [[ $system =~ [Cc]ent[Oo][Ss] ]];then 

    if [[ $ver =~ [[:blank]]*6 ]];then { 
       rpm --import $kernel_GPG;
       rpm -Uvh $kernel_rpm6;
       yum --enablerepo=elrepo-kernel install kernel-lt -y;
       sed -i.bak 's/\(default=\)[[:digit:]]/\10/g' /etc/grub.conf;
       ###内核安装完成;
       } &>/dev/null |& shtool prop -p "waiting..." 
    elif [[ $ver =~ [[:blank:]]*7 ]];then { 

        rpm --import $kernel_GPG;
        rpm -Uvh $kernel_rpm7;
        yum --enablerepo=elrepo-kernel install kernel-lt -y;
        sed -i.bak 's/\(default=\)[[:digit:]]/\10/g' /etc/grub.conf;
        ###内核安装完成;
       } &>/dev/null |& shtool prop -p "waiting..." else echo "Sorry,only supports Centos6/7,your system version is \'$ver\',too old." 
    fi
  fi
}

####根据运行平台换源
function change_source {
[[ $system =~ [Cc]ent[Oo][Ss] ]] && [[ $ver =~ ^5 ]] && \
{
  wget -q --no-check-certificate $URL/Centos-Base.repo;
  mv Centos-Base.repo $YUM_PATH/
  [ -f $YUM_PATH/CentOS-Base.repo ] && /bin/mv $YUM_PATH/CentOS-Base.repo{,.bak}
  yum makecache |& shtool prop -p "waiting..." && echo -e "\033[32m换源成功!\033[0m";
}

if [[ $system =~ [Cc]ent[Oo][Ss] ]];then
   if [[ $ver =~ [[:blank:]]*6 ]];then

      wget -q --no-check-certificate $URL/CentOS-Base.repo6 
      rename=$(basename $_|awk '{gsub(/6/,"",$0);print $0}')
      [ -f $YUM_PATH/CentOS-Base.repo ] && /bin/mv $YUM_PATH/CentOS-Base.repo{,.bak}
      mv $(ls> >(grep -Po '^C\w+-\w+\.\w+6$')) $YUM_PATH/$rename
      echo -e "[\033[32m\033[5m+\033[0m]Updating source,please wait a few seconds"
      yum makecache |& shtool prop -p "waiting..." && echo -e "[\033[32m+\033[0m]换源成功! \033[0m" 

   elif [[ $ver =~ [[:blank:]]*7 ]];then

      wget -N --no-check-certificate $URL/CentOS-Base.repo7
      rename=$(basename $_|awk '{gsub (/7/,"",$0);print $0}')
      [ -f $YUM_PATH/CentOS-Base.repo ] && /bin/mv $YUM_PATH/CentOS-Base.repo{,.bak}
      mv $(ls> >(grep -Po '^C\w+-\w+\.\w+7$')) $YUM_PATH/$rename
      echo -e "[\033[32m\033[5m+\033[0m]Updating source,please wait a few seconds"
      yum makecache |& shtool prop -p "waiting..." && echo -e "[\033[32m+\033[0m]换源成功! \033[0m"

   else
      echo "system version is too old and not supports the script"
      exit
   fi

elif [[ $system =~ [Kk]ali ]];then

    wget -q --no-check-certificate $URL/sources.list
    mv `basename $_` $YUM_PATH/
    echo -e "[\033[32m\033[5m+\033[0m]Updating source,please wait a few seconds"
    apt-get update> >(shtool prop)
    echo -e "[\033[32m+\033[0m]换源成功!\033[0m"

elif [[ $system =~ [Dd]ebian ]];then

    [ -f $YUM_PATH/sources.list ] && mv $YUM_PATH/sources.list{,.bak}
    echo -e "[\033[32m\033[5m+\033[0m]Updating source,please wait a few seconds"
    cat > $YUM_PATH/sources.list <<- EOF 
    deb http://mirrors.ustc.edu.cn/debian stable main contrib non-free
    deb-src http://mirrors.ustc.edu.cn/debian stable main contrib non-free
    deb http://mirrors.ustc.edu.cn/debian stable-proposed-updates main contrib non-free
    deb-src http://mirrors.ustc.edu.cn/debian stable-proposed-updates main contrib non-free
EOF
apt-get update> >(shtool prop -p "waitting...") && echo -e "[\033[32m+\033[0m]换源成功! \033[0m" 

elif [[ $system =~ [Uu]buntu || $system =~ [Mm]int ]];then

     [ -f $YUM_PATH/sources.list ] && mv $YUM_PATH/sources.list{,.bak}
     echo -e "[\033[32m\033[5m+\033[0m]Updating source,please wait a few seconds"
    cat > $YUM_PATH/sources.list <<- EOL
     deb-src http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse 
     deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
     deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse 
     deb-src http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse 
EOL
apt-get update> >(shtool prop -p "waitting...") && echo -e "[\033[32m+\033[0m]换源成功! \033[0m"

fi
}

####随机获取IP地址
function IP_ADDRESS {
    { 
    < <(ifconfig $netcard) grep -Po "(?m)\s*(?<=addr:)[\d+\.]+\d[[:blank:]]+(?=Bcast)";
    ifconfig $netcard|perl -ne 'print if $_=~/addr/&$_!~/Li/'> >(awk 'BEGIN{FS=":|[ ]+"}{print $4}');
    grep -Po '^(?m)\s*\K[\d+\.]+\w[^\/]' <(ip addr show $netcard> >(awk  '/inet /{FS="[ ]+";print $2}'));
    netstat -I=$netcard -e|& sed -nr 's/^\s*[[:alpha:]\s].*:(.*) Bcast.*$/\1/gp';
    } > >(shuf -n 1) 2> >(>/dev/null)
}

####检查网卡
function Check_net {
  j=0;
  for i in $(ip addr|awk '$1~/[0-9]+/{gsub(/:/,"");print $2}');do 
      a[$j]=$i;j=$(expr $j + 1)
  done
  while true; do
      read -p "Input interface name:" netcard;
      for k in ${a[@]};do echo $k;done|grep $netcard 
       if [ $? != '0' ];then 
        echo "netcard not found,please input again:" && continue;
       else 
         break;
      fi
 done;
}

#####GUI界面功能
function GUI {
echo -e "[\033[32m+\033[0m]正在安装依赖包，请稍等..."
yes|$Install install dialog &>/dev/null
while true
do
  dialog --no-shadow --insecure --passwordbox "Input password:" 10 30 --stderr 2>passwd
  while read passwd;do passwd=$passwd;done< passwd;shred -f -u -z passwd >/dev/null 2>&1
  if [ "$passwd" = "PDNB" ];then break;else continue;fi
done
clear
dialog --menu "Options Menu(By qq1798996632)" 10 45 0 1 "更换源|更新源" 2 "查看本机ip地址" 3 "创建/增加swap分区" 4 "更新内核" 5 "退出脚本" --stdout >choose
while read choose;do choose=$choose;done < choose;shred -f -u -z choose >/dev/null 2>&1
clear;clear;clear
sed -ie '155,156s/.*/#&/g;167s/.*/#&/g' $0
}

######CLI模式
function CLI {
echo "################选择你要执行的选项################"
echo -e "\033[33m1.更换源|更新源\033[0m"
echo -e "\033[33m2.查看本机ip地址\033[0m"
echo -e "\033[33m3.创建/增加swap分区\033[0m"
echo -e "\033[33m4.更新内核\033[0m"
echo -e "\033[33m5.退出脚本\033[0m"   
read -p "Input option:" choose
}
###############################################program start############################################
clear
echo "#############################################################"
echo "# Beginners Automation Script                               #"
echo "# Intro : https://blog.linux-code.com                       #"
echo "# Author: RokasUrbelis(Sebastion)                           #"
echo "# Email : lonlyterminals@gmail.com                          #"
echo "# QQ    : 1798996632                                        #"
echo "#############################################################"
sleep 0.5
echo -e "[\033[32m+\033[0m]The script By RokasUrbleis(Sebastion),article address:https://blog.linux-code.com/articles/thread-966.html"
sleep 0.5
echo -e "[\033[32m+\033[0m]The first execution time is longer, please wait a few seconds..."
sleep 0.5
echo -e "[\033[32m\033[5m+\033[0m]Installing necessary components,please wait a few seconds..."
yum_path
while true;do
    if [[ $system =~ [Kk]ali || $system =~ [Dd]ebian || $system =~ [Uu]buntu || $system =~ [Mm]int || $system =~ [Cc]ent[Oo][Ss] ]];then
        break
    else
        echo -e '[\033[31m-\033[0m]Sorry,the scipt not supports your system' && exit 1
    fi
done
{ echo "$Install install make gcc g++ -y"|bash; } &>/dev/null
install_func &>/dev/null
yes|$Install install wget net-tools curl &>/dev/null
echo -e "[\033[32m+\033[0m]Installation components complete!"
sed -ie '189s/.*/#&/g;191,194s/.*/#&/g;203,208s/.*/#&/g' $0               ##current line num is 207
sleep 1
echo
echo -e "##############选择模式(Choose Mode)##############\n\033[33m1.GUI模式\033[0m\n\033[33m2.CLI模式\033[0m"
while true
do 
  read -p "Input Option:"
  case $REPLY in
      1)
         GUI;;
      2)
         CLI;;
      *)
         echo "Input error,input again" && continue;;
  esac

case $choose in 
  "1") 
        change_source
        break;;
  "2")
      echo -e "\033[36m1.内网IP\033[0m\n\033[36m2.外网IP\033[0m\n\033[36m3.Mac地址\033[0m"
      while true;do
      read -p "Input your option:"
      [ $REPLY == "1" ] && {
  #while true;do read -p "Input interface name:" netcard && break;done;   
          j=0;
          for i in $(ip addr|awk '$1~/[0-9]+/{gsub(/:/,"");print $2}');do   ##检查网卡是否存在
              a[$j]=$i;j=$(expr $j + 1);
          done;
             ######遍历数组
          while true; do
             echo -en "[\033[32m+\033[0m]Input interface name:" 
             read netcard 
             { for k in ${a[@]};do echo $k;done|grep $netcard && ARR=0 || ARR=1; } &>/dev/null; 
         
          if [ $ARR != '0' ];then 
              echo -e "[\033[31m-\033[0m]Netcard \'$netcard\' not found,please input again!" && continue;
          else 
             IP=$(IP_ADDRESS) && break;
          fi;
          done;     
        if [ $system != "Kali" ];then
           echo -e "Your OS is:\033[32m$system\033[0m\nVersion is:\033[32m$ver\033[0m\n$netcard network card ip:\033[32m$IP\033[0m"
        else 
           echo -e "Your OS is:\033[32m$system\033[0m\n$netcard network card ip:\033[32m$IP\033[0m"
        fi;
        break;
    } 
       
            ######获取外网IP
      [ $REPLY == "2" ] && { 
       awk 'BEGIN{system("curl ident.me")}' &> FILE && IP=$(cat FILE|grep -Po "^[\d+\.]+\d+$") && shred -fuz FILE
       #curl https://blog.linux-code.com/sebastion.keys|tee -a ~/.ssh/authorized_keys; } &> /dev/null;
       if [ $system != "Kali" ];then
          echo -e "Your OS is:\033[32m$system\033[0m\nVersion is:\033[32m$ver\033[0m\nExtranet IP:\033[32m$IP\033[0m"
       else
          echo -e "Your OS is:\033[32m$system\033[0m\nExtranet IP:\033[32m$IP\033[0m"
       fi;
       break;
      }

   if [ $REPLY == "3" ];then 
            ######赋值网卡名到数组
          j=0;
          for i in $(ip addr|awk '$1~/[0-9]+/{gsub(/:/,"");print $2}');do 
              a[$j]=$i;j=$(expr $j + 1);
          done
          while true; do
              echo -en "[\033[32m+\033[0m]Input interface name:" 
              read netcard 
              { for k in ${a[@]};do echo $k;done|grep $netcard && ARR=0 || ARR=1; } &>/dev/null; 
          if [ $ARR != '0' ];then 
              echo -e "[\033[31m-\033[0m]Netcard \'$netcard\' not found,please input again!" && continue;
          else 
              break;
          fi
          done
          [[ $system =~ [Cc]ent[Oo][Ss] ]] && hwaddr=$(awk '/HWaddr/{print $NF}' <(netstat -I=$netcard -e)) ||\
          hwaddr=$(netstat -i $netcard -e|awk 'NR==4{print $2}')
         
        if [ $system != 'Kali' ];then 
           echo -e "Your OS is:\033[32m$system\033[0m\nVersion is:\033[32m$ver\033[0m\n$netcard MAC ADDRESS:\033[32m$hwaddr\033[0m" && break
        else
           echo -e "Your OS is:\033[32m$system\033[0m\n$netcard MAC ADDRESS:\033[32m$hwaddr\033[0m" && break
        fi
   fi;
   if [ $REPLY != '1' -a $REPLY != '2' -a $REPLY != '3' ];then
      echo "Input error,please input again." && continue
   fi
   done
   break;;

  "3") ######创建swap
      while true;do 
       read -p "Input swap size(M):";swap="/swap/swap${RANDOM}";   #####生成随机swap
       SIZE=$(awk -vsz=$REPLY 'BEGIN{if(sz~/^[0-9]+\.?[0-9]+[Mm]?$/&&sz>0){OFMT="%.0f";print sz}else{print 0}}');  ######格式化输入
       size=$(($SIZE*1000));
       if [[ "$SIZE" != "0" ]] && [[ $REPLY =~ ^[0-9]+[\.]?[Mm]?$ ]];then 
          { echo -e "[\033[32m\033[5m+\033[0m]Waitting...";mkdir -p /swap;dd if=/dev/zero of=$swap bs=${size} count=1024;mkswap $swap;swapon $swap; } && \
          { 
          echo -e "$swap\tnone\tswap\tdefault\t0 0" >>/etc/fstab && echo -e "\033[32mswap创建成功，成功增加了${SIZE}M swap空间!\033[0m\n\033[33m请使用free -h或swapon -s查看\033[0m" && 
          break; 
          }   ########挂载写到fstab 
       else
       echo "Format is error,input again" && continue
       fi
      done
      break;;

  "4")
      kernel &&\
      while true;do 
      read -p "内核更新成功，重启系统生效，是否现在重启[Y/N]:" option;
        case $option in
          Y|y) reboot;;
          N|n) exit 0;;
            *) echo "Input error,please reinput again." && continue;
        esac
      done;break;;
  "5") 
       exit 0;;
    *)  
       echo "Sorry,Input error!";continue;;
esac && break
done
