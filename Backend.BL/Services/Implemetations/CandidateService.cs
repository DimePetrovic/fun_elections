using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Backend.DAL.Repositories;
using Backend.DAL.Models;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.Services.Implemetations
{
    public class CandidateService : ICandidateService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<CandidateService> _logger;

        public CandidateService(IUnitOfWork unitOfWork, ILogger<CandidateService> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }

        public async Task<IEnumerable<CandidateDTO>> GetAllAsync()
        {
            var candidates = await _unitOfWork.Candidates.GetAllAsync();
            return candidates.Select(c => new CandidateDTO
            {
                Id = c.Id,
                Name = c.Name,
                Points = c.Points
            });
        }

        public async Task<CandidateDTO?> GetByIdAsync(Guid id)
        {
            var candidate = await _unitOfWork.Candidates.GetByIdAsync(id);
            if (candidate == null) return null;

            return new CandidateDTO
            {
                Id = candidate.Id,
                Name = candidate.Name,
                Points = candidate.Points
            };
        }

        public async Task<CandidateDTO> CreateAsync(CandidateDTO candidateDTO)
        {
            var candidate = new Candidate
            {
                Id = Guid.NewGuid(),
                Name = candidateDTO.Name,
                Points = candidateDTO.Points
            };

            await _unitOfWork.Candidates.AddAsync(candidate);
            await _unitOfWork.SaveChangesAsync();

            candidateDTO.Id = candidate.Id;
            return candidateDTO;
        }

        public async Task<bool> UpdateAsync(Guid id, CandidateDTO candidateDTO)
        {
            var candidate = await _unitOfWork.Candidates.GetByIdAsync(id);
            if (candidate == null) return false;

            candidate.Name = candidateDTO.Name;
            candidate.Points = candidateDTO.Points;

            await _unitOfWork.Candidates.UpdateAsync(candidate);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var candidate = await _unitOfWork.Candidates.GetByIdAsync(id);
            if (candidate == null) return false;

            await _unitOfWork.Candidates.DeleteAsync(candidate);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        public async Task<IEnumerable<CandidateDTO>> GetByElectionIdAsync(Guid electionId)
        {
            var candidates = await _unitOfWork.Candidates.GetByElectionIdAsync(electionId);
            return candidates.Select(c => new CandidateDTO
            {
                Id = c.Id,
                Name = c.Name,
                Points = c.Points
            });
        }
    }
}
