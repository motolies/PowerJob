#!/bin/bash
# -p: 문자열이 프롬프트로 뒤따를 수 있도록 허용 -r: 이스케이프 없이 원본 내용을 읽도록 합니다.
read -r -p "Docker 이미지 버전을 입력하십시오:" version
echo "빌드할 서버 이미지: powerjob-server:$version"
echo "빌드할 에이전트 이미지: powerjob-agent:$version"
read -r -p "모든 키를 사용하여 계속:"

# 원클릭 배포 스크립트, 스크립트를 이동하지 마십시오
cd `dirname $0`/../.. || exit

read -r -p "maven 빌드 여부(y/n):" needmvn
if [ "$needmvn" = "y" ] || [  "$needmvn" = "Y" ]; then
  echo "================== jar 만들기 =================="
  # mvn clean package -Pdev -DskipTests -U -e -pl powerjob-server,powerjob-worker-agent -am
  # -U: 스냅샷 라이브러리 강제 검사 -pl: 여러 모듈에 대해 쉼표로 구분하여 빌드할 모듈 지정 -am: 종속 모듈을 동시에 빌드, 일반적으로 pl과 함께 사용 -Pxxx: 구성 파일 지정 사용
  mvn clean package -Pdev -DskipTests -U -e
  echo "================== jar 복사 =================="
  /bin/cp -rf powerjob-server/powerjob-server-starter/target/*.jar powerjob-server/docker/powerjob-server.jar
  /bin/cp -rf powerjob-worker-agent/target/*.jar powerjob-worker-agent/powerjob-agent.jar
  ls -l powerjob-server/docker/powerjob-server.jar
  ls -l powerjob-worker-agent/powerjob-agent.jar
fi

echo "================== 이전 버전 docker stop =================="
docker stop powerjob-server
docker stop powerjob-agent
docker stop powerjob-agent2
echo "================== 이전 버전 docker remove =================="
docker container rm powerjob-server
docker container rm powerjob-agent
docker container rm powerjob-agent2
read -r -p "이미지를 다시 빌드할지 여부（y/n）:" rebuild
if [ "$rebuild" = "y" ] || [  "$rebuild" = "Y" ]; then
  echo "================== 이전 버전의 도커 이미지 삭제 =================="
  docker rmi -f tjqq/powerjob-server:$version
  docker rmi -f tjqq/powerjob-agent:$version
  echo "================== powerjob-server 이미지 빌드 =================="
  docker build -t tjqq/powerjob-server:$version powerjob-server/docker/. || exit
  echo "================== powerjob-agent 이미지 빌드 =================="
  docker build -t tjqq/powerjob-agent:$version powerjob-worker-agent/. || exit

  read -r -p "이미지를 공식적으로 공개할지 여부（y/n）:" needrelease
  if [ "$needrelease" = "y" ] || [  "$needrelease" = "Y" ]; then
    read -r -p "경고! 현재 릴리스된 마스터 분기에 있는지 확인하십시오!（y/n）:" needrelease
    if [ "$needrelease" = "y" ] || [  "$needrelease" = "Y" ]; then
      echo "================== 서버 이미지를 중앙 저장소로 푸시 =================="
      docker push tjqq/powerjob-server:$version
      echo "================== 에이전트 이미지를 중앙 저장소로 푸시 =================="
      docker push tjqq/powerjob-agent:$version
    fi
  fi
fi


read -r -p "시작여부 server & agent（y/n）:" startup
if [ "$startup" = "y" ] || [  "$startup" = "Y" ]; then
  # 애플리케이션 시작(포트 매핑, 데이터 경로 마운트)
  ## -d: 백그라운드에서 실행
  ## -p: 포트 매핑 지정, 호스트 포트: 컨테이너 포트
  ## --name: 컨테이너 이름 지정
  ## -v (--volume): 마운트 디렉토리, 호스트 디렉토리: 도커의 디렉토리, 도커의 경로에 기록된 데이터는 호스트에 직접 기록되며, 종종 로그 파일에 사용됩니다.
  ## --net=host: 컨테이너와 호스트가 네트워크를 공유함(컨테이너는 호스트 IP를 직접 사용하므로 성능은 최상이지만 네트워크 분리가 나쁨)
  echo "================== powerjob-server를 시작할 준비가 되었습니다. =================="
  docker run -d \
         --name powerjob-server \
         -p 7700:7700 -p 10086:10086 -p 5001:5005 -p 10001:10000 \
         -e JVMOPTIONS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=10000 -Dcom.sun.management.jmxremote.rmi.port=10000 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" \
         -e PARAMS="--spring.profiles.active=pre" \
         -e TZ="Asia/Shanghai" \
         -v ~/docker/powerjob-server:/root/powerjob-server -v ~/.m2:/root/.m2 \
         tjqq/powerjob-server:$version
  sleep 1
#  tail -f -n 1000 ~/docker/powerjob-server/logs/powerjob-server-application.log

  sleep 30
  echo "================== powerjob-client를 시작할 준비가 되었습니다. =================="
  serverIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' powerjob-server)
  serverAddress="$serverIP:7700"
  echo "사용된 서버 주소：$serverAddress"
  docker run -d \
         --name powerjob-agent \
         -p 27777:27777 -p 5002:5005 -p 10002:10000 \
         -e JVMOPTIONS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=10000 -Dcom.sun.management.jmxremote.rmi.port=10000 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false" \
         -e PARAMS="--app powerjob-agent-test --server $serverAddress" \
         -v ~/docker/powerjob-agent:/root \
         tjqq/powerjob-agent:$version

  docker run -d \
         --name powerjob-agent2 \
         -p 27778:27777 -p 5003:5005 -p 10003:10000 \
         -e JVMOPTIONS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005" \
         -e PARAMS="--app powerjob-agent-test --server $serverAddress" \
         -v ~/docker/powerjob-agent2:/root \
         tjqq/powerjob-agent:$version

  tail -f -n 100 ~/docker/powerjob-agent/powerjob/logs/powerjob-agent-application.log
fi