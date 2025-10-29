# Implementation Guide for HNG Stage 2 Backend

## Step-by-Step Thinking Process

1. **Understand the Requirements**:
   - Build a RESTful API for country data with currency exchange rates.
   - Fetch from external APIs: restcountries and exchange rates.
   - Store in MySQL database with computed GDP.
   - Implement CRUD operations with specific endpoints.
   - Handle validations, errors, and image generation.

2. **Analyze Project Structure**:
   - Existing ASP.NET Core minimal API project.
   - Need to convert to MVC with controllers.
   - Add Entity Framework Core for database.
   - Add services for business logic.

3. **Design Database Model**:
   - Country entity with all required fields.
   - Use EF Core with MySQL.
   - Handle updates by name (case-insensitive).

4. **Plan Services**:
   - ICountryService interface for abstraction.
   - CountryService implementation with HTTP calls, data processing, image generation.
   - Use HttpClient for external APIs.
   - Use SkiaSharp for PNG image creation.

5. **Implement Controllers**:
   - CountriesController for main endpoints.
   - StatusController for status endpoint.
   - Handle HTTP methods, routing, error responses.

6. **Configure Application**:
   - Update Program.cs for MVC, DbContext, services.
   - Add connection string to appsettings.json.
   - Update .csproj with necessary packages.

7. **Handle Edge Cases**:
   - Multiple currencies: take first.
   - No currencies: set fields to null/0.
   - Currency not in rates: set exchange/gdp to null.
   - External API failures: 503 error.
   - Image not found: 404 with JSON.

8. **Testing and Validation**:
   - Ensure endpoints return correct JSON.
   - Handle filters, sorting.
   - Generate image on refresh.

9. **Deployment Considerations**:
   - Use environment variables for DB config.
   - Ensure MySQL is set up.
   - Host on allowed platforms (not Vercel/Render).

This implementation follows the specifications closely, using C# and ASP.NET Core for a robust API.