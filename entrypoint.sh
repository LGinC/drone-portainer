#!/bin/bash

set -e

# set default endpointid=1
if [ -z "$PLUGIN_ENDPOINTID" ]; then
 PLUGIN_ENDPOINTID=1
fi

compose=$(echo "$PLUGIN_DOCKER_COMPOSE" | sed 's#\"#\\"#g' | sed ":a;N;s/\\n/\\\\n/g;ta") # replace charactor  "->\"   \n -> \\n

#把stack name转为小写
stack=$(echo "$PLUGIN_STACKNAME" | tr "[:upper:]" "[:lower:]") #ToLowerCase

#请求/api/auth 进行身份验证  获取token
echo "get token  : $PLUGIN_SERVERURL/api/auth"
Token_Result=$(curl --location --request POST ''$PLUGIN_SERVERURL'/api/auth' \
--data-raw '{"Username":"'$PLUGIN_USERNAME'", "Password":"'$PLUGIN_PASSWORD'"}')
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
echo "pull image: $PLUGIN_IMAGENAME"
registry=$(echo "$PLUGIN_IMAGENAME" | awk -F'/' '{print $1}')
if [[ "$registry" =~ "." ]]
then
    base64Registry=$(echo "{\"serveraddress\":\"$registry\"}" | base64)
    curl --location --request POST ''${PLUGIN_SERVERURL}'/api/endpoints/'$PLUGIN_ENDPOINTID'/docker/images/create?fromImage='$PLUGIN_IMAGENAME'' \
    -H "Authorization: Bearer $token"  -H "X-Registry-Auth: $base64Registry"
else
    curl --location --request POST ''${PLUGIN_SERVERURL}'/api/endpoints/'$PLUGIN_ENDPOINTID'/docker/images/create?fromImage='$PLUGIN_IMAGENAME'' \
    -H "Authorization: Bearer $token"
fi





#get stacks
echo
echo "get statcks :  $PLUGIN_SERVERURL/api/stacks"
#请求/api/stacks 查询stack列表
stacks=$(curl --location --request GET ''${PLUGIN_SERVERURL}'/api/stacks' \
--header 'Authorization: Bearer '$token'')
echo "stacks: $stacks"
#获取stack列表长度，如果为空则长度为0
length=$(echo "$stacks" | jq '.|length')
echo "length: $length"
#如果长度大于0
if [ $length -gt 0  ]; then
  #查找同名stack
  stackId=$(echo "$stacks" | jq '.[] | select(.Name=="'$stack'") | .Id') #find the stack name of PLUGIN_STACKNAME
  echo "stackId: $stackId"
  if [ -z "$compose" ]; then
    #find the current compose file content
    #/api/stacks/${stackId}/file
    echo "get stack file :  $PLUGIN_SERVERURL/api/stacks/$stackId/file"
    file_result=$(curl --location --request GET ''${PLUGIN_SERVERURL}'/api/stacks/'${stackId}/file'' \
     --header 'Authorization: Bearer '$token'')
    file_msg=$(echo "$file_result" | jq -r '.message')
    if [ "$file_msg" != "null" ]; then
      echo "get stack file failed"
      echo "result: $file_result"
      exit 1
    fi
    echo "file: $file_result"
    compose=$(echo "$file_result" | jq '.StackFileContent')
    update_content="{\"id\":${stackId},\"StackFileContent\":${compose},\"Env\":[]}"
  else
    update_content="{\"id\":${stackId},\"StackFileContent\":\"${compose}\",\"Env\":[]}"
  fi

  

  if [ $stackId -gt 0 ]; then
 #find the stack id, and delete it
    echo
    echo "update stack id=$stackId"
    #找到同名stack，更新stack
    update_result=$(curl --location --request PUT ''${PLUGIN_SERVERURL}'/api/stacks/'${stackId}?endpointId=${PLUGIN_ENDPOINTID}'' \
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
echo 'create stack  : '${PLUGIN_SERVERURL}'/api/stacks?endpointId='$PLUGIN_ENDPOINTID'&method=string&type=2'
if [ -z "$compose" ]; then
  echo "docker_compose can't be empty for create stack"
  exit 1
fi
echo
#echo "{\"Name\":\"'${PLUGIN_STACKNAME}'\",\"StackFileContent\":\"${compose}\",\"Env\":[]}"
#输出结果
create_content="{\"Name\":\"'${stack}'\",\"StackFileContent\":\"${compose}\",\"Env\":[]}"
result=$(curl --location --request POST ''${PLUGIN_SERVERURL}'/api/stacks?endpointId='$PLUGIN_ENDPOINTID'&method=string&type=2' \
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