using Backend.DAL.Contexts;
using Backend.DAL.Repositories.Interfaces;
using Backend.Models;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Repositories.Implemetations
{
    class ApplicationUserRepository : Repository<ApplicationUser, IBackendDbContext>, IApplicationUserRepository
    {
        public ApplicationUserRepository(IBackendDbContext dbContext, ILogger<ApplicationUserRepository> logger) : base(dbContext, logger)
        {

        }
    }
}
