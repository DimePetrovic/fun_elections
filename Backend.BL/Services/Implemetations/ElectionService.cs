using Backend.BL.Services.Interfaces;
using Backend.DAL.Repositories;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.Services.Implemetations
{
    public class ElectionService : IElectionService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<ElectionService> _logger;

        public ElectionService (IUnitOfWork unitOfWork, ILogger<ElectionService> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }
    }
}
