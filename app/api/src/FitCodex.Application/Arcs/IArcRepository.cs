using FitCodex.Domain.Arcs;

namespace FitCodex.Application.Arcs;

/// <summary>
/// Contrato de persistencia del arc. Application no sabe si del otro lado hay
/// SQL Server, un mock o una cache: esa decision es de Infrastructure.
/// </summary>
public interface IArcRepository
{
    Task<Arc?> GetActiveAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<Arc>> GetHistoryAsync(Guid userId, CancellationToken cancellationToken = default);

    Task AddAsync(Arc arc, CancellationToken cancellationToken = default);

    Task SaveChangesAsync(CancellationToken cancellationToken = default);
}
