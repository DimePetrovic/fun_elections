using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.DTOs
{
    public class VoterDTO
    {
        public Guid Id { get; set; }
        public Guid ElectionId { get; set; }
        public string UserId { get; set; } = string.Empty;
    }
}
