   #!/bin/bash

   # 日志函数
   log() {
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> run_log.txt
       echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
   }

   # 定义多组账号信息
   declare -A ACCOUNTS=(
       ["account1"]="TASK_ID=123 FLOCK_API_KEY=key1 HF_TOKEN=token1 HF_USERNAME=user1"
       ["account2"]="TASK_ID=456 FLOCK_API_KEY=key2 HF_TOKEN=token2 HF_USERNAME=user2"
       ["account3"]="TASK_ID=789 FLOCK_API_KEY=key3 HF_TOKEN=token3 HF_USERNAME=user3"
   )

   # 运行时间(分钟)
   RUN_TIME=480

   # 运行函数
   run_task() {
       local account_name=$1
       local account_info=${ACCOUNTS[$account_name]}
       
       log "Starting task with $account_name"
       
       # 创建运行脚本
       cat << EOF > run_training_node.sh
#!/bin/bash
source "$MINICONDA_PATH/bin/activate" training-node
CUDA_VISIBLE_DEVICES=0 $account_info python full_automation.py
EOF
       
       chmod +x run_training_node.sh
       
       # 使用 PM2 启动训练节点
       pm2 start run_training_node.sh --name "flock-training-node-$account_name" -- start
       pm2 save
       
       log "Started PM2 process for $account_name"
       
       # 等待指定时间
       sleep ${RUN_TIME}m
       
       # 停止当前任务
       pm2 stop "flock-training-node-$account_name"
       pm2 delete "flock-training-node-$account_name"
       log "Stopped PM2 process for $account_name"
   }

   # 主循环
   while true; do
       for account in "${!ACCOUNTS[@]}"; do
           log "Switching to account: $account"
           
           # 运行任务
           run_task "$account"
           
           # 检查是否有错误发生
           if [ $? -ne 0 ]; then
               log "Error occurred with $account"
           fi
           
           log "Completed run with $account"
       done
   done
