using FitCodex.Domain.Arcs;

namespace FitCodex.Domain.Tests;

public class ArcTests
{
    private static Arc NewArc(DateOnly start) =>
        new(Guid.NewGuid(), "Winter Arc", ArcType.Hybrid, start, start.AddDays(140));

    [Fact]
    public void Arc_cannot_end_before_it_starts()
    {
        var start = new DateOnly(2026, 8, 10);

        Assert.Throws<ArgumentException>(() =>
            new Arc(Guid.NewGuid(), "Invalido", ArcType.Cut, start, start.AddDays(-1)));
    }

    [Fact]
    public void WeekOf_and_DayOf_follow_the_session_identifier_convention()
    {
        // Arc que arranca lunes 10 Ago: D1 es ese lunes, D7 el domingo.
        var start = new DateOnly(2026, 8, 10);
        var arc = NewArc(start);

        Assert.Equal(1, arc.WeekOf(start));
        Assert.Equal(1, arc.DayOf(start));

        Assert.Equal(1, arc.WeekOf(start.AddDays(6)));
        Assert.Equal(7, arc.DayOf(start.AddDays(6)));

        Assert.Equal(2, arc.WeekOf(start.AddDays(7)));
        Assert.Equal(1, arc.DayOf(start.AddDays(7)));
    }

    [Fact]
    public void ElapsedDays_is_clamped_to_the_arc_window()
    {
        var start = new DateOnly(2026, 8, 10);
        var arc = NewArc(start);

        Assert.Equal(0, arc.ElapsedDays(start.AddDays(-30)));
        Assert.Equal(140, arc.ElapsedDays(start.AddDays(400)));
    }

    [Fact]
    public void A_goal_type_cannot_be_registered_twice()
    {
        var arc = NewArc(new DateOnly(2026, 8, 10));
        arc.AddGoal(new ArcGoal(ArcGoalType.BodyFatPercent, baselineValue: 24.5m, targetValue: 17m));

        Assert.Throws<InvalidOperationException>(() =>
            arc.AddGoal(new ArcGoal(ArcGoalType.BodyFatPercent, targetValue: 15m)));
    }

    [Fact]
    public void Goal_progress_is_null_without_a_baseline()
    {
        // Sin baseline no se puede decir cuanto se avanzo. Devolver 0 seria
        // mentir con un numero que parece medido.
        var goal = new ArcGoal(ArcGoalType.BodyFatPercent, targetValue: 17m);

        Assert.Null(goal.ProgressFrom(21m));
    }

    [Fact]
    public void Goal_progress_works_when_the_target_goes_down()
    {
        // Bajar de 24.5% a 17%: estar en 21% es poco mas de la mitad.
        var goal = new ArcGoal(ArcGoalType.BodyFatPercent, baselineValue: 24.5m, targetValue: 17m);

        var progress = goal.ProgressFrom(21m);

        Assert.NotNull(progress);
        Assert.InRange(progress!.Value, 0.46m, 0.47m);
    }

    [Fact]
    public void Goal_progress_is_clamped_past_the_target()
    {
        var goal = new ArcGoal(ArcGoalType.BodyFatPercent, baselineValue: 24.5m, targetValue: 17m);

        Assert.Equal(1m, goal.ProgressFrom(15m));
        Assert.Equal(0m, goal.ProgressFrom(26m));
    }

    [Fact]
    public void Phase_covers_only_its_own_week_range()
    {
        var phase = new ArcPhase(phaseNumber: 2, name: "Deficit sostenido", weekStart: 5, weekEnd: 10);

        Assert.False(phase.Covers(4));
        Assert.True(phase.Covers(5));
        Assert.True(phase.Covers(10));
        Assert.False(phase.Covers(11));
    }
}
