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

var builder = WebApplication.CreateBuilder(args);

// Config
var jwtSection = builder.Configuration.GetSection("Jwt");
var key = jwtSection["Key"];

// DbContext
builder.Services.AddDbContext<BackendDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

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


builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS: dozvoli Flutter web + android emulator (localhost)
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevCors", policy =>
    {
        policy.AllowAnyHeader().AllowAnyMethod()
              .WithOrigins("http://localhost:5000", "http://localhost:3000", "http://localhost:5500", "http://localhost:4200");
    });
});

var app = builder.Build();

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

app.Run();
