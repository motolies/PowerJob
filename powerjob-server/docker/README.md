# 도커파일 만들기

---
## - 개요
서버 빌드시에만 사용가능하며, 대체적인 옵션은 powerjob-server-starter 모듈의 application에서 설정 가능 한 것으로 판단됨


## - 빌드
```bash
# PowerJob\powerjob-server 폴더에서 실행
docker build -t docker.hvy.kr/powerjob:latest -f docker/Dockerfile .
```

## - debug

우선은 윈도우에서 작업했다.
```bash
# 도커빌드가 깨질 때 들어가서 확인할 수 있음
docker run --rm -it docker.hvy.kr/powerjob:latest sh

# 이미지 빌드 완료 후에 서버 실행해볼 수 있음
## network의 경우 저 안에 db와 mongodb를 실행해놨음
## 추가적으로 메일 설정이 가능함
docker run --rm -it \
--network="powerjob-docker_power-network" \
-e PARAMS="--spring.profiles.active=product" \
-e JDBC_URL="jdbc:mysql://powerdb:3306/powerjob-product?useUnicode=true&characterEncoding=UTF-8&serverTimezone=UTC" \
-e JDBC_USER="powerjob" \
-e JDBC_PASSWORD="powerjob" \
-e MONGO_URL="mongodb://powermongo:27017/powerjob-product" \
-p 7700:7700 \
-p 10086:10086 docker.hvy.kr/powerjob:latest sh 

# 푸쉬
docker push docker.hvy.kr/powerjob:latest
```

추가 옵션
```dockerfile
# 서버 실행시에 spring profile 설정
ENV PARAMS="--spring.profiles.active=product"
# 기타 jvm 옵션
ENV JVMOPTIONS=""

# db 커넥션 정보
ENV JDBC_URL=""
ENV JDBC_USER=""
ENV JDBC_PASSWORD=""

# mongodb 커넥션 정보
# user/pass 설정 가능하지만 우선은 없는 걸로 했음
# 분산처리시에만 활용가능 한 것 같음
ENV MONGO_URL=""

# 이메일 정보 전달 시에만 활용가능한 것 같음
ENV MAIL_HOST=""
ENV MAIL_USER=""
ENV MAIL_PASSWORD=""
```