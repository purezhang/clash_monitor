#!/bin/bash

#set -x

# clash_monitor_crontab=$(crontab -l|grep clash_monitor)
# if [[ -z $clash_monitor_crontab ]];then
#   echo "* * * * * bash /root/clash-linux/clash_monitor.sh" >> 


# 定义基础变量
clash_base_folder=/root/clash-linux
clash_subscribe_bak=${clash_base_folder}/clash_subscribe_bak/$(date +"%Y-%m")
clash_log_folder="/data/disk-wd4t-1/DataBackup/run_log/clash-log/$(date +"%Y-%m")"
clash_subscribe_link="https://api.stentvessel.top/sub?target=clash&new_name=true&emoji=true&clash.doh=true&filename=YToo_SS&udp=true&url=https%3A%2F%2Fapi.ytoo.xyz%2Fosubscribe.php%3Fsid%3D45965%26token%3D7CPH1p6Mrhv5%26sip002%3D1"
clash_reboot_at_time=0300
clash_subscribe_filesize_min=10000
clash_subscribe_update_time=3600


# 创建日志文件夹和日志文件
mkdir -p ${clash_log_folder}
mkdir -p ${clash_subscribe_bak}

clash_log_file_start=${clash_log_folder}/clash_log_file_start_$(date +%F).log
clash_log_file_run=${clash_log_folder}/clash_log_file_run_$(date +%F).log
echo -------------- clash_log_file: ------------------
echo -e "clash_log_file_start: \t$clash_log_file_start" | tee -a $clash_log_file_start
echo -e "clash_log_file_run: \t$clash_log_file_run" | tee -a $clash_log_file_start
echo ---------------------------------

# 更新订阅链接的函数
update_clash_subscribe() {
  subscribe_update_file=$clash_base_folder/clash-config-$(date "+%Y%m%d-%H%M%S").yaml
  curl --noproxy "*" $clash_subscribe_link -o $subscribe_update_file
  curl_exit_code=$?
  subscribe_new_filesize=$(ls -l $subscribe_update_file | awk -F " " '{print $5}')
  if [[ $subscribe_new_filesize -gt $clash_subscribe_filesize_min ]] && [[ $curl_exit_code=0 ]];then 
    mv ${clash_base_folder}/clash-config.yaml ${clash_subscribe_bak}/clash-config-$(date "+%Y%m%d-%H%M%S").yaml.bak
    mv $subscribe_update_file ${clash_base_folder}/clash-config.yaml
    echo -ne "$(date "+%F %T")\tsubscribe file update SECUESSED. subscribe_new_filesize:$subscribe_new_filesize. curl_exit_code: $curl_exit_code. " | tee -a $clash_log_file_start
  else
    rm -rf $subscribe_update_file
    echo -ne "$(date "+%F %T")\tSubscribe file update FAILD! Wait next time update. Subscribe_new_filesize: $subscribe_new_filesize. curl_exit_code: $curl_exit_code. " | tee -a $clash_log_file_start
  fi
}

# 获取Clash进程ID的函数
get_clash_pid() {
  clash_pid=$(pgrep -f "/root/clash-linux/clash-config")
  clash_threads_count=$(echo "$clash_pid" | wc -l)
}

# 检查并处理多个Clash进程的情况
get_clash_pid


debug(){
echo $clash_pid
echo $clash_threads_count
}

if [[ $clash_threads_count -gt 1 ]]; then
  echo -e "$(date "+%F %T")\tWarning !!! Clash Muti Threads. Count: $clash_threads_count" | tee -a $clash_log_file_start
  echo -e "$(date "+%F %T")\tNow Kill clash and Restart it." | tee -a $clash_log_file_start
  echo -e "$(date "+%F %T")\tCurrent clash pid: \r$clash_pid" | tee -a $clash_log_file_start
  echo -e "$(date "+%F %T")\tNow Kill All clash..." | tee -a $clash_log_file_start
  for PID in "$clash_pid"
    do
      ps -eo pid,lstart,cmd | grep -v grep | grep "/root/clash-linux/clash-config.yaml" | tee -a $clash_log_file_start
      echo -e "$(date "+%F %T")\tkill $PID"  | tee -a $clash_log_file_start
      kill $PID
  done
    echo -e "$(date "+%F %T")\tRestart clash, ${clash_base_folder}/clash-linux -d ${clash_base_folder}/ -f ${clash_base_folder}/clash-config.yaml >> $clash_log_file_run 2>&1 &"
    ${clash_base_folder}/clash-linux -d ${clash_base_folder}/ -f ${clash_base_folder}/clash-config.yaml >> $clash_log_file_run 2>&1 &
    get_clash_pid
    echo -e "$(date "+%F %T")\tclash-linux restarted. clash-pid: $clash_pid" | tee -a $clash_log_file_start
fi


# 每天凌晨3点重启clash进程
if [[ $(date +%H%M) -eq $clash_reboot_at_time ]] && [[ -n $clash_pid ]]; then
  echo -e "$(date "+%F %T")\tRestarting Clash" | tee -a $clash_log_file_start
  kill $clash_pid
  sleep 1
  ${clash_base_folder}/clash-linux -d ${clash_base_folder}/ -f ${clash_base_folder}/clash-config.yaml >> $clash_log_file_run 2>&1 &
  get_clash_pid
  echo -e "$(date "+%F %T")\tclash-linux restarted. clash-pid: $clash_pid" | tee -a $clash_log_file_start
fi

# 检查clash-config.yaml是否超过1小时未更新
clash_subscribe_file_time=$(stat -c %Y ${clash_base_folder}/clash-config.yaml)
now_time_utc=$(date +%s)
clash_subscribe_file_older_time=$(( now_time_utc - clash_subscribe_file_time ))

if [[ $clash_subscribe_file_older_time -gt $clash_subscribe_update_time ]]; then
  echo -e "$(date "+%F %T")\tUpdating clash-config.yaml as it is older than 1 hour ($clash_subscribe_file_older_time sec)." | tee -a $clash_log_file_start
  update_clash_subscribe
else
  echo -e "$(date "+%F %T")\tclash-config.yaml update passed: $(( now_time_utc - clash_subscribe_file_time )) sec." | tee -a $clash_log_file_start
fi

# 检查Clash进程是否存在，如果不存在则启动
get_clash_pid
if [[ -z $clash_pid ]]; then
  echo -e "$(date "+%F %T")\tClash is NOT EXIST !!, Starting CLASH Now..." | tee -a $clash_log_file_start
  ${clash_base_folder}/clash-linux -d ${clash_base_folder}/ -f ${clash_base_folder}/clash-config.yaml >> $clash_log_file_run 2>&1 &
  get_clash_pid
  echo -e "$(date "+%F %T")\tClash start done. Clash_Pid: $clash_pid " | tee -a $clash_log_file_start
  echo -e "$(date "+%F %T")\tClash Thread Status: $(ps -eo lstart,cmd | grep -v grep | grep "/root/clash-linux/clash-config.yaml")" | tee -a $clash_log_file_start
else
  get_clash_pid
  echo -e "$(date "+%F %T")\tClash OK, Pid: $clash_pid " | tee -a $clash_log_file_start
  echo -e "$(date "+%F %T")\tClash Thread Status: $(ps -eo lstart,cmd | grep -v grep | grep "/root/clash-linux/clash-config.yaml")" | tee -a $clash_log_file_start
fi
echo -e "\r\r\n\n" >> $clash_log_file_start
echo -e "\r\r\n\n" >> $clash_log_file_run
