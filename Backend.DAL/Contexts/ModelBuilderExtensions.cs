using Microsoft.EntityFrameworkCore;
using Backend.DAL.Models;

namespace Backend.DAL.Contexts
{
    public static class ModelBuilderExtensions
    {
        public static void ConfigureVotesCascade(this ModelBuilder modelBuilder)
        {
            // Only one cascade allowed, the other must be Restrict/NoAction
            modelBuilder.Entity<Vote>()
                .HasOne(v => v.Match)
                .WithMany()
                .HasForeignKey(v => v.MatchId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Vote>()
                .HasOne(v => v.Candidate)
                .WithMany()
                .HasForeignKey(v => v.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
