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

        public async Task<IEnumerable<Match>> GetByElectionIdAsync(Guid electionId)
        {
            return await _dbContext.Matches
                .Where(m => m.ElectionId == electionId)
                .ToListAsync();
        }
    }
}
