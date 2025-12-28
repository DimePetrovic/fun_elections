using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Backend.DAL.Repositories;
using Backend.DAL.Models;
using Backend.DAL.Enums;
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
        private readonly IMatchService _matchService;
        private readonly ILogger<ElectionService> _logger;
        private static readonly Random _random = new Random();

        public ElectionService(IUnitOfWork unitOfWork, IMatchService matchService, ILogger<ElectionService> logger)
        {
            _unitOfWork = unitOfWork;
            _matchService = matchService;
            _logger = logger;
        }

        public async Task<IEnumerable<ElectionDTO>> GetAllAsync()
        {
            var elections = await _unitOfWork.Elections.GetAllAsync();
            return await MapElectionsToDTOsAsync(elections);
        }

        public async Task<ElectionDTO?> GetByIdAsync(Guid id)
        {
            var election = await _unitOfWork.Elections.GetByIdAsync(id);
            if (election == null) return null;

            var candidates = await _unitOfWork.Candidates.GetByElectionIdAsync(id);
            return MapToDTO(election, candidates);
        }

        public async Task<ElectionDTO?> GetByCodeAsync(string code)
        {
            var elections = await _unitOfWork.Elections.GetAllAsync();
            var election = elections.FirstOrDefault(e => e.Code == code && !e.isPublic);
            if (election == null) return null;

            var candidates = await _unitOfWork.Candidates.GetByElectionIdAsync(election.Id);
            return MapToDTO(election, candidates);
        }

        public async Task<IEnumerable<ElectionDTO>> GetPublicElectionsAsync()
        {
            var elections = await _unitOfWork.Elections.GetAllAsync();
            var publicElections = elections.Where(e => e.isPublic && e.Status == EElectionStatus.Active);
            return await MapElectionsToDTOsAsync(publicElections);
        }

        public async Task<IEnumerable<ElectionDTO>> GetElectionsByUserIdAsync(string userId)
        {
            var elections = await _unitOfWork.Elections.GetAllAsync();
            var userElections = elections.Where(e => 
                e.AdminId == userId || 
                e.Voters.Any(v => v.UserId == userId)
            );
            return await MapElectionsToDTOsAsync(userElections);
        }

        public async Task<ElectionDTO> CreateAsync(ElectionDTO electionDTO, string adminId)
        {
            var election = new Election
            {
                Name = electionDTO.Name,
                Description = electionDTO.Description,
                isPublic = electionDTO.IsPublic,
                ElectionType = electionDTO.ElectionType,
                Code = electionDTO.IsPublic ? string.Empty : GenerateUniqueCode(),
                AdminId = adminId,
                Status = EElectionStatus.Active,
                NumberOfGroups = electionDTO.NumberOfGroups,
                VoteCount = electionDTO.VoteCount
            };

            await _unitOfWork.Elections.AddAsync(election);

            // Add admin as first voter only if we have a real authenticated user
            // Skip for temp users and anonymous users
            if (adminId != "temp-admin-id" && !adminId.StartsWith("temp-user-") && !adminId.StartsWith("user-"))
            {
                var voter = new Voter
                {
                    ElectionId = election.Id,
                    UserId = adminId
                };
                await _unitOfWork.Voters.AddAsync(voter);
            }

            // Add candidates if provided
            if (electionDTO.Candidates != null && electionDTO.Candidates.Any())
            {
                var candidates = new List<Candidate>();
                foreach (var candidateDTO in electionDTO.Candidates)
                {
                    var candidate = new Candidate
                    {
                        Name = candidateDTO.Name,
                        ElectionId = election.Id,
                        Points = 0
                    };
                    await _unitOfWork.Candidates.AddAsync(candidate);
                    candidates.Add(candidate);
                }

                await _unitOfWork.SaveChangesAsync();

                // Generate matches based on election type
                if (electionDTO.ElectionType == EElectionType.LegacySingleVote ||
                    electionDTO.ElectionType == EElectionType.LegacyMultipleVotes ||
                    electionDTO.ElectionType == EElectionType.LegacyWeightedVotes)
                {
                    await _matchService.GenerateLegacyMatchesAsync(election.Id, candidates);
                }
                else if (electionDTO.ElectionType == EElectionType.Knockout)
                {
                    await _matchService.GenerateKnockoutMatchesAsync(election.Id, candidates);
                }
            }
            else
            {
                await _unitOfWork.SaveChangesAsync();
            }

            var finalCandidates = await _unitOfWork.Candidates.GetByElectionIdAsync(election.Id);
            return MapToDTO(election, finalCandidates);
        }

        public async Task<ElectionDTO?> UpdateAsync(Guid id, ElectionDTO electionDTO)
        {
            var election = await _unitOfWork.Elections.GetByIdAsync(id);
            if (election == null) return null;

            election.Name = electionDTO.Name;
            election.Description = electionDTO.Description;
            election.Status = electionDTO.Status;
            
            await _unitOfWork.SaveChangesAsync();

            var candidates = await _unitOfWork.Candidates.GetByElectionIdAsync(id);
            return MapToDTO(election, candidates);
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            _logger.LogInformation("Attempting to delete/end election with ID: {ElectionId}", id);
            var election = await _unitOfWork.Elections.GetByIdAsync(id);
            if (election == null)
            {
                _logger.LogWarning("Election with ID {ElectionId} not found", id);
                return false;
            }

            // Instead of deleting, mark as ended so users can view history
            _logger.LogInformation("Setting election {ElectionId} status to Ended", id);
            election.Status = EElectionStatus.Ended;
            await _unitOfWork.Elections.UpdateAsync(election);
            await _unitOfWork.SaveChangesAsync();
            _logger.LogInformation("Election {ElectionId} successfully marked as Ended", id);
            return true;
        }

        public async Task<bool> JoinElectionAsync(Guid electionId, string userId)
        {
            var election = await _unitOfWork.Elections.GetByIdAsync(electionId);
            if (election == null || election.Status != EElectionStatus.Active) return false;

            // Skip adding voter for temporary users and anonymous users (no auth)
            // Anonymous users start with "user-" prefix, temp users with "temp-user-"
            if (userId.StartsWith("temp-user-") || userId == "temp-admin-id" || userId.StartsWith("user-"))
                return true;

            // Check if user already joined
            if (election.Voters.Any(v => v.UserId == userId)) return true;

            var voter = new Voter
            {
                ElectionId = electionId,
                UserId = userId
            };

            await _unitOfWork.Voters.AddAsync(voter);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        public async Task<bool> LeaveElectionAsync(Guid electionId, string userId)
        {
            var election = await _unitOfWork.Elections.GetByIdAsync(electionId);
            if (election == null) return false;

            // Skip for temporary users and anonymous users (no auth) - just return success
            if (userId.StartsWith("temp-user-") || userId == "temp-admin-id" || userId.StartsWith("user-"))
                return true;

            // If user is admin, delete entire election
            if (election.AdminId == userId)
            {
                election.Status = EElectionStatus.Ended;
                await _unitOfWork.Elections.DeleteAsync(election);
                await _unitOfWork.SaveChangesAsync();
                return true;
            }

            // Remove voter
            var voter = election.Voters.FirstOrDefault(v => v.UserId == userId);
            if (voter != null)
            {
                await _unitOfWork.Voters.DeleteAsync(voter);
                await _unitOfWork.SaveChangesAsync();
            }

            return true;
        }

        private string GenerateUniqueCode()
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            return new string(Enumerable.Repeat(chars, 6)
                .Select(s => s[_random.Next(s.Length)]).ToArray());
        }

        private async Task<List<ElectionDTO>> MapElectionsToDTOsAsync(IEnumerable<Election> elections)
        {
            var electionDTOs = new List<ElectionDTO>();
            foreach (var e in elections)
            {
                var candidates = await _unitOfWork.Candidates.GetByElectionIdAsync(e.Id);
                electionDTOs.Add(MapToDTO(e, candidates));
            }
            return electionDTOs;
        }

        private ElectionDTO MapToDTO(Election election, IEnumerable<Candidate> candidates)
        {
            return new ElectionDTO
            {
                Id = election.Id,
                Name = election.Name,
                IsPublic = election.isPublic,
                Description = election.Description,
                ElectionType = election.ElectionType,
                Code = election.Code,
                AdminId = election.AdminId,
                Status = election.Status,
                NumberOfGroups = election.NumberOfGroups,
                VoteCount = election.VoteCount,
                Candidates = candidates.Select(c => new CandidateDTO
                {
                    Id = c.Id,
                    Name = c.Name,
                    Points = c.Points
                }).ToList()
            };
        }
    }
}