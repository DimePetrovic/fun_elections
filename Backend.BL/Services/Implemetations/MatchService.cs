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
    public class MatchService : IMatchService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<MatchService> _logger;

        public MatchService(IUnitOfWork unitOfWork, ILogger<MatchService> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }

        public async Task<IEnumerable<MatchDTO>> GetAllAsync()
        {
            var matches = await _unitOfWork.Matches.GetAllAsync();
            return matches.Select(m => new MatchDTO
            {
                Id = m.Id,
                ElectionId = m.ElectionId,
                Points = m.Points,
                TimeDuration = m.TimeDuration,
                IsFinished = m.IsFinished,
                MatchIndex = m.MatchIndex
            });
        }

        public async Task<MatchDTO?> GetByIdAsync(Guid id)
        {
            var match = await _unitOfWork.Matches.GetByIdAsync(id);
            if (match == null) return null;

            return new MatchDTO
            {
                Id = match.Id,
                ElectionId = match.ElectionId,
                Points = match.Points,
                TimeDuration = match.TimeDuration,
                IsFinished = match.IsFinished,
                MatchIndex = match.MatchIndex
            };
        }

        public async Task<IEnumerable<MatchDTO>> GetByElectionIdAsync(Guid electionId)
        {
            var matches = await _unitOfWork.Matches.GetByElectionIdAsync(electionId);
            return matches.Select(m => new MatchDTO
            {
                Id = m.Id,
                ElectionId = m.ElectionId,
                Points = m.Points,
                TimeDuration = m.TimeDuration,
                IsFinished = m.IsFinished,
                MatchIndex = m.MatchIndex
            });
        }

        public async Task<MatchDTO> CreateAsync(MatchDTO matchDto)
        {
            var match = new Match
            {
                Id = Guid.NewGuid(),
                ElectionId = matchDto.ElectionId,
                Points = matchDto.Points,
                TimeDuration = matchDto.TimeDuration,
                IsFinished = matchDto.IsFinished,
                MatchIndex = matchDto.MatchIndex
            };

            await _unitOfWork.Matches.AddAsync(match);
            await _unitOfWork.SaveChangesAsync();

            matchDto.Id = match.Id;
            return matchDto;
        }

        public async Task<bool> UpdateAsync(Guid id, MatchDTO matchDto)
        {
            var match = await _unitOfWork.Matches.GetByIdAsync(id);
            if (match == null) return false;

            match.Points = matchDto.Points;
            match.TimeDuration = matchDto.TimeDuration;
            match.IsFinished = matchDto.IsFinished;
            match.MatchIndex = matchDto.MatchIndex;

            await _unitOfWork.Matches.UpdateAsync(match);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var match = await _unitOfWork.Matches.GetByIdAsync(id);
            if (match == null) return false;

            await _unitOfWork.Matches.DeleteAsync(match);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }
    }
}
