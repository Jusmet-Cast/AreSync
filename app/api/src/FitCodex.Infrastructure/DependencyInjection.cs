using FitCodex.Application.Arcs;
using FitCodex.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace FitCodex.Infrastructure;

/// <summary>
/// Unico punto donde la Api se entera de que la persistencia es SQL Server.
/// Cambiar de motor o meter un doble de prueba es tocar este archivo.
/// </summary>
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("FitCodex")
            ?? throw new InvalidOperationException(
                "Falta la cadena de conexion 'FitCodex'. Se configura por user-secrets o variable de entorno, nunca en appsettings.json versionado.");

        services.AddDbContext<FitCodexDbContext>(options => options.UseSqlServer(connectionString));
        services.AddScoped<IArcRepository, ArcRepository>();
        services.AddScoped<GetActiveArcHandler>();

        return services;
    }
}
