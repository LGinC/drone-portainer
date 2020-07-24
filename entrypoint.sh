#!/bin/bash

set -e

# set default endpointid=1
if [ -z "$DRONE_ENDPOINTID" ]; then
 DRONE_ENDPOINTID=1
fi

compose=$(echo "$DRONE_DOCKER_COMPOSE" | sed 's#\"#\\"#g' | sed ":a;N;s/\\n/\\\\n/g;ta") # replace charactor  "->\"   \n -> \\n
#compose="$DRONE_DOCKER_COMPOSE"
echo "compose:            $compose"
#compose="$DRONE_DOCKER_COMPOSE"
#把stack name转为小写
stack=$(echo "$DRONE_STACKNAME" | tr "[:upper:]" "[:lower:]") #ToLowerCase

#请求/api/auth 进行身份验证  获取token
echo "get token  : $DRONE_SERVERURL/api/auth"
Token_Result=$(curl --location --request POST ''$DRONE_SERVERURL'/api/auth' \
--data-raw '{"Username":"'$DRONE_USERNAME'", "Password":"'$DRONE_PASSWORD'"}')
# Token_Result = {"jwt":"xxxxxxxx"}
#todo: get token failed  exit 1
token=$(echo "$Token_Result" | jq -r '.jwt')
if [ "$token" = "null" ]; then
  echo 'Authorization failed'
  echo "$Token_Result"
  exit 1
fi



#pull image  
#拉取镜像
echo "pull image: $DRONE_IMAGENAME"
registry=$(echo "$DRONE_IMAGENAME" | awk -F'/' '{print $1}')
if [[ "$registry" =~ "." ]]
then
    base64Registry=$(echo "{\"serveraddress\":\"$registry\"}" | base64)
    curl --location --request POST ''${DRONE_SERVERURL}'/api/endpoints/'$DRONE_ENDPOINTID'/docker/images/create?fromImage='$DRONE_IMAGENAME'' \
    -H "Authorization: Bearer $token"  -H "X-Registry-Auth: $base64Registry"
else
    curl --location --request POST ''${DRONE_SERVERURL}'/api/endpoints/'$DRONE_ENDPOINTID'/docker/images/create?fromImage='$DRONE_IMAGENAME'' \
    -H "Authorization: Bearer $token"
fi





#get stacks
echo
echo "get statcks :  $DRONE_SERVERURL/api/stacks"
#请求/api/stacks 查询stack列表
stacks=$(curl --location --request GET ''${DRONE_SERVERURL}'/api/stacks' \
--header 'Authorization: Bearer '$token'')
echo "stacks: $stacks"
#获取stack列表长度，如果为空则长度为0
length=$(echo "$stacks" | jq '.|length')
echo "length: $length"
#如果长度大于0
if [ $length -gt 0  ]; then
  #查找同名stack
  stackId=$(echo "$stacks" | jq '.[] | select(.Name=="'$stack'") | .Id') #find the stack name of DRONE_STACKNAME
  echo "stackId: $stackId"
  if [ $stackId -gt 0 ]; then
 #find the stack id, and delete it
    echo
    echo "update stack id=$stackId"
    #找到同名stack，更新stack
    # update_content=$(jq -n -c -M --arg content "$compose" --arg id $stackId '{"id": $id, "StackFileContent": $content}')
    update_content="{\"id\":${stackId},\"StackFileContent\":\"${compose}\",\"Env\":[]}"
    update_result=$(curl --location --request PUT ''${DRONE_SERVERURL}'/api/stacks/'${stackId}?endpointId=${DRONE_ENDPOINTID}'' \
     --header 'Authorization: Bearer '$token'' \
     --header 'Content-Type: application/json' \
     --data-raw "$update_content")
    update_result_msg=$(echo "$update_result" | jq -r '.message')
    if [ "$update_result_msg" != "null" ]; then
      echo "update stack failed"
      echo "body:   $update_content"
      echo "result: $update_result"
      exit 1
    fi
    echo "update success"
    exit 0
  fi
fi


#create stacks
#创建stack

echo
echo 'create stack  : '${DRONE_SERVERURL}'/api/stacks?endpointId='$DRONE_ENDPOINTID'&method=string&type=2'

echo
#echo "{\"Name\":\"'${DRONE_STACKNAME}'\",\"StackFileContent\":\"${compose}\",\"Env\":[]}"
#输出结果
create_content="{\"Name\":\"'${stack}'\",\"StackFileContent\":\"${compose}\",\"Env\":[]}"
result=$(curl --location --request POST ''${DRONE_SERVERURL}'/api/stacks?endpointId='$DRONE_ENDPOINTID'&method=string&type=2' \
--header 'Authorization: Bearer '${token}'' \
--header 'Content-Type: application/json' \
--data-raw "$create_content")
echo "$result"
echo
#如果结果中message不为空则说明有异常
message=$(echo $result | jq -r '.message')
if [ "$message" != "null" ]; then
  echo "create failed: $message"
  exit 1
fi
exit 0