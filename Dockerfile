# Stage 1: Build the application
FROM gradle:8.8.0-jdk21-alpine AS build
WORKDIR /workspace
COPY build.gradle settings.gradle gradle.properties ./
COPY src ./src
RUN gradle clean build -Dquarkus.package.type=fast-jar

# Stage 2: Create the runtime image
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY --from=build /workspace/build/quarkus-app/lib ./lib
COPY --from=build /workspace/build/quarkus-app/quarkus-run.jar ./

CMD ["java", "-jar", "quarkus-run.jar"]
