using Backend.BL.DTOs;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.Services.Interfaces
{
    public interface IGroupService
    {
        Task<IEnumerable<GroupDTO>> GetAllAsync();
        Task<GroupDTO?> GetByIdAsync(Guid id);
        Task<IEnumerable<GroupDTO>> GetByElectionIdAsync(Guid electionId);
        Task<GroupDTO> CreateAsync(GroupDTO groupDto);
        Task<bool> UpdateAsync(Guid id, GroupDTO groupDto);
        Task<bool> DeleteAsync(Guid id);
    }
}
