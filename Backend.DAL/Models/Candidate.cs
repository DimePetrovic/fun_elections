using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Models
{
    public class Candidate : Auxiliary.IdentityModel
    {
        public string Name { get; set; } = string.Empty;
        public int Points { get; set; } = 0;

        public Guid ElectionId { get; set; }
        
    }
}
