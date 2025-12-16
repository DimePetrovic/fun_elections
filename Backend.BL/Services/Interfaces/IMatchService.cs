using Backend.BL.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.Services.Interfaces
{
    public interface IMatchService
    {
        Task<IEnumerable<MatchDTO>> GetAllAsync();
        Task<MatchDTO?> GetByIdAsync(Guid id);
        Task<IEnumerable<MatchDTO>> GetByElectionIdAsync(Guid electionId);
        Task<MatchDTO> CreateAsync(MatchDTO matchDto);
        Task<bool> UpdateAsync(Guid id, MatchDTO matchDto);
        Task<bool> DeleteAsync(Guid id);
    }
}
