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
    public class GroupService : IGroupService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<GroupService> _logger;

        public GroupService(IUnitOfWork unitOfWork, ILogger<GroupService> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }

        public async Task<IEnumerable<GroupDTO>> GetAllAsync()
        {
            var groups = await _unitOfWork.Groups.GetAllAsync();
            return groups.Select(g => new GroupDTO
            {
                Id = g.Id,
                ElectionId = g.ElectionId,
                CandidatePoints = g.CandidatePoints
            });
        }

        public async Task<GroupDTO?> GetByIdAsync(Guid id)
        {
            var group = await _unitOfWork.Groups.GetByIdAsync(id);
            if (group == null) return null;

            return new GroupDTO
            {
                Id = group.Id,
                ElectionId = group.ElectionId,
                CandidatePoints = group.CandidatePoints
            };
        }

        public async Task<IEnumerable<GroupDTO>> GetByElectionIdAsync(Guid electionId)
        {
            var groups = await _unitOfWork.Groups.GetByElectionIdAsync(electionId);
            return groups.Select(g => new GroupDTO
            {
                Id = g.Id,
                ElectionId = g.ElectionId,
                CandidatePoints = g.CandidatePoints
            });
        }

        public async Task<GroupDTO> CreateAsync(GroupDTO groupDTO)
        {
            var group = new Group
            {
                Id = Guid.NewGuid(),
                ElectionId = groupDTO.ElectionId,
                CandidatePoints = groupDTO.CandidatePoints
            };

            await _unitOfWork.Groups.AddAsync(group);
            await _unitOfWork.SaveChangesAsync();

            groupDTO.Id = group.Id;
            return groupDTO;
        }

        public async Task<bool> UpdateAsync(Guid id, GroupDTO groupDTO)
        {
            var group = await _unitOfWork.Groups.GetByIdAsync(id);
            if (group == null) return false;

            group.CandidatePoints = groupDTO.CandidatePoints;

            await _unitOfWork.Groups.UpdateAsync(group);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var group = await _unitOfWork.Groups.GetByIdAsync(id);
            if (group == null) return false;

            await _unitOfWork.Groups.DeleteAsync(group);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }
    }
}
