using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using Backend.DAL.Models;
using Microsoft.EntityFrameworkCore.Infrastructure;

namespace Backend.DAL.Contexts;
public class BackendDbContext : IdentityDbContext<ApplicationUser>, IBackendDbContext
{
    public virtual DbSet<Voter> Voters { get; set; }
    public virtual DbSet<Election> Elections { get; set; }
    public virtual DbSet<Candidate> Candidates { get; set; }
    public virtual DbSet<Group> Groups { get; set; }
    public virtual DbSet<Match> Matches { get; set; }
    public virtual DbSet<Vote> Votes { get; set; }
    

    public BackendDbContext(DbContextOptions<BackendDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        ModelBuilderExtensions.ConfigureVotesCascade(modelBuilder);
        
        // Configure Match.Candidates relationship explicitly to prevent WinnerId1 shadow property
        modelBuilder.Entity<Candidate>()
            .HasOne<Match>()
            .WithMany(m => m.Candidates)
            .HasForeignKey(c => c.MatchId)
            .OnDelete(DeleteBehavior.NoAction);
        
        // Configure Match.Winner relationship
        modelBuilder.Entity<Match>()
            .HasOne(m => m.Winner)
            .WithMany()
            .HasForeignKey(m => m.WinnerId)
            .OnDelete(DeleteBehavior.NoAction);
    }

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
