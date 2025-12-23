using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Models
{
    public class Group : Auxiliary.IdentityModel
    {
        public Guid ElectionId { get; set; }
        public Election Election { get; set; } = null!;
        
        public List<Candidate> Candidates { get; set; } = new();
        public List<int> CandidatePoints { get; set; } = new();
    }
}
