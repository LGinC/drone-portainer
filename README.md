# drone-portainer
[![Docker Pulls](https://img.shields.io/docker/pulls/lginc/drone-portainer.svg)](https://hub.docker.com/r/lginc/drone-portainer/)
+ plugin of drone continuous deployment to portainer
+ The drone plugin can be used to deploy a Docker image to a Drone environment.The below pipeline configuration demonstrates simple usage:

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
          image: xxx/xxx
          ports:
          - 80:80
        xx1:
          image: myhub.com/xx1/xxx
```
# Parameter Reference

+ serverurl
: required, portainer server url. like this: http://xxx.com:9000

+ username
: required, portainer username

+ password
: required, portainer password

+ endpointId
: optional, portainer endpoint id,default 1, localhost is 1 <br> portainer终结点id，默认是1,即第一个，一般为localhost

+ stackname
: required, name of stack, show in stack list <br> 服务栈的名称，会在stacks列表里显

+ imagenames
: required, names of pull images, like: mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine <br> 将会进行拉取镜像的镜像名 如:mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine

+ env:
: optional, environments of stack.
+ docker_compose
: optional, content of docker-compose.yml. 
sample like this:<br>
```
docker_compose: |
  version: "3"
  services:
  dotnettest:
    image:  mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine
    container_name: dotnet_runtime
```

