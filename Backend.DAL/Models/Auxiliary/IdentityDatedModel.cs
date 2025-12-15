using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Models.Auxiliary
{
   public abstract class IdentityDatedModel : IdentityModel
    {
        public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    }
}
