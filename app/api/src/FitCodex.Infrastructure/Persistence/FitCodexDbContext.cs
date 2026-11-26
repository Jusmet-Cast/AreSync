using FitCodex.Domain.Arcs;
using Microsoft.EntityFrameworkCore;

namespace FitCodex.Infrastructure.Persistence;

public sealed class FitCodexDbContext(DbContextOptions<FitCodexDbContext> options) : DbContext(options)
{
    public DbSet<Arc> Arcs => Set<Arc>();

    protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
    {
        // EF Core mapea string a NVARCHAR por defecto. La convencion del
        // proyecto es VARCHAR siempre, asi que se invierte el default una sola
        // vez aca en vez de repetir IsUnicode(false) en cada propiedad y
        // descubrir la primera columna olvidada en produccion.
        configurationBuilder.Properties<string>().AreUnicode(false);

        configurationBuilder.Properties<decimal>().HavePrecision(18, 4);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(FitCodexDbContext).Assembly);
    }
}
