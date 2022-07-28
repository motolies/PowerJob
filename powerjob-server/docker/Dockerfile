# 기본 이미지(amd64 및 arm64 지원)
FROM openjdk:8-jdk-alpine AS builder

# maven 설치
RUN apk add --no-cache curl tar bash procps

## Downloading and installing Maven
## 1- Define a constant with the version of maven you want to install
ARG MAVEN_VERSION=3.8.6

## 2- Define a constant with the working directory
ARG USER_HOME_DIR="/root"

## 3- Define the SHA key to validate the maven download
ARG SHA=f790857f3b1f90ae8d16281f902c689e4f136ebe584aba45e4b1fa66c80cba826d3e0e52fdd04ed44b4c66f6d3fe3584a057c26dfcac544a60b301e6d0f91c26

## 4- Define the URL where maven can be downloaded from
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

## 5- Create the directories, download maven, validate the download, install it, remove downloaded file and set links
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && echo "Downlaoding maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  \
  && echo "Checking download hash" \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  \
  && echo "Unziping maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

## 6- Define environmental variables required by Maven, like Maven_Home directory and where the maven repo is located
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

## maven 설정 파일 교체
RUN rm -rf /usr/share/maven/conf/settings.xml
COPY ./docker/settings.xml /usr/share/maven/conf/settings.xml



#빌드
## 작업폴더 지정
WORKDIR /usr/src/app

## powerjob-server 폴더 통째로 복사
COPY ./ .

## 빌드 시작
RUN mvn clean package -Pdev -DskipTests -U -e

RUN echo Build End


### STAGE 2: Production Environment ###
FROM openjdk:8-jdk-alpine

# 애플리케이션 jar 패키지를 도커에 복사
ARG JAR_FILE=target/*.jar
COPY --from=builder --chown=boot:spring /usr/src/app/powerjob-server-starter/${JAR_FILE} ./powerjob-server.jar

# 시간대 설정
ENV TZ=UTC

# 다른 환경 변수 설정
ENV APP_NAME=powerjob-server
# SpringBoot 시작 매개변수 및 JVM 매개변수 전달(쌍따옴표로 감쌌었는데, 안되서 작은 따옴표로 하니 된다.)
ENV PARAMS='--spring.profiles.active=product'
ENV JVMOPTIONS=''

ENV JDBC_URL=''
ENV JDBC_USER=''
ENV JDBC_PASSWORD=''

ENV MONGO_URL=''

ENV MAIL_HOST=''
ENV MAIL_USER=''
ENV MAIL_PASSWORD=''

# 포트 노출(HTTP + AKKA + VertX)
EXPOSE 7700 10086 10010
# 도커 파일 디렉토리 생성
RUN mkdir -p /root/powerjob-server
# 데이터 볼륨을 마운트하고 파일을 호스트에 직접 출력합니다(익명 볼륨은 여기에 마운트됩니다. 즉, 호스트의 위치는 임의적임)
VOLUME /root/powerjob
# 애플리케이션 시작
ENTRYPOINT ["sh","-c","java $JVMOPTIONS -jar /powerjob-server.jar $PARAMS"]
