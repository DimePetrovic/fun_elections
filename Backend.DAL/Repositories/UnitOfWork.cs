using Backend.DAL.Contexts;
using Backend.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Repositories
{
   internal class UnitOfWork : IUnitOfWork
    {

        private readonly IBackendDbContext _dbContext;
        private IDbContextTransaction? _currentTransaction;

        public IApplicationUserRepository Users { get; private set; }

        private bool _disposed;
        private readonly ILogger<UnitOfWork> _logger;



        public UnitOfWork(IApplicationUserRepository userRepository, IBackendDbContext backendDbContext, ILogger<UnitOfWork> logger) {
            
            _dbContext = backendDbContext;
            _logger = logger;

            Users = userRepository;
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            ThrowIfDisposed();
            _logger.LogDebug("Saving changes to database");
            try
            {
                var result = await _dbContext.SaveChangesAsync(cancellationToken);
                _logger.LogDebug("Successfully saved {Count} changes to database", result);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving changes to database");
                throw; // Re-throw to let caller handle
            }
        }

        #region Transactions
        public async Task BeginTransactionAsync()
        {
            _logger.LogDebug("Beginning new database transaction");

            if (_currentTransaction != null)
            {
                throw new InvalidOperationException("A transaction is already in progress");
            }

            _currentTransaction = await _dbContext.Database.BeginTransactionAsync();
            _logger.LogDebug("Transaction started");
        }

        public async Task CommitTransactionAsync()
        {
            _logger.LogDebug("Committing transaction");

            try
            {
                if (_currentTransaction == null)
                {
                    throw new InvalidOperationException("No transaction is in progress");
                }

                await _dbContext.SaveChangesAsync();
                await _currentTransaction.CommitAsync();
                _logger.LogInformation("Transaction committed successfully");
            }
            finally
            {
                if (_currentTransaction != null)
                {
                    await _currentTransaction.DisposeAsync();
                    _currentTransaction = null;
                }
            }
        }

        public async Task RollbackTransactionAsync()
        {
            _logger.LogDebug("Rolling back transaction");

            try
            {
                if (_currentTransaction == null)
                {
                    throw new InvalidOperationException("No transaction is in progress");
                }

                await _currentTransaction.RollbackAsync();
                _logger.LogInformation("Transaction rolled back successfully");
            }
            finally
            {
                if (_currentTransaction != null)
                {
                    await _currentTransaction.DisposeAsync();
                    _currentTransaction = null;
                }
            }
        }

        /// <inheritdoc />
        public async Task ExecuteInTransactionAsync(Func<Task> action)
        {
            try
            {
                await BeginTransactionAsync();
                await action();
                await CommitTransactionAsync();
            }
            catch (Exception)
            {
                await RollbackTransactionAsync();
                throw;
            }
        }

        /// <inheritdoc />
        public async Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> action)
        {
            try
            {
                await BeginTransactionAsync();
                var result = await action();
                await CommitTransactionAsync();
                return result;
            }
            catch (Exception)
            {
                await RollbackTransactionAsync();
                throw;
            }
        }
        #endregion

        #region Infrastructure
        public async Task<bool> UpdateDatabaseSchemaAsync()
        {
            try
            {
                _logger.LogInformation("Updating database schema");
                IMigrator migrator = _dbContext.GetService<IMigrator>();
                await migrator.MigrateAsync();
                _logger.LogInformation("Database schema updated successfully");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating database schema");
                return false;
            }
        }
        #endregion

        #region IDisposable
        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    _currentTransaction?.Dispose();
                    _dbContext.Dispose();
                }
                _disposed = true;
            }
        }
        #endregion

        #region IAsyncDisposable
        public async ValueTask DisposeAsync()
        {
            await DisposeAsyncCore();
            Dispose(false);
            GC.SuppressFinalize(this);
        }

        protected virtual async ValueTask DisposeAsyncCore()
        {
            if (_currentTransaction != null)
            {
                await _currentTransaction.DisposeAsync();
            }
            await _dbContext.DisposeAsync();
        }
        #endregion

        protected void ThrowIfDisposed()
        {
            if (_disposed)
            {
                throw new ObjectDisposedException(nameof(UnitOfWork));
            }
        }



    }
}
