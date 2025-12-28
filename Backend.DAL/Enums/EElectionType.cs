using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.DAL.Enums
{
    public enum EElectionType
    {
        LegacySingleVote = 0,           // Legacy: Each user votes once
        LegacyMultipleVotes = 1,        // Legacy: Each user can vote multiple times (1 point per vote)
        LegacyWeightedVotes = 2,        // Legacy: Each user votes with weighted points
        Knockout = 3,
        GroupThenKnockout = 4,
        League = 5,
        GroupThenLeague = 6
    }
}
