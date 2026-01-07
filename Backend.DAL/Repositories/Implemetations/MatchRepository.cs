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
    class MatchRepository : Repository<Match, IBackendDbContext>, IMatchRepository
    {
        public MatchRepository(IBackendDbContext DbContext, ILogger logger) : base(DbContext, logger)
        {       
        }

        public override async Task<Match?> GetByIdAsync(Guid id)
        {
            var match = await _dbContext.Matches
                .Include(m => m.Candidates)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (match != null && match.CandidateIds != null && match.CandidateIds.Any())
            {
                // For League matches: populate Candidates from CandidateIds
                var candidates = await _dbContext.Candidates
                    .Where(c => match.CandidateIds.Contains(c.Id))
                    .ToListAsync();
                
                match.Candidates = candidates;
            }

            return match;
        }

        public async Task<IEnumerable<Match>> GetByElectionIdAsync(Guid electionId)
        {
            var matches = await _dbContext.Matches
                .Where(m => m.ElectionId == electionId)
                .Include(m => m.Candidates)
                .ToListAsync();

            // For League matches: populate Candidates from CandidateIds
            foreach (var match in matches)
            {
                if (match.CandidateIds != null && match.CandidateIds.Any())
                {
                    // Load candidates by IDs
                    var candidates = await _dbContext.Candidates
                        .Where(c => match.CandidateIds.Contains(c.Id))
                        .ToListAsync();
                    
                    match.Candidates = candidates;
                }
            }

            return matches;
        }
    }
}
