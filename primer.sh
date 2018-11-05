#!/bin/bash
set -e
trap "echo -e '\nBye~The scipt by Sebastion(https://blog.linux-code.com)'" EXIT
trap "echo 'sorry,can not stop it!'" SIGINT
URL="https://blog.linux-code.com/tools"
######检查是否为root权限
[ $(id -u) != '0' ] && echo "Must be root or use 'sudo' to exec the script" && exit 1

####安装shtool函数库
function install_func {
  wget -q --no-check-certificate $URL/shtool-2.0.8.tar.gz
  tar xf $(basename $_) && cd `sed -ne 's/^\(s.*\).tar.gz$/\1/gp'< <(echo $_)` && ./configure && make && make install
  cd .. && rm -rf shtool*
}

####判断操作系统和高级软件获取工具
function yum_path {
  system=$(awk '{print $1}'< <(shtool platform))
  ver=$(shtool platform> >(awk '{print $2}'))
  if [ $system = "centos" ];then 
    YUM_PATH="/etc/yum.repos.d";Install="yum";
  elif [[ $system =~ [kK]ali ]] || [ $system == "Debian" -o $system == "Ubuntu" ];then YUM_PATH="/etc/apt" && Install="apt-get";
  fi
 }

####更新内核模块
function kernel {
  kernel_GPG="$URL/RPM-GPG-KEY-elrepo.org"
  kernel_rpm6="$URL/elrepo-release-6-8.el6.elrepo.noarch.rpm"
  kernel_rpm7="$URL/elrepo-release-7.0-3.el7.elrepo.noarch.rpm"
  yum_path
  old_kernel=$(uname -r)
  if [ $system == "centos" ];then 

    if [[ $ver =~ ^6 ]];then { 
       rpm --import $kernel_GPG;
       rpm -Uvh $kernel_rpm6;
       yum --enablerepo=elrepo-kernel install kernel-lt -y;
       sed -i.bak 's/\(default=\)[[:digit:]]/\10/g' /etc/grub.conf;
       ###内核安装完成;
       } &>/dev/null |& shtool prop -p "waiting..." 
    elif [[ $ver =~ ^7 ]];then { 

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
[ $system == "centos" ] && [[ $ver =~ ^5 ]] && \
{
  wget -q --no-check-certificate $URL/Centos-Base.repo;
  mv $YUM_PATH/Centos-Base.repo{.bak} && mv Centos.Base.repo $YUM_PATH/;
  yum makecache |& shtool prop -p "waiting..." && echo -e "\033[32m换源成功!\033[0m";
}

if [ $system == "centos" ];then
   if [[ $ver =~ ^6 ]];then
      wget -q --no-check-certificate $URL/Centos-Base.repo6 
      rename=$(basename $_|awk '{gsub (6,"",$0);print}')
      mv $(ls> >(grep -Po '^C\w+-\w+\.\w+6$')) $YUM_PATH/$rename
      yum makecache |& shtool prop -p "waiting..." && echo -e "\033[32m换源成功!\033[0m" 
   elif [[ $ver =~ ^7 ]];then
      wget -N --no-check-certificate $URL/Centos-Base.repo7 
      rename=$(basename $_|awk '{gsub (7,"",$0);print}')
      mv $(ls> >(grep -Po '^C\w+-\w+\.\w+7$')) $YUM_PATH/$rename
      yum makecache |& shtool prop -p "waiting..." && echo -e "\033[32m换源成功!\033[0m"
   else
      echo "system version is too old and not supports the script"
      exit
   fi
elif [ $system == "kali" ];then
    wget -q --no-check-certificate $URL/sources.list
    mv `basename $_` $YUM_PATH/
    apt-get update> >(shtool prop)
    echo -e "\033[32m换源成功!\033[0m"
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
echo "正在安装依赖包，请稍等..."
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
clear
clear
}

######CLI模式
function CLI {
echo "##################选择你要执行的选项##################"
echo -e "\033[33m1.更换源|更新源\033[0m"
echo -e "\033[33m2.查看本机ip地址\033[0m"
echo -e "\033[33m3.创建/增加swap分区\033[0m"
echo -e "\033[33m4.更新内核\033[0m"
echo -e "\033[33m5.退出脚本\033[0m"   
read -p "Input option:" choose
}

####################program start#########################
echo "The first execution time is longer, please wait a few seconds..."
install_func &>/dev/null
yum_path
yes|$Install install wget net-tools curl &>/dev/null
sed -i '/依赖包/s/.*/#&/g;/execution/s/.*/#&/g' $0
sed -i 's/^yes/#&/g;s/^ins/#&/g' $0  ##注释函数安装与工具安装
clear 
echo -e "##############选择模式\n\033[33m1.GUI模式\033[0m\n\033[33m2.CLI模式\033[0m"
while true
do 
  read -p "Input Option:"
  case $REPLY in
      1)
         GUI && break;;
      2)
         CLI && break;;
      *)
         echo "Input error,input again" && continue;;
  esac
