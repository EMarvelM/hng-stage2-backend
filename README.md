# HNG Stage 2 Backend - Country Currency & Exchange API

A RESTful API that fetches country data from external APIs, stores it in a MySQL database, and provides CRUD operations with currency exchange rates and GDP calculations.

## Features

- Fetch country data from restcountries.com
- Fetch exchange rates from open.er-api.com
- Compute estimated GDP using population and exchange rates
- Store data in MySQL database
- CRUD operations for countries
- Filtering and sorting capabilities
- Generate summary image on refresh
- Comprehensive error handling

## Endpoints

- `POST /countries/refresh` - Refresh country data from external APIs
- `GET /countries` - Get all countries (supports `?region=`, `?currency=`, `?sort=gdp_desc`)
- `GET /countries/{name}` - Get country by name
- `DELETE /countries/{name}` - Delete country by name
- `GET /status` - Get total countries and last refresh timestamp
- `GET /countries/image` - Serve summary image

## Setup Instructions

### Prerequisites

- .NET 8.0 SDK
- MySQL Server
- Git

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd hng-stage2-backend
   ```

2. Install dependencies:
   ```bash
   dotnet restore
   ```

3. Set up MySQL database:
   - Create a database named `hng_stage2`
   - Update connection string in `appsettings.json` if needed

4. Run database migrations:
   ```bash
   dotnet ef database update
   ```

5. Run the application:
   ```bash
   dotnet run
   ```

The API will be available at `https://localhost:5001` (or configured port).

### Environment Variables

You can override the database connection using environment variables:
- `ConnectionStrings__DefaultConnection`

### Testing

Use the provided `.http` file or tools like Postman to test endpoints.

First, call `POST /countries/refresh` to populate the database.

## Technologies Used

- ASP.NET Core 8.0
- Entity Framework Core
- MySQL
- SkiaSharp (for image generation)
- HttpClient (for external API calls)

## Deployment

Host on platforms like Railway, Heroku, AWS, etc. (not Vercel or Render).

Ensure MySQL is available and connection string is configured.