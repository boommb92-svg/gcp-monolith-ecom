FROM maven:3.8.8 AS build
WORKDIR /workspace
COPY app/pom.xml app/pom.xml
COPY app/src app/src
RUN mvn -f app/pom.xml -B -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /workspace/app/target/*.jar /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
