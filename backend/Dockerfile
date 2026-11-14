FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app
COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw
COPY src src
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -ntp -DskipTests package

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=build --chown=app:app /app/target/backend-0.0.1-SNAPSHOT.jar app.jar
USER app
ENV TZ=UTC
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=60s --retries=8 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/v3/api-docs || exit 1
ENTRYPOINT ["java", "-Duser.timezone=UTC", "-jar", "app.jar"]
