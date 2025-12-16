using Backend.BL.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.Services.Interfaces
{
    public interface ICandidateService
    {
        Task<IEnumerable<CandidateDTO>> GetAllAsync();
        Task<CandidateDTO?> GetByIdAsync(Guid id);
        Task<CandidateDTO> CreateAsync(CandidateDTO candidateDto);
        Task<bool> UpdateAsync(Guid id, CandidateDTO candidateDto);
        Task<bool> DeleteAsync(Guid id);
        
        Task<IEnumerable<CandidateDTO>> GetByElectionIdAsync(Guid electionId);
    }
}
