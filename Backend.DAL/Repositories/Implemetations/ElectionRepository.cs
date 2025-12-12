using Backend.DAL.Contexts;
using Backend.DAL.Models;
using Backend.DAL.Repositories.Interfaces;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Repositories.Implemetations
{
    class ElectionRepository : Repository<Election, IBackendDbContext>, IElectionRepository
    {
        public ElectionRepository(IBackendDbContext DbContext, ILogger logger) : base(DbContext, logger)
        {
        }
    }
}
