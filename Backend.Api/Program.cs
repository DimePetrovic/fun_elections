using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Backend.DAL.Models;
using Microsoft.AspNetCore.Identity;
using Backend.DAL.Contexts;
using Backend.DAL.Repositories;
using Backend.DAL.Repositories.Interfaces;
using Backend.DAL.Repositories.Implemetations;
using Backend.BL.Services.Interfaces;
using Backend.BL.Services.Implemetations;
using Backend.Api.Hubs;

var builder = WebApplication.CreateBuilder(args);

// Config
var jwtSection = builder.Configuration.GetSection("Jwt");
var key = jwtSection["Key"];

// DbContext
builder.Services.AddDbContext<BackendDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))
           .ConfigureWarnings(warnings => warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning)));

// Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = false;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
})
.AddEntityFrameworkStores<BackendDbContext>()
.AddDefaultTokenProviders();

builder.Services.AddScoped<IBackendDbContext>(provider => provider.GetRequiredService<BackendDbContext>());
builder.Services.AddScoped<IApplicationUserRepository, ApplicationUserRepository>();
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

builder.Services.AddScoped<IVoterService, VoterService>();
builder.Services.AddScoped<IElectionService, ElectionService>();
builder.Services.AddScoped<IMatchService, MatchService>();
builder.Services.AddScoped<IGroupService, GroupService>();
builder.Services.AddScoped<ICandidateService, CandidateService>();


builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// SignalR for real-time updates
builder.Services.AddSignalR();

// CORS: dozvoli Flutter web + android emulator (localhost)
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevCors", policy =>
    {
        policy.AllowAnyHeader()
              .AllowAnyMethod()
              .SetIsOriginAllowed(origin => 
              {
                  if (string.IsNullOrWhiteSpace(origin)) return false;
                  // Allow localhost on any port
                  if (origin.StartsWith("http://localhost:") || origin.StartsWith("http://127.0.0.1:"))
                      return true;
                  return false;
              })
              .AllowCredentials();
    });
});

var app = builder.Build();

// Apply migrations automatically on startup
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<BackendDbContext>();
    dbContext.Database.Migrate();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("DevCors");

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ElectionHub>("/electionHub");

app.Run();
