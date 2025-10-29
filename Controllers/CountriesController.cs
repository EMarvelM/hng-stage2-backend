using hng_stage2_backend.Models;
using hng_stage2_backend.Services;
using Microsoft.AspNetCore.Mvc;

namespace hng_stage2_backend.Controllers;

[ApiController]
[Route("countries")]
public class CountriesController : ControllerBase
{
    private readonly ICountryService _countryService;

    public CountriesController(ICountryService countryService)
    {
        _countryService = countryService;
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> RefreshCountries()
    {
        try
        {
            await _countryService.RefreshCountriesAsync();
            return Ok(new { message = "Countries refreshed successfully" });
        }
        catch (Exception ex)
        {
            if (ex.Message.Contains("restcountries") || ex.Message.Contains("exchange"))
            {
                return StatusCode(503, new { error = "External data source unavailable", details = ex.Message });
            }
            return StatusCode(500, new { error = "Internal server error", details = ex.Message });
        }
    }

    [HttpGet]
    public async Task<IActionResult> GetCountries([FromQuery] string? region, [FromQuery] string? currency, [FromQuery] string? sort)
    {
        var countries = await _countryService.GetCountriesAsync(region, currency, sort);
        return Ok(countries);
    }

    [HttpGet("image")]
    public async Task<IActionResult> GetImage()
    {
        try
        {
            var total = await _countryService.GetCountriesAsync(null, null, null);
            var top5 = total
                .Where(c => c.EstimatedGdp.HasValue)
                .OrderByDescending(c => c.EstimatedGdp)
                .Take(5)
                .Select(c => new { name = c.Name, estimated_gdp = c.EstimatedGdp })
                .ToList();
            var lastRefresh = total.Max(c => c.LastRefreshedAt);

            var summary = new
            {
                total_countries = total.Count(),
                last_refreshed_at = lastRefresh.ToString("yyyy-MM-ddTHH:mm:ssZ"),
                top_5_by_gdp = top5
            };

            return Ok(summary);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { error = "Failed to generate summary", details = ex.Message });
        }
    }

    [HttpGet("{name}")]
    public async Task<IActionResult> GetCountry(string name)
    {
        var country = await _countryService.GetCountryByNameAsync(name);
        if (country == null)
            return NotFound(new { error = "Country not found" });
        return Ok(country);
    }
    [HttpDelete("{name}")]
    public async Task<IActionResult> DeleteCountry(string name)
    {
        var country = await _countryService.GetCountryByNameAsync(name);
        if (country == null)
            return NotFound(new { error = "Country not found" });
        await _countryService.DeleteCountryAsync(name);
        return Ok(new { message = "Country deleted successfully" });
    }
}

[ApiController]
[Route("status")]
public class StatusController : ControllerBase
{
    private readonly ICountryService _countryService;

    public StatusController(ICountryService countryService)
    {
        _countryService = countryService;
    }

    [HttpGet]
    public async Task<IActionResult> GetStatus()
    {
        var (total, lastRefresh) = await _countryService.GetStatusAsync();
        return Ok(new { total_countries = total, last_refreshed_at = lastRefresh?.ToString("yyyy-MM-ddTHH:mm:ssZ") });
    }
}