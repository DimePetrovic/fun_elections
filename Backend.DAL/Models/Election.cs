using Backend.DAL.Enums;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Models
{
    public class Election : Auxiliary.IdentityDatedModel
    {
        public List<Voter> Voters { get; set; } = new();
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public bool isPublic { get; set; }
        public EElectionType ElectionType { get; set; }
        public List<Candidate> Candidates { get; set; } = new();
        public string Code { get; set; } = string.Empty; // Unique join code
        public string AdminId { get; set; } = string.Empty; // Creator user ID
        public EElectionStatus Status { get; set; } = EElectionStatus.Active;
        public int? NumberOfGroups { get; set; } // For group-based formats
        public int? VoteCount { get; set; } // For legacy multiple/weighted votes


    }
}
