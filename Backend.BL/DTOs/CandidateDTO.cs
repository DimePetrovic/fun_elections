using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.DTOs
{
    public class CandidateDTO
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int Points { get; set; }
    }
}
