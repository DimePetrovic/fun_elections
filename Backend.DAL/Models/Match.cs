using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Models
{
    public class Match : Auxiliary.IdentityModel
    {
        public Guid ElectionId { get; set; }
        public Election Election { get; set; } = null!;
        
        public List<Candidate> Candidates { get; set; } = new();
        public List<Guid> CandidateIds { get; set; } = new(); // For League format - stores candidate IDs without FK
        public List<int> Points { get; set; } = new();
        
        public TimeSpan TimeDuration { get; set; }
        public bool IsFinished { get; set; } = false;
        public int MatchIndex { get; set; } // Sequential match number
        public int RoundNumber { get; set; } = 0; // Round number (for knockout stages)
        public bool IsActive { get; set; } = false; // Only one match can be active at a time
        public Guid? WinnerId { get; set; } // Candidate who won this match
        public Candidate? Winner { get; set; }
    }
}
