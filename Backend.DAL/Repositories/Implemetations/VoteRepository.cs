using Backend.DAL.Contexts;
using Backend.DAL.Models;
using Backend.DAL.Repositories.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Repositories.Implemetations
{
    public class VoteRepository : Repository<Vote, IBackendDbContext>, IVoteRepository
    {
        private readonly IBackendDbContext _backendDbContext;

        public VoteRepository(IBackendDbContext dbContext, ILogger logger) 
            : base(dbContext, logger)
        {
            _backendDbContext = dbContext;
        }

        public async Task<IEnumerable<Vote>> GetByMatchIdAsync(Guid matchId)
        {
            _logger.LogDebug("Getting votes for match {MatchId}", matchId);
            return await _backendDbContext.Votes
                .Where(v => v.MatchId == matchId)
                .Include(v => v.Candidate)
                .ToListAsync();
        }

        public async Task<bool> HasUserVotedAsync(Guid matchId, string userId)
        {
            _logger.LogDebug("Checking if user {UserId} voted in match {MatchId}", userId, matchId);
            return await _backendDbContext.Votes
                .AnyAsync(v => v.MatchId == matchId && v.UserId == userId);
        }

        public async Task<Vote?> GetUserVoteAsync(Guid matchId, string userId)
        {
            _logger.LogDebug("Getting vote for user {UserId} in match {MatchId}", userId, matchId);
            return await _backendDbContext.Votes
                .FirstOrDefaultAsync(v => v.MatchId == matchId && v.UserId == userId);
        }
    }
}
