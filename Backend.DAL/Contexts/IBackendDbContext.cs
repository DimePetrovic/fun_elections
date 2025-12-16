using Backend.DAL.Models;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Contexts
{
    public interface IBackendDbContext : IDbContext, IDisposable, IAsyncDisposable
    {
        // Identity-related DbSets
        DbSet<ApplicationUser> Users { get; }
        DbSet<IdentityRole> Roles { get; }
        DbSet<IdentityUserClaim<string>> UserClaims { get; }
        DbSet<IdentityUserRole<string>> UserRoles { get; }
        DbSet<IdentityUserLogin<string>> UserLogins { get; }
        DbSet<IdentityRoleClaim<string>> RoleClaims { get; }
        DbSet<IdentityUserToken<string>> UserTokens { get; }
        DbSet<Voter> Voters { get; }
        DbSet<Election> Elections { get; }
        DbSet<Candidate> Candidates { get; }
        DbSet<Group> Groups { get; }
        DbSet<Match> Matches { get; }


    }
}
