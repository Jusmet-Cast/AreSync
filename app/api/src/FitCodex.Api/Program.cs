using FitCodex.Application.Arcs;
using FitCodex.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddInfrastructure(builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

// Primer endpoint real: resolver el arc vigente. Devuelve 404 cuando no hay
// ninguno activo — un usuario sin arc no es un error, pero tampoco es un
// dashboard vacio: la app tiene que mandarlo a crear el primero.
app.MapGet("/users/{userId:guid}/arcs/active", async (
    Guid userId,
    GetActiveArcHandler handler,
    CancellationToken cancellationToken) =>
{
    var today = DateOnly.FromDateTime(DateTime.UtcNow);
    var result = await handler.HandleAsync(userId, today, cancellationToken);

    return result is null ? Results.NotFound() : Results.Ok(result);
})
.WithName("GetActiveArc");

app.Run();
