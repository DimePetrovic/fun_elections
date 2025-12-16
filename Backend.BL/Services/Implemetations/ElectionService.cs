using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Backend.DAL.Repositories;
using Backend.DAL.Models.Auxiliary;
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

        public ElectionService(IUnitOfWork unitOfWork, ILogger<ElectionService> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }
        public async Task<IEnumerable<ElectionDTO>> GetAllAsync()
        {
            var elections = await _unitOfWork.Elections.GetAllAsync();
            var electionDTOs = new List<ElectionDTO>();

            foreach (var e in elections)
            {
                var candidates = await _unitOfWork.Candidates.GetByElectionIdAsync(e.Id);
                electionDTOs.Add(new ElectionDTO
                {
                    Id = e.Id,
                    Name = e.Name,
                    IsPublic = e.isPublic,
                    Description = e.Description,
                    ElectionType = e.ElectionType,
                    Candidates = candidates.Select(c => new CandidateDTO
                    {
                        Id = c.Id,
                        Name = c.Name,
                        Points = c.Points
                    }).ToList()
                });
            }

            return electionDTOs;
        }
    }
}