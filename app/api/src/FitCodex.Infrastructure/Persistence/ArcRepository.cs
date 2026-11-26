using FitCodex.Application.Arcs;
using FitCodex.Domain.Arcs;
using Microsoft.EntityFrameworkCore;

namespace FitCodex.Infrastructure.Persistence;

public sealed class ArcRepository(FitCodexDbContext db) : IArcRepository
{
    public Task<Arc?> GetActiveAsync(Guid userId, CancellationToken cancellationToken = default) =>
        db.Arcs
            .Include(a => a.Goals)
            .Include(a => a.Phases)
            .FirstOrDefaultAsync(a => a.UserId == userId && a.Status == ArcStatus.Active, cancellationToken);

    public async Task<IReadOnlyList<Arc>> GetHistoryAsync(Guid userId, CancellationToken cancellationToken = default) =>
        await db.Arcs
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.StartDate)
            .ToListAsync(cancellationToken);

    public async Task AddAsync(Arc arc, CancellationToken cancellationToken = default) =>
        await db.Arcs.AddAsync(arc, cancellationToken);

    public Task SaveChangesAsync(CancellationToken cancellationToken = default) =>
        db.SaveChangesAsync(cancellationToken);
}
