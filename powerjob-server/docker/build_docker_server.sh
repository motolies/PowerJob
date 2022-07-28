#!/bin/bash
# -p: 문자열이 프롬프트로 뒤따를 수 있도록 허용 -r: 이스케이프 없이 원본 내용을 읽도록 합니다.
read -r -p "Docker 이미지 버전을 입력하십시오:" version
echo "빌드할 서버 이미지: powerjob-server:$version"
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
  ls -l powerjob-server/docker/powerjob-server.jar
fi

echo "================== 이전 버전 docker stop =================="
docker stop powerjob-server
echo "================== 이전 버전 docker remove =================="
docker container rm powerjob-server
read -r -p "이미지를 다시 빌드할지 여부（y/n）:" rebuild
if [ "$rebuild" = "y" ] || [  "$rebuild" = "Y" ]; then
  echo "================== 이전 버전의 도커 이미지 삭제 =================="
  docker rmi -f tjqq/powerjob-server:$version
  echo "================== powerjob-server 이미지 빌드 =================="
  docker build -t tjqq/powerjob-server:$version powerjob-server/docker/. || exit

  read -r -p "이미지를 공식적으로 공개할지 여부（y/n）:" needrelease
  if [ "$needrelease" = "y" ] || [  "$needrelease" = "Y" ]; then
    read -r -p "경고! 현재 릴리스된 마스터 분기에 있는지 확인하십시오!（y/n）:" needrelease
    if [ "$needrelease" = "y" ] || [  "$needrelease" = "Y" ]; then
      echo "================== 서버 이미지를 중앙 저장소로 푸시 =================="
      docker push tjqq/powerjob-server:$version
    fi
  fi
fi


