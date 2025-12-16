using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.DTOs
{
    public class GroupDTO
    {
        public Guid Id { get; set; }
        public Guid ElectionId { get; set; }
        public List<CandidateDTO> Candidates { get; set; } = new();
        public List<int> CandidatePoints { get; set; } = new();
    }
}
