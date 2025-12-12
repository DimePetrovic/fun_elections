using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Backend.BL.Services.Interfaces;
using Backend.DAL.Repositories;
using Microsoft.Extensions.Logging;

namespace Backend.BL.Services.Implemetations
{
    public class VoterService : IVoterService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<VoterService> _logger;
        public VoterService(IUnitOfWork unitOfWork, ILogger<VoterService> logger)
        {
            _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }
    }
}
