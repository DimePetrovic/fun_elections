using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Models.Auxiliary
{
   public abstract class IdentityDatedMode
    {
        public DateTime CreatedAt { get; private set; } = DateTime.UtcNow;
    }
}
