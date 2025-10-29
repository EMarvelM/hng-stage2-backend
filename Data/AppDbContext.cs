using Microsoft.EntityFrameworkCore;
using hng_stage2_backend.Models;

namespace hng_stage2_backend.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Country> Countries { get; set; }
}