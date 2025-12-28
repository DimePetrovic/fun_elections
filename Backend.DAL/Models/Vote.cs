using Backend.DAL.Models.Auxiliary;
using System;

namespace Backend.DAL.Models
{
    public class Vote : IdentityModel
    {
        public Guid MatchId { get; set; }
        public Match Match { get; set; } = null!;
        
        public Guid CandidateId { get; set; }
        public Candidate Candidate { get; set; } = null!;
        
        public string UserId { get; set; } = string.Empty; // Can be anonymous user ID
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
