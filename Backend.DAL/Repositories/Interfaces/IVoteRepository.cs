using Backend.DAL.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Repositories.Interfaces
{
    public interface IVoteRepository : IRepository<Vote>
    {
        Task<IEnumerable<Vote>> GetByMatchIdAsync(Guid matchId);
        Task<bool> HasUserVotedAsync(Guid matchId, string userId);
        Task<Vote?> GetUserVoteAsync(Guid matchId, string userId);
    }
}
