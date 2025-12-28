using Backend.DAL.Contexts;
using Backend.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Repositories.Implemetations
{
    public class Repository <T, TContext> : IRepository<T>
       where T : class
       where TContext : IDbContext
    {
        protected readonly TContext _dbContext;
        protected readonly ILogger _logger;

        public Repository(TContext DbContext, ILogger logger)
        {
            _dbContext = DbContext ?? throw new ArgumentNullException(nameof(DbContext));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        public async Task AddAsync(T entity)
        {
            _logger.LogDebug("Adding {EntityType} to database", typeof(T).Name);
            await _dbContext.Set<T>().AddAsync(entity);
        }

        public async Task AddRangeAsync(IEnumerable<T> entities)
        {
            _logger.LogDebug("Adding {Count} {EntityType} to database", entities.Count(), typeof(T).Name);
            await _dbContext.Set<T>().AddRangeAsync(entities);
        }

        public async Task<bool> AnyAsync(Expression<Func<T, bool>> predicate)
        {
            _logger.LogDebug("Finding any {EntityType} with predicate from the database", typeof(T).Name);
            return await _dbContext.Set<T>().AnyAsync(predicate);
        }

        public async Task UpdateAsync(T entity)
        {
            _logger.LogDebug("Updating {EntityType} in database", typeof(T).Name);
            _dbContext.Set<T>().Update(entity);
            await Task.CompletedTask;
        }

        public Task DeleteAsync(T entity)
        {
            _logger.LogDebug("Removing {EntityType} from database", typeof(T).Name);
            _dbContext.Set<T>().Remove(entity);
            return Task.CompletedTask;
        }

        public Task DeleteRangeAsync(IEnumerable<T> entities)
        {
            _logger.LogDebug("Removing {Count} {EntityType} from database", entities.Count(), typeof(T).Name);
            _dbContext.Set<T>().RemoveRange(entities);
            return Task.CompletedTask;
        }

        public async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate)
        {
            _logger.LogDebug("Finding {EntityType} with predicate", typeof(T).Name);
            return await _dbContext.Set<T>().Where(predicate).ToListAsync();
        }

        public async Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate)
        {
            _logger.LogDebug("Finding first {EntityType} with predicate", typeof(T).Name);
            return await _dbContext.Set<T>().FirstOrDefaultAsync(predicate);
        }

        public async Task<IEnumerable<T>> GetAllAsync()
        {
            _logger.LogDebug("Getting all {EntityType}", typeof(T).Name);
            return await _dbContext.Set<T>().ToListAsync();
        }

        public async Task<T?> GetByIdAsync(string id)
        {
            _logger.LogDebug("Getting {EntityType} with ID {Id}", typeof(T).Name, id);
            return await _dbContext.Set<T>().FindAsync(id);
        }

        public virtual async Task<T?> GetByIdAsync(Guid id)
        {
            _logger.LogDebug("Getting {EntityType} with ID {Id}", typeof(T).Name, id);
            return await _dbContext.Set<T>().FindAsync(id);
        }
    }
}
