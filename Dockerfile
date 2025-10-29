# Use the official .NET 8 SDK image to build the app
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["hng-stage2-backend.csproj", "."]
RUN dotnet restore "hng-stage2-backend.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "hng-stage2-backend.csproj" -c Release -o /app/build

# Publish the app
FROM build AS publish
RUN dotnet publish "hng-stage2-backend.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Use the ASP.NET Core runtime image with MariaDB installed
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Install MariaDB server (MySQL-compatible)
RUN apt-get update && apt-get install -y mariadb-server && rm -rf /var/lib/apt/lists/*

# Set environment variables for MariaDB
ENV MYSQL_ROOT_PASSWORD=rootpassword
ENV MYSQL_DATABASE=hng_stage2

# Set ASP.NET Core to listen on port 80
ENV ASPNETCORE_URLS=http://+:80

# Copy published app
WORKDIR /app
COPY --from=publish /app/publish .

# Copy start script
COPY start.sh .
RUN chmod +x start.sh

# Expose ports
EXPOSE 80
EXPOSE 3306

# Start using the script
CMD ["./start.sh"]