using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Backend.DAL.Models;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace Backend.DAL.Contexts;
public class BackendDbContext : IdentityDbContext<ApplicationUser>, IBackendDbContext
{
    public BackendDbContext(DbContextOptions<BackendDbContext> options) : base(options) { }

    // public DbSet<Product> Products { get; set; }

    // IMPORTANT: NEVER allow records nor transactions to be deleted
    public override int SaveChanges()
    {
        return base.SaveChanges();
    }

    // IMPORTANT: NEVER allow records nor transactions to be deleted
    public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await base.SaveChangesAsync(cancellationToken);
    }

    public TService GetService<TService>() where TService : class
    {
        return ((IInfrastructure<IServiceProvider>)this).GetService<TService>();
    }
}
