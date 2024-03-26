【new】
```
1，定时重启，默认凌晨3点
2，定时更新，默认1小时，目前没定义变量
```



【how to use】
```
# crontab -e
```

添加以下内容：
```
# clash-linux，每分钟检查进程，1小时更新订阅，每天3点重启
* * * * * bash /root/clash-linux/clash_monitor.sh
```
