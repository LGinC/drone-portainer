# drone-portainer
[![Docker Pulls](https://img.shields.io/docker/pulls/lginc/drone-portainer.svg)](https://hub.docker.com/r/lginc/drone-portainer/)
+ plugin of drone continuous deployment to portainer
+ The drone plugin can be used to deploy a Docker image to a Drone environment.The below pipeline configuration demonstrates simple usage:

docker-compose in step

```yaml
steps:
- name: portainer
  image: lginc/drone-portainer:dev
  settings:
    serverurl: http://xxxxx:9000
    username: 
      from_secret: portainer_username
    password:
      from_secret: portainer_password
    endpointId: 1
    stackname: xxxservice
    variables:
      - tag=dev
    imagenames: 
      - xxx/xxx
      - myhub.com/xx1/xxx
    env:
      - TZ:Asia/Shanghai
      - myTag:App
    docker_compose: |
      version: "3"
      services:
        xxx:
          image: xxx/xxx:{{ tag }}
          ports:
          - 80:80
        xx1:
          image: myhub.com/xx1/xxx
```
or

<br>docker-compose in repository

```yaml
steps:
- name: portainer
  image: lginc/drone-portainer:dev
  settings:
    serverurl: http://xxxxx:9000
    apikey: 
      from_secret: portainer_apikey
    endpointId: 2
    stackname: xxxservice
    imagenames: 
      - xxx/xxx
    env:
      - myTag:App
    docker_compose_path: deploy/docker-compose.yaml
    repo_username:
      from_secret: repo_username
    repo_password:
      from_secret: repo_password
```
# Parameter Reference

+ serverurl
: required, portainer server url. like this: http://xxx.com:9000
<br> 必填, portainer服务器url, 如 http://xxx.com:9000

+ username
: optional, portainer username
<br> 可选 登录portainer的用户名

+ password
: optional, portainer password
<br> 可选 登录portainer的密码

+ access_token
: optional, portainer account  [access token](https://docs.portainer.io/v/ce-2.11/api/access), login by username password or access_token. 
click on my account in the top right -> Scroll down to the Access tokens section -> click the Add access token 
<br> 可选 portainer账户的 [访问令牌](https://docs.portainer.io/v/ce-2.11/api/access), 登录方式二选一 用户名-密码 或者 访问令牌. 
创建访问令牌在 portainer 右上角 myAccount, 下拉到Access Token, 点击 Add access token,输入描述 确定


+ endpointId
: optional, portainer endpoint id,default 1, localhost is 1 
<br> portainer终结点id，默认是1,即第一个，一般为localhost

+ stackname
: required, name of stack, show in stack list 
<br> 必填 服务栈的名称，会在stacks列表里显

+ imagenames
: optional, names of pull images, a arrary. add this param because not auto pull image when image:tag not change in docker-compose
<br> 可选 将会进行拉取镜像的镜像名列表, 为数组.加这个参数是因为docker-compose里的镜像名:tag 没有变化则不会自动拉取镜像 <br>
: like this: 
```yaml
- mcr.microsoft.com/dotnet/core/aspnet:6.0-alpine  
- alpine:latest
```


+ env:
: optional, environments of stack.
<br> 可选 环境变量列表 
![env](https://p.sda1.dev/5/b982dedaf195db23d1767701e4200ebd/msedge_xwrxILQuNN.webp)

+ docker_compose
: optional, content of docker-compose.yml.  it will be filled by original stack when stack exist.
<br> 可选, docker-compose.yaml的内容. 如果stack已经存在,不填则会自动获取已经存在的stack内容
sample like this:<br>
```
docker_compose: |
  version: "3"
  services:
    dotnettest:
      image:  mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine
      container_name: dotnet_runtime
```

+ docker_compose_path
: optional, docker-compose.yml in repository relative path. just need choose one between docker_compose and docker_compose_path.
<br> 可选, docker-comose.yml在git仓库中的相对路径, docker_compose和docker_compose_path二选一即可<br>


+ repo_username
: optional, username of git repository
<br> 可选, git仓库用户名<br>


+ repo_password
: optional, password of git repository
<br> 可选, git仓库密码<br>

