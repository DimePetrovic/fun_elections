using Backend.BL.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.Services.Interfaces
{
    public interface IElectionService
    {
        Task<IEnumerable<ElectionDTO>> GetAllAsync();
        Task<ElectionDTO?> GetByIdAsync(Guid id);
        Task<ElectionDTO?> GetByCodeAsync(string code);
        Task<IEnumerable<ElectionDTO>> GetPublicElectionsAsync();
        Task<IEnumerable<ElectionDTO>> GetElectionsByUserIdAsync(string userId);
        Task<ElectionDTO> CreateAsync(ElectionDTO electionDTO, string adminId);
        Task<ElectionDTO?> UpdateAsync(Guid id, ElectionDTO electionDTO);
        Task<bool> DeleteAsync(Guid id);
        Task<bool> JoinElectionAsync(Guid electionId, string userId);
        Task<bool> LeaveElectionAsync(Guid electionId, string userId);
    }
}
