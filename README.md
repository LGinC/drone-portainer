# drone-portainer
[![Docker Pulls](https://img.shields.io/docker/pulls/lginc/drone-portainer.svg)](https://hub.docker.com/r/lginc/drone-portainer/)
+ plugin of drone continuous deployment to portainer
+ The drone plugin can be used to deploy a Docker image to a Drone environment.The below pipeline configuration demonstrates simple usage:

```yaml
steps:
- name: portainer
  image: turinge/drone-portainer
  settings:
    serverurl: http://xxxxx:9000
    username: 
      from_secret: portainer_username
    password:
      from_secret: portainer_password
    endpointId: 1
    stackname: xxxservice
    imagename: xxx/xxx
    docker_compose: |
      version: "2"
      services:
        xxx:
          image: xxx/xxx
          ports:
          - 80:80
```
# Parameter Reference

+ serverurl
: portainer server url. like this: http://xxx.com:9000

+ username
: portainer username

+ password
: portainer password

+ endpointId
: portainer endpoint id,default 1, localhost is 1 <br> portainer终结点id，默认是1,即第一个，一般为localhost

+ stackname
: name of stack, show in stack list <br> 服务栈的名称，会在stacks列表里显

+ imagename
: name of pull image, like: mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine <br> 将会进行拉取镜像的镜像名 如:mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine

+ docker_compose
: content of docker-compose.yml. ps: portainer just support version: "2" <br> docker-compose.yml 的内容 注意:portainer目前仅支持version: "2" <br>
sample like this:<br>
```
docker_compose: |
  version: "2"
  services:
  dotnettest:
    image:  mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine
    container_name: dotnet_runtime
```

