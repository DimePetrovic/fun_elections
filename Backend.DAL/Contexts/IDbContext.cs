using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Contexts
{
    public interface IDbContext
    {
        // Generic method for accessing any DbSet
        DbSet<TEntity> Set<TEntity>() where TEntity : class;

        // Methods needed from DbContext
        Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
        DatabaseFacade Database { get; }

        // For getting services like IMigrator
        TService GetService<TService>() where TService : class;
    }
}
