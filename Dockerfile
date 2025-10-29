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

# Use the ASP.NET Core runtime image with MySQL installed
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Install MySQL server
RUN apt-get update && apt-get install -y mysql-server && rm -rf /var/lib/apt/lists/*

# Set environment variables for MySQL
ENV MYSQL_ROOT_PASSWORD=rootpassword
ENV MYSQL_DATABASE=hng_stage2

# Copy published app
WORKDIR /app
COPY --from=publish /app/publish .

# Expose ports
EXPOSE 80
EXPOSE 3306

# Start MySQL and the app
CMD service mysql start && sleep 5 && dotnet hng-stage2-backend.dll