FROM dart:stable AS build

WORKDIR /app

# Install dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source and build
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# Production stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server

EXPOSE 8080

CMD ["/app/bin/server"]
