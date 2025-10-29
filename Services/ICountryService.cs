using hng_stage2_backend.Models;

namespace hng_stage2_backend.Services;

public interface ICountryService
{
    Task RefreshCountriesAsync();
    Task<IEnumerable<Country>> GetCountriesAsync(string? region, string? currency, string? sort);
    Task<Country?> GetCountryByNameAsync(string name);
    Task DeleteCountryAsync(string name);
    Task<(int total, DateTime? lastRefresh)> GetStatusAsync();
}