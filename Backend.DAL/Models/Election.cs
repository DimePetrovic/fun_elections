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
        public bool isPublic { get; set; }
        public string Description { get; set; } = string.Empty;
        public EElectionType ElectionType { get; set; } 
    }
}
