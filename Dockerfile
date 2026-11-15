# Build stage: Maven and Java 17 live inside Docker
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline
COPY src ./src
RUN mvn -q -DskipTests package

# Runtime stage: only Java 17 JRE is needed to run the app
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/notification-platform-1.0.0.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
