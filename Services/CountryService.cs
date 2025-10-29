using System.Net.Http.Json;
using System.Text.Json;
using hng_stage2_backend.Data;
using hng_stage2_backend.Models;
using Microsoft.EntityFrameworkCore;
using SkiaSharp;

namespace hng_stage2_backend.Services;

public class CountryService : ICountryService
{
    private readonly AppDbContext _context;
    private readonly HttpClient _httpClient;
    private readonly Random _random = new();

    public CountryService(AppDbContext context, HttpClient httpClient)
    {
        _context = context;
        _httpClient = httpClient;
    }

    public async Task RefreshCountriesAsync()
    {
        // Fetch countries
        var countriesResponse = await _httpClient.GetFromJsonAsync<List<CountryApiResponse>>("https://restcountries.com/v2/all?fields=name,capital,region,population,flag,currencies");
        if (countriesResponse == null)
            throw new Exception("Could not fetch data from restcountries API");

        // Fetch exchange rates
        var ratesResponse = await _httpClient.GetFromJsonAsync<ExchangeRatesResponse>("https://open.er-api.com/v6/latest/USD");
        if (ratesResponse == null || ratesResponse.Rates == null)
            throw new Exception("Could not fetch data from exchange rates API");

        var rates = ratesResponse.Rates;

        var now = DateTime.UtcNow;
        var countriesToSave = new List<Country>();

        foreach (var apiCountry in countriesResponse)
        {
            var country = new Country
            {
                Name = apiCountry.Name,
                Capital = apiCountry.Capital,
                Region = apiCountry.Region,
                Population = apiCountry.Population,
                FlagUrl = apiCountry.Flag,
                LastRefreshedAt = now
            };

            string? currencyCode = null;
            decimal? exchangeRate = null;
            decimal? estimatedGdp = null;

            if (apiCountry.Currencies != null && apiCountry.Currencies.Length > 0 && !string.IsNullOrEmpty(apiCountry.Currencies[0].Code))
            {
                currencyCode = apiCountry.Currencies[0].Code;
                if (rates.TryGetValue(currencyCode, out var rate))
                {
                    exchangeRate = (decimal)rate;
                    var multiplier = _random.Next(1000, 2001);
                    estimatedGdp = (decimal)apiCountry.Population * multiplier / exchangeRate;
                }
                else
                {
                    // currency not found, set null
                }
            }
            else
            {
                // no currencies or code null, set gdp to 0
                estimatedGdp = 0;
            }

            country.CurrencyCode = currencyCode;
            country.ExchangeRate = exchangeRate;
            country.EstimatedGdp = estimatedGdp;

            countriesToSave.Add(country);
        }

        // Now, for each, check if exists, update or insert
        foreach (var country in countriesToSave)
        {
            var existing = await _context.Countries.FirstOrDefaultAsync(c => c.Name.ToLower() == country.Name.ToLower());
            if (existing != null)
            {
                existing.Capital = country.Capital;
                existing.Region = country.Region;
                existing.Population = country.Population;
                existing.CurrencyCode = country.CurrencyCode;
                existing.ExchangeRate = country.ExchangeRate;
                existing.EstimatedGdp = country.EstimatedGdp;
                existing.FlagUrl = country.FlagUrl;
                existing.LastRefreshedAt = country.LastRefreshedAt;
            }
            else
            {
                _context.Countries.Add(country);
            }
        }

        await _context.SaveChangesAsync();

        // Generate image (don't fail refresh if image generation fails)
        try
        {
            var total = await _context.Countries.CountAsync();
            var top5 = await _context.Countries
                .Where(c => c.EstimatedGdp.HasValue)
                .OrderByDescending(c => c.EstimatedGdp)
                .Take(5)
                .ToListAsync();
            GenerateSummaryImage(total, top5, now);
        }
        catch (Exception ex)
        {
            // Log or ignore image generation failure
            Console.WriteLine($"Image generation failed: {ex.Message}");
        }
    }

    private void GenerateSummaryImage(int totalCountries, List<Country> top5, DateTime timestamp)
    {
        var imageInfo = new SKImageInfo(800, 600);
        using var surface = SKSurface.Create(imageInfo);
        var canvas = surface.Canvas;
        canvas.Clear(SKColors.White);

        var paint = new SKPaint
        {
            Color = SKColors.Black,
            TextSize = 20,
            IsAntialias = true
        };

        canvas.DrawText($"Total Countries: {totalCountries}", 10, 30, paint);
        canvas.DrawText($"Last Refresh: {timestamp:yyyy-MM-dd HH:mm:ss}", 10, 60, paint);
        canvas.DrawText("Top 5 by GDP:", 10, 90, paint);

        int y = 120;
        foreach (var c in top5)
        {
            canvas.DrawText($"{c.Name}: {c.EstimatedGdp:F2}", 10, y, paint);
            y += 30;
        }

        using var image = surface.Snapshot();
        using var data = image.Encode(SKEncodedImageFormat.Png, 100);
        Directory.CreateDirectory("cache");
        File.WriteAllBytes("cache/summary.png", data.ToArray());
    }

    public async Task<IEnumerable<Country>> GetCountriesAsync(string? region, string? currency, string? sort)
    {
        var query = _context.Countries.AsQueryable();

        if (!string.IsNullOrEmpty(region))
            query = query.Where(c => c.Region == region);

        if (!string.IsNullOrEmpty(currency))
            query = query.Where(c => c.CurrencyCode == currency);

        if (sort == "gdp_desc")
            query = query.OrderByDescending(c => c.EstimatedGdp);

        return await query.ToListAsync();
    }

    public async Task<Country?> GetCountryByNameAsync(string name)
    {
        return await _context.Countries.FirstOrDefaultAsync(c => c.Name.ToLower() == name.ToLower());
    }

    public async Task DeleteCountryAsync(string name)
    {
        var country = await GetCountryByNameAsync(name);
        if (country != null)
        {
            _context.Countries.Remove(country);
            await _context.SaveChangesAsync();
        }
    }

    public async Task<(int total, DateTime? lastRefresh)> GetStatusAsync()
    {
        var total = await _context.Countries.CountAsync();
        var lastRefresh = await _context.Countries.MaxAsync(c => (DateTime?)c.LastRefreshedAt);
        return (total, lastRefresh);
    }

    public async Task GenerateImageAsync()
    {
        try
        {
            var total = await _context.Countries.CountAsync();
            var top5 = await _context.Countries
                .Where(c => c.EstimatedGdp.HasValue)
                .OrderByDescending(c => c.EstimatedGdp)
                .Take(5)
                .ToListAsync();
            var lastRefresh = await _context.Countries.MaxAsync(c => (DateTime?)c.LastRefreshedAt) ?? DateTime.UtcNow;
            GenerateSummaryImage(total, top5, lastRefresh);
        }
        catch (Exception ex)
        {
            // Log or rethrow
            Console.WriteLine($"Image generation failed: {ex.Message}");
            throw;
        }
    }
}

// API response models
public class CountryApiResponse
{
    public string Name { get; set; } = null!;
    public string? Capital { get; set; }
    public string? Region { get; set; }
    public long Population { get; set; }
    public string? Flag { get; set; }
    public Currency[]? Currencies { get; set; }
}

public class Currency
{
    public string? Code { get; set; }
}

public class ExchangeRatesResponse
{
    public Dictionary<string, double> Rates { get; set; } = null!;
}