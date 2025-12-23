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
    class GroupRepository : Repository<Group, IBackendDbContext>, IGroupRepository
    {
        public GroupRepository(IBackendDbContext DbContext, ILogger logger) : base(DbContext, logger)
        {       
        }

        public async Task<IEnumerable<Group>> GetByElectionIdAsync(Guid electionId)
        {
            return await _dbContext.Groups
                .Where(g => g.ElectionId == electionId)
                .ToListAsync();
        }
    }
}
