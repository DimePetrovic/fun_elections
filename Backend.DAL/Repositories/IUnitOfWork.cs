using Backend.DAL.Repositories.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Repositories
{
    public interface IUnitOfWork
    {

        IApplicationUserRepository Users { get; }
        /// <summary>
        /// Save changes to the database
        /// </summary>
        /// <returns>Task with number of entries written to the database</returns>
        Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

        Task<bool> UpdateDatabaseSchemaAsync();

        /// <summary>
        /// Begins a new transaction
        /// </summary>
        Task BeginTransactionAsync();

        /// <summary>
        /// Commits the current transaction
        /// </summary>
        Task CommitTransactionAsync();

        /// <summary>
        /// Rolls back the current transaction
        /// </summary>
        Task RollbackTransactionAsync();

        /// <summary>
        /// Executes an action within a database transaction that returns a value. If the action succeeds, the transaction is committed.
        /// If an exception occurs, the transaction is rolled back and the exception is re-thrown.
        /// </summary>
        /// <typeparam name="T">The type of the result returned by the action</typeparam>
        /// <param name="action">The async function to execute within the transaction</param>
        /// <returns>A task that represents the asynchronous operation. The task result contains the value returned by the action.</returns>
        /// <exception cref="InvalidOperationException">Thrown when a transaction is already in progress</exception>
        /// <example>
        /// <code>
        /// var newId = await unitOfWork.ExecuteInTransactionAsync(async () =>
        /// {
        ///     var subscription = new Subscription { ... };
        ///     await unitOfWork.Subscriptions.AddAsync(subscription);
        ///     await unitOfWork.SaveChangesAsync();
        ///     return subscription.Id;
        /// });
        /// </code>
        /// </example>
        Task<T> ExecuteInTransactionAsync<T>(Func<Task<T>> action);

        /// <summary>
        /// Executes an action within a database transaction. If the action succeeds, the transaction is committed.
        /// If an exception occurs, the transaction is rolled back and the exception is re-thrown.
        /// </summary>
        /// <param name="action">The async action to execute within the transaction</param>
        /// <returns>A task that represents the asynchronous operation.</returns>
        /// <exception cref="InvalidOperationException">Thrown when a transaction is already in progress</exception>
        /// <example>
        /// <code>
        /// await unitOfWork.ExecuteInTransactionAsync(async () =>
        /// {
        ///     var subscription = new Subscription { ... };
        ///     await unitOfWork.Subscriptions.AddAsync(subscription);
        ///     await unitOfWork.SaveChangesAsync();
        /// });
        /// </code>
        /// </example>
        Task ExecuteInTransactionAsync(Func<Task> action);
    }
}
