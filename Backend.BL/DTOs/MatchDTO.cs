using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.DTOs
{
    public class MatchDTO
    {
        public Guid Id { get; set; }
        public Guid ElectionId { get; set; }
        public List<CandidateDTO> Candidates { get; set; } = new();
        public List<int> Points { get; set; } = new();
        public TimeSpan TimeDuration { get; set; }
        public bool IsFinished { get; set; }
        public int MatchIndex { get; set; }
        public int RoundNumber { get; set; }
        public bool IsActive { get; set; }
        public Guid? WinnerId { get; set; }
    }
}
