#!/bin/bash

# Start MariaDB
service mariadb start

# Wait for MariaDB to be ready
echo "Waiting for MariaDB to start..."
sleep 15

# Run database setup if needed (optional)
# mysql -u root -prootpassword -e "CREATE DATABASE IF NOT EXISTS hng_stage2;"

# Start the application
echo "Starting ASP.NET Core app..."
dotnet hng-stage2-backend.dll