done

case $choose in 
  "1") 
        change_source;;
  "2")
      echo -e "\033[36m1.内网IP\033[0m\n\033[36m2.外网IP\033[0m\n\033[36m3.Mac地址\033[0m"
      read -p "Input your option:"
      [ $REPLY == "1" ] && {
  #while true;do read -p "Input interface name:" netcard && break;done;   
          j=0;
          for i in $(ip addr|awk '$1~/[0-9]+/{gsub(/:/,"");print $2}');do   ##检查网卡是否存在
              a[$j]=$i;j=$(expr $j + 1);
          done;
             ######遍历数组
          while true; do
              read -p "Input network interface name:" netcard
              for k in ${a[@]};do echo $k;done|grep $netcard &>/dev/null 

          if [ $? != '0' ];then 
              echo "netcard $netcard not found,please input again:" && continue;
          else 
             IP=$(IP_ADDRESS) && break;
          fi;
          done;     
        echo -e "Your OS is:\033[32m$system\033[0m\nVersion is \033[32m$ver\033[0m\n$netcard network card ip:\033[32m$IP\033[0m"; 
    } 

            ######获取外网IP
      [ $REPLY == "2" ] && {
       curl ident.me &>ip_file && IP=$(while read line;do awk '$1~/[[:digit:]+\.]+[0-9]+/{print}' $line;done< <(echo ip_file)) && shred -fuz ip_file;
         #curl https://blog.linux-code.com/sebastion.keys|tee -a ~/.ssh/authorized_keys; } &> /dev/null;
        echo -e "Your OS is:\033[32m$system\033[0m\nVersion is \033[32m$ver\033[0m\nExtranet IP:\033[32m$IP\033[0m"; 
      }

   if [ $REPLY == "3" ];then 
            ######赋值网卡名到数组
          clear
          j=0;
          for i in $(ip addr|awk '$1~/[0-9]+/{gsub(/:/,"");print $2}');do 
              a[$j]=$i;((j++));              ##j=$(expr $j + 1)
          done
            ######遍历数组
          while true; do
              read -p "Input interface name:" netcard 
              for k in ${a[@]};do echo $k;done|grep $netcard &>/dev/null; 
          if [ $? != '0' ];then 
              echo "netcard $netcard not found,please input again:" && continue;
          else 
            break;
          fi
          done
          hwaddr=$(awk '/HWaddr/{print $NF}' <(netstat -I=$netcard -e)) ######赋值mac地址

         echo -e "Your OS is:\033[32m$system\033[0m\nVersion is \033[32m$ver\033[0m\nMAC ADDRESS:\033[32m$hwaddr\033[0m"
     fi;;

  "3") ######创建swap
      while true;do 
       read -p "Input swap size(M):";swap="/swap/swap${RANDOM}";   #####生成随机swap
       SIZE=$(awk -vsz=$REPLY 'BEGIN{if(sz~/^[0-9]+\.?[0-9]+[Mm]?$/&&sz>0){OFMT="%.0f";print sz}else{print 0}}');  ######格式化输入
       size=$(($SIZE*1000));
       if [[ "$SIZE" != "0" ]] && [[ $REPLY =~ ^[0-9]+[\.]?[Mm]?$ ]];then 
          { echo "waitting...";mkdir -p /swap;dd if=/dev/zero of=$swap bs=${size} count=1024|& shtool prop -p "waiting...";mkswap $swap;swapon $swap; } && \
          { 
          echo -e "$swap\tnone\tswap\tdefault\t0 0" >>/etc/fstab && echo -e "\033[32mswap创建成功，成功增加了${SIZE}M swap空间!\033[0m\n\033[33m请使用free -h或swapon -s查看\033[0m" && 
          break; 
          }   ########挂载写到fstab 
       else
       echo "Format is error,input again" && break
       fi
      done;;

  "4")
      kernel &&\
      while true;do 
      read -p "内核更新成功，重启系统生效，是否现在重启[Y/N]:" option;
        case $option in
          Y|y) reboot;;
          N|n) exit 0;;
            *) echo "Input error,please reinput again." && continue;
        esac
      done;;
  "5") 
       exit 0;;
    *)  echo "Sorry,Input error!";;
esac
