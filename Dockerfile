# ---- build ----
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -q -B dependency:go-offline
COPY src ./src
RUN mvn -q -B -DskipTests package

# ---- run ----
FROM eclipse-temurin:17-jre
WORKDIR /app
RUN useradd --system --create-home srirammart && mkdir -p /app/data /app/uploads && chown -R srirammart /app
COPY --from=build /src/target/srirammart-1.0.0.jar /app/app.jar
USER srirammart
ENV UPLOAD_DIR=/app/uploads
EXPOSE 8080
VOLUME ["/app/data", "/app/uploads"]
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
