# -------- BUILD (JDK + sbt) --------
FROM sbtscala/scala-sbt:eclipse-temurin-17.0.15_6_1.11.7_2.12.20 AS build
WORKDIR /app

# better caching of dependencies
COPY project ./project
COPY build.sbt ./
RUN sbt -batch update

# now copy the rest and build a fat jar
COPY . .
RUN sbt -batch clean assembly

# -------- RUN (JRE only) --------
FROM eclipse-temurin:17-jre-jammy AS run
WORKDIR /app

# copy the uber-jar produced by sbt-assembly
COPY --from=build /app/target/scala-2.12/*assembly*.jar /app/app.jar

RUN cat <<'EOF' >/usr/local/bin/start-app.sh
#!/usr/bin/env bash
set -euo pipefail

APP_JAR="/app/app.jar"

# Use fully-qualified main class names
#CLI_MAIN="${CLI_MAIN:-siren.feedDB}"
ANALYTIC_MAIN="${ANALYTIC_MAIN:-siren.analyticcli}"

#java -cp "${APP_JAR}" "${CLI_MAIN}"
java -cp "${APP_JAR}" "${ANALYTIC_MAIN}"
EOF

RUN chmod +x /usr/local/bin/start-app.sh

EXPOSE 15002
CMD ["/usr/local/bin/start-app.sh"]
