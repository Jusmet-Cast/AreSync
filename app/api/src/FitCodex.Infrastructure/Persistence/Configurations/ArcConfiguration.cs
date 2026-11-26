using FitCodex.Domain.Arcs;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace FitCodex.Infrastructure.Persistence.Configurations;

/// <summary>
/// Mapea el agregado Arc contra las tablas de <c>database/schema/01_arcs.sql</c>.
/// El DDL es la fuente de verdad del schema; esta clase solo tiene que
/// coincidir con el, nunca generar un diseño propio.
/// </summary>
public sealed class ArcConfiguration : IEntityTypeConfiguration<Arc>
{
    public void Configure(EntityTypeBuilder<Arc> builder)
    {
        builder.ToTable("Arc", "arcs");
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Name).HasMaxLength(120).IsRequired();

        // Los enums se guardan como el mismo texto que valida el CHECK del
        // DDL ('recomp', 'active', ...), no como int: una fila tiene que ser
        // legible desde SSMS sin tener el codigo C# al lado.
        builder.Property(a => a.Type)
            .HasMaxLength(20)
            .HasConversion(
                v => v.ToString().ToLowerInvariant(),
                v => Enum.Parse<ArcType>(v, ignoreCase: true));

        builder.Property(a => a.Status)
            .HasMaxLength(20)
            .HasConversion(
                v => v.ToString().ToLowerInvariant(),
                v => Enum.Parse<ArcStatus>(v, ignoreCase: true));

        builder.Property(a => a.ShortDescription).HasColumnType("varchar(max)");
        builder.Property(a => a.InitialWeightKg).HasPrecision(6, 2);
        builder.Property(a => a.FinalWeightKg).HasPrecision(6, 2);

        builder.HasMany(a => a.Goals)
            .WithOne()
            .HasForeignKey(g => g.ArcId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(a => a.Phases)
            .WithOne()
            .HasForeignKey(p => p.ArcId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Navigation(a => a.Goals).UsePropertyAccessMode(PropertyAccessMode.Field);
        builder.Navigation(a => a.Phases).UsePropertyAccessMode(PropertyAccessMode.Field);
    }
}

public sealed class ArcGoalConfiguration : IEntityTypeConfiguration<ArcGoal>
{
    public void Configure(EntityTypeBuilder<ArcGoal> builder)
    {
        builder.ToTable("ArcGoal", "arcs");
        builder.HasKey(g => g.Id);

        builder.Property(g => g.Type)
            .HasMaxLength(30)
            .HasConversion(
                v => ToSnakeCase(v.ToString()),
                v => ParseGoalType(v));

        builder.Property(g => g.BaselineValue).HasPrecision(10, 2);
        builder.Property(g => g.TargetValue).HasPrecision(10, 2);
        builder.Property(g => g.StretchValue).HasPrecision(10, 2);
        builder.Property(g => g.TargetText).HasMaxLength(60);

        builder.HasIndex(g => new { g.ArcId, g.Type }).IsUnique();
    }

    private static string ToSnakeCase(string value) =>
        string.Concat(value.Select((c, i) =>
            char.IsUpper(c) && i > 0 ? "_" + char.ToLowerInvariant(c) : char.ToLowerInvariant(c).ToString()));

    private static ArcGoalType ParseGoalType(string value) =>
        Enum.GetValues<ArcGoalType>().First(t => ToSnakeCase(t.ToString()) == value);
}

public sealed class ArcPhaseConfiguration : IEntityTypeConfiguration<ArcPhase>
{
    public void Configure(EntityTypeBuilder<ArcPhase> builder)
    {
        builder.ToTable("ArcPhase", "arcs");
        builder.HasKey(p => p.Id);

        builder.Property(p => p.Name).HasMaxLength(120).IsRequired();
        builder.Property(p => p.SleepGoalText).HasMaxLength(60);

        builder.Property(p => p.Status)
            .HasMaxLength(20)
            .HasConversion(
                v => v.ToString().ToLowerInvariant(),
                v => Enum.Parse<ArcPhaseStatus>(v, ignoreCase: true));

        builder.HasIndex(p => new { p.ArcId, p.PhaseNumber }).IsUnique();
    }
}
