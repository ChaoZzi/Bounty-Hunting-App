FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
RUN mkdir -p /app/upload /app/logs

COPY bounty-boot/target/bounty-app.jar /app/app.jar

ENV TZ=Asia/Shanghai
ENV JAVA_OPTS="-Xms256m -Xmx768m"

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
