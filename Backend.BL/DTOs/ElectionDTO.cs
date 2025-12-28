using Backend.DAL.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.DTOs
{
    public class ElectionDTO
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public bool IsPublic { get; set; }
        public string Description { get; set; } = string.Empty;
        public EElectionType ElectionType { get; set; }
        public List<CandidateDTO> Candidates { get; set; } = new();
        public string Code { get; set; } = string.Empty;
        public string AdminId { get; set; } = string.Empty;
        public EElectionStatus Status { get; set; }
        public int? NumberOfGroups { get; set; }
        public int? VoteCount { get; set; }
    }
}
