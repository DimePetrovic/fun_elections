using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Backend.DAL.Repositories;
using Backend.DAL.Models;
using Backend.DAL.Enums;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Backend.BL.Services.Implemetations
{
    public class MatchService : IMatchService
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ILogger<MatchService> _logger;

        public MatchService(IUnitOfWork unitOfWork, ILogger<MatchService> logger)
        {
            _unitOfWork = unitOfWork;
            _logger = logger;
        }

        public async Task<IEnumerable<MatchDTO>> GetAllAsync()
        {
            var matches = await _unitOfWork.Matches.GetAllAsync();
            return matches.Select(m => new MatchDTO
            {
                Id = m.Id,
                ElectionId = m.ElectionId,
                Points = m.Points,
                TimeDuration = m.TimeDuration,
                IsFinished = m.IsFinished,
                MatchIndex = m.MatchIndex
            });
        }

        public async Task<MatchDTO?> GetByIdAsync(Guid id)
        {
            var match = await _unitOfWork.Matches.GetByIdAsync(id);
            if (match == null) return null;

            return new MatchDTO
            {
                Id = match.Id,
                ElectionId = match.ElectionId,
                Candidates = match.Candidates?.Select(c => new CandidateDTO
                {
                    Id = c.Id,
                    Name = c.Name,
                    Points = c.Points
                }).ToList() ?? new List<CandidateDTO>(),
                Points = match.Points,
                TimeDuration = match.TimeDuration,
                IsFinished = match.IsFinished,
                MatchIndex = match.MatchIndex,
                RoundNumber = match.RoundNumber,
                IsActive = match.IsActive,
                WinnerId = match.WinnerId
            };
        }

        public async Task<IEnumerable<MatchDTO>> GetByElectionIdAsync(Guid electionId)
        {
            var matches = await _unitOfWork.Matches.GetByElectionIdAsync(electionId);
            return matches.Select(m => new MatchDTO
            {
                Id = m.Id,
                ElectionId = m.ElectionId,
                Candidates = m.Candidates?.Select(c => new CandidateDTO
                {
                    Id = c.Id,
                    Name = c.Name,
                    Points = c.Points
                }).ToList() ?? new List<CandidateDTO>(),
                Points = m.Points,
                TimeDuration = m.TimeDuration,
                IsFinished = m.IsFinished,
                MatchIndex = m.MatchIndex,
                RoundNumber = m.RoundNumber,
                IsActive = m.IsActive,
                WinnerId = m.WinnerId
            });
        }

        public async Task<MatchDTO> CreateAsync(MatchDTO matchDto)
        {
            var match = new Match
            {
                Id = Guid.NewGuid(),
                ElectionId = matchDto.ElectionId,
                Points = matchDto.Points,
                TimeDuration = matchDto.TimeDuration,
                IsFinished = matchDto.IsFinished,
                MatchIndex = matchDto.MatchIndex
            };

            await _unitOfWork.Matches.AddAsync(match);
            await _unitOfWork.SaveChangesAsync();

            matchDto.Id = match.Id;
            return matchDto;
        }

        public async Task<bool> UpdateAsync(Guid id, MatchDTO matchDto)
        {
            var match = await _unitOfWork.Matches.GetByIdAsync(id);
            if (match == null) return false;

            match.Points = matchDto.Points;
            match.TimeDuration = matchDto.TimeDuration;
            match.IsFinished = matchDto.IsFinished;
            match.MatchIndex = matchDto.MatchIndex;

            await _unitOfWork.Matches.UpdateAsync(match);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var match = await _unitOfWork.Matches.GetByIdAsync(id);
            if (match == null) return false;

            await _unitOfWork.Matches.DeleteAsync(match);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        // Generate matches for Legacy format (single match with all candidates)
        public async Task GenerateLegacyMatchesAsync(Guid electionId, List<Candidate> candidates)
        {
            var match = new Match
            {
                Id = Guid.NewGuid(),
                ElectionId = electionId,
                MatchIndex = 1,
                RoundNumber = 1,
                IsActive = true,
                IsFinished = false,
                Candidates = candidates,
                Points = new List<int>(new int[candidates.Count])
            };

            await _unitOfWork.Matches.AddAsync(match);
            await _unitOfWork.SaveChangesAsync();
        }

        // Generate knockout bracket matches
        public async Task GenerateKnockoutMatchesAsync(Guid electionId, List<Candidate> candidates)
        {
            if (!IsPowerOfTwo(candidates.Count))
                throw new ArgumentException("Number of candidates must be a power of 2 for knockout");

            int n = candidates.Count;
            int totalMatches = n - 1; // Za n kandidata, n-1 meceva
            
            // Kreiraj SVE prazne mečeve (n-1)
            for (int matchIndex = 1; matchIndex <= totalMatches; matchIndex++)
            {
                var match = new Match
                {
                    Id = Guid.NewGuid(),
                    ElectionId = electionId,
                    MatchIndex = matchIndex,
                    IsActive = true,
                    IsFinished = false,
                    Candidates = new List<Candidate>(),
                    Points = new List<int>()
                };
                await _unitOfWork.Matches.AddAsync(match);
            }

            await _unitOfWork.SaveChangesAsync();
            _logger.LogInformation("Created {Count} empty matches", totalMatches);

            // Popuni prvih n/2 mečeva sa kandidatima
            await FillInitialMatchesWithCandidatesAsync(electionId, candidates);
        }

        public async Task FillInitialMatchesWithCandidatesAsync(Guid electionId, List<Candidate> candidates)
        {
            int n = candidates.Count;
            int initialMatchesNumber = n / 2; // Prvih n/2 meceva imaju kandidate

            // Dohvati sve mečeve za ovu election iz baze
            var allMatches = (await _unitOfWork.Matches.GetByElectionIdAsync(electionId))
                .OrderBy(m => m.MatchIndex)
                .ToList();

            // Popuni prvih n/2 mečeva sa kandidatima
            for (int matchIndex = 1; matchIndex <= initialMatchesNumber; matchIndex++)
            {
                var match = allMatches.FirstOrDefault(m => m.MatchIndex == matchIndex);
                if (match == null)
                {
                    _logger.LogError("Match with index {Index} not found!", matchIndex);
                    continue;
                }

                int candidateIndex = (matchIndex - 1) * 2;
                
                if (match.Candidates == null)
                    match.Candidates = new List<Candidate>();
                
                match.Candidates.Add(candidates[candidateIndex]);
                match.Candidates.Add(candidates[candidateIndex + 1]);
                match.Points = new List<int> { 0, 0 };

                await _unitOfWork.Matches.UpdateAsync(match);
                _logger.LogInformation("Filled match {Index} with candidates: {C1} vs {C2}", 
                    matchIndex, candidates[candidateIndex].Name, candidates[candidateIndex + 1].Name);
            }

            await _unitOfWork.SaveChangesAsync();
            
            _logger.LogInformation("Filled {Count} initial matches with candidates", initialMatchesNumber);
        }


        // End match and advance winner (winner determined by vote count)
        public async Task<bool> EndMatchAsync(Guid matchId, Guid winnerId)
        {
            var match = await _unitOfWork.Matches.GetByIdAsync(matchId);
            if (match == null || match.IsFinished) return false;

            // Count votes to determine winner
            var votes = await _unitOfWork.Votes.GetByMatchIdAsync(matchId);
            var voteCounts = votes.GroupBy(v => v.CandidateId)
                .Select(g => new { CandidateId = g.Key, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .ToList();

            // Determine winner
            Guid actualWinnerId;
            if (voteCounts.Any())
            {
                var maxVotes = voteCounts.First().Count;
                var topCandidates = voteCounts.Where(x => x.Count == maxVotes).ToList();

                // If tie (multiple candidates with same max votes), pick randomly
                if (topCandidates.Count > 1)
                {
                    var random = new Random();
                    var randomIndex = random.Next(topCandidates.Count);
                    actualWinnerId = topCandidates[randomIndex].CandidateId;
                    _logger.LogInformation("Tie detected in match {MatchId}. Randomly selected winner: {WinnerId}", 
                        matchId, actualWinnerId);
                }
                else
                {
                    actualWinnerId = voteCounts.First().CandidateId;
                }
            }
            else
            {
                // No votes - pick random candidate from match
                var matchCandidates = match.Candidates.ToList();
                if (matchCandidates.Count > 0)
                {
                    var random = new Random();
                    var randomIndex = random.Next(matchCandidates.Count);
                    actualWinnerId = matchCandidates[randomIndex].Id;
                    _logger.LogInformation("No votes in match {MatchId}. Randomly selected winner: {WinnerId}", 
                        matchId, actualWinnerId);
                }
                else
                {
                    actualWinnerId = winnerId;
                }
            }

            match.WinnerId = actualWinnerId;
            match.IsFinished = true;
            match.IsActive = false;

            await _unitOfWork.Matches.UpdateAsync(match);

            // Award point to winner
            var winner = await _unitOfWork.Candidates.GetByIdAsync(actualWinnerId);
            if (winner != null)
            {
                winner.Points += 1;
                await _unitOfWork.Candidates.UpdateAsync(winner);
            }

            // IMPORTANT: Save winner to database BEFORE creating next match
            await _unitOfWork.SaveChangesAsync();

            // Get election to determine type
            var election = await _unitOfWork.Elections.GetByIdAsync(match.ElectionId);
            if (election == null) return false;

            // For knockout, check if we need to create next match
            if (election.ElectionType == EElectionType.Knockout || 
                election.ElectionType == EElectionType.GroupThenKnockout)
            {
                await AdvanceWinnerInKnockoutAsync(match, actualWinnerId);
                await _unitOfWork.SaveChangesAsync(); // Save new matches immediately
                
                _logger.LogInformation("After AdvanceWinner for match {MatchId}, changes saved", match.Id);
            }

            // IMPORTANT: Re-fetch matches from database after potential new match creation
            // Check if all matches are finished - if so, mark election as Ended
            var allMatches = await _unitOfWork.Matches.GetByElectionIdAsync(match.ElectionId);
            var finishedCount = allMatches.Count(m => m.IsFinished);
            var totalCount = allMatches.Count();
            
            _logger.LogInformation("Election {ElectionId}: {Finished}/{Total} matches finished. Matches: [{MatchList}]", 
                match.ElectionId, finishedCount, totalCount, 
                string.Join(", ", allMatches.Select(m => $"M{m.MatchIndex}({(m.IsFinished ? "✓" : "○")})")));
            
            if (allMatches.All(m => m.IsFinished))
            {
                election.Status = EElectionStatus.Ended;
                await _unitOfWork.Elections.UpdateAsync(election);
                _logger.LogInformation("All matches finished for election {ElectionId}. Status set to Ended.", election.Id);
            }
            else
            {
                _logger.LogInformation("Election {ElectionId} continues. Unfinished matches: {Unfinished}", 
                    match.ElectionId, totalCount - finishedCount);
            }

            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        private async Task AdvanceWinnerInKnockoutAsync(Match finishedMatch, Guid winnerId)
        {
            _logger.LogInformation("🏆 AdvanceWinner START: Match {Index} finished, advancing winner {WinnerId}", 
                finishedMatch.MatchIndex, winnerId);

            var allMatches = (await _unitOfWork.Matches.GetByElectionIdAsync(finishedMatch.ElectionId))
                .OrderBy(m => m.MatchIndex)
                .ToList();

            int n = allMatches.Count + 1; // broj kandidata
            int initialMatchesNumber = n / 2;

            _logger.LogInformation("📊 Tournament stats: n={N}, initial matches={Initial}, total matches={Total}", 
                n, initialMatchesNumber, allMatches.Count);

            // Dodaj pobednika u target mec
            var winner = await _unitOfWork.Candidates.GetByIdAsync(winnerId);
            if (winner == null)
            {
                _logger.LogError("❌ Winner {WinnerId} not found!", winnerId);
                return;
            }

            _logger.LogInformation("✅ Winner found: {Name} (ID: {Id})", winner.Name, winner.Id);

            // Pronađi PRVI mec (od indeksa n/2+1 do n-1) koji ima manje od 2 kandidata I NIJE ZAVRŠEN
            var incompletMatches = allMatches
                .Where(m => m.MatchIndex > initialMatchesNumber && 
                           m.Candidates.Count < 2 && 
                           !m.IsFinished) 
                .OrderBy(m => m.MatchIndex)
                .ToList();

            _logger.LogInformation("🔍 Found {Count} incomplete matches (index > {Initial}): [{List}]",
                incompletMatches.Count, 
                initialMatchesNumber,
                string.Join(", ", incompletMatches.Select(m => $"M{m.MatchIndex}({m.Candidates.Count}/2)")));

            var targetMatch = incompletMatches.FirstOrDefault();
            
            if (targetMatch == null)
            {
                _logger.LogInformation("🏆 Tournament finished! Winner: {Winner}", winner.Name);
                return;
            }

            _logger.LogInformation("🎯 Target match: Index {Index} (currently has {Count} candidates)",
                targetMatch.MatchIndex, targetMatch.Candidates.Count);

            if (targetMatch.Candidates == null)
            {
                targetMatch.Candidates = new List<Candidate>();
                _logger.LogInformation("⚠️ Target match had null Candidates list, created new one");
            }

            // VAŽNO: Dodaj kandidata i odmah postavi Points ako je meč kompletan
            int beforeCount = targetMatch.Candidates.Count;
            targetMatch.Candidates.Add(winner);
            int afterCount = targetMatch.Candidates.Count;

            _logger.LogInformation("➕ Added {Winner} to match {Index}. Candidates: {Before} → {After}",
                winner.Name, targetMatch.MatchIndex, beforeCount, afterCount);
            
            // Ako target mec sada ima 2 kandidata, postavi Points
            if (targetMatch.Candidates.Count == 2)
            {
                targetMatch.Points = new List<int> { 0, 0 };
                _logger.LogInformation("✅✅ Match {Index} is NOW COMPLETE and READY TO PLAY: {C1} vs {C2}", 
                    targetMatch.MatchIndex, 
                    targetMatch.Candidates[0].Name, 
                    targetMatch.Candidates[1].Name);
                _logger.LogInformation("   IsActive={Active}, IsFinished={Finished}, Points={Points}",
                    targetMatch.IsActive, targetMatch.IsFinished, string.Join(",", targetMatch.Points));
            }
            else if (targetMatch.Candidates.Count == 1)
            {
                _logger.LogInformation("⏳ Match {Index} waiting for second candidate. Current: {C1}",
                    targetMatch.MatchIndex, targetMatch.Candidates[0].Name);
            }
            else
            {
                _logger.LogWarning("⚠️ Match {Index} has unexpected candidate count: {Count}",
                    targetMatch.MatchIndex, targetMatch.Candidates.Count);
            }

            await _unitOfWork.Matches.UpdateAsync(targetMatch);
            await _unitOfWork.SaveChangesAsync(); // VAŽNO: Sačuvaj odmah!
            
            _logger.LogInformation("💾 Target match {Index} updated and SAVED to database", targetMatch.MatchIndex);

            // PROVERA: Učitaj ponovo iz baze da potvrdiš da je sačuvano
            var verifyMatch = await _unitOfWork.Matches.GetByIdAsync(targetMatch.Id);
            if (verifyMatch != null)
            {
                _logger.LogInformation("✔️ VERIFICATION: Match {Index} in DB has {Count} candidates: [{Names}]",
                    verifyMatch.MatchIndex, 
                    verifyMatch.Candidates?.Count ?? 0,
                    verifyMatch.Candidates != null ? string.Join(", ", verifyMatch.Candidates.Select(c => c.Name)) : "NULL");
            }
        }

        public async Task<MatchDTO?> GetActiveMatchAsync(Guid electionId)
        {
            var matches = await _unitOfWork.Matches.GetByElectionIdAsync(electionId);
            
            // Vrati prvi aktivan meč koji IMA 2 kandidata (spreman je za igranje)
            var activeMatch = matches
                .Where(m => m.IsActive && !m.IsFinished && m.Candidates.Count == 2)
                .OrderBy(m => m.MatchIndex)
                .FirstOrDefault();
            
            if (activeMatch == null) return null;

            return new MatchDTO
            {
                Id = activeMatch.Id,
                ElectionId = activeMatch.ElectionId,
                Candidates = activeMatch.Candidates?.Select(c => new CandidateDTO
                {
                    Id = c.Id,
                    Name = c.Name,
                    Points = c.Points
                }).ToList() ?? new List<CandidateDTO>(),
                Points = activeMatch.Points,
                TimeDuration = activeMatch.TimeDuration,
                IsFinished = activeMatch.IsFinished,
                MatchIndex = activeMatch.MatchIndex,
                RoundNumber = activeMatch.RoundNumber,
                IsActive = activeMatch.IsActive,
                WinnerId = activeMatch.WinnerId
            };
        }

        // Vote for a candidate in a match
        public async Task<bool> VoteInMatchAsync(Guid matchId, Guid candidateId, string userId)
        {
            // Check if match exists and is active
            var match = await _unitOfWork.Matches.GetByIdAsync(matchId);
            if (match == null || !match.IsActive || match.IsFinished)
            {
                _logger.LogWarning("Cannot vote: Match {MatchId} is not active or is finished", matchId);
                return false;
            }

            // Check if election is still active (not ended)
            var election = await _unitOfWork.Elections.GetByIdAsync(match.ElectionId);
            if (election == null || election.Status != EElectionStatus.Active)
            {
                _logger.LogWarning("Cannot vote: Election {ElectionId} is not active", match.ElectionId);
                return false;
            }

            // Check if candidate is in this match
            var candidate = match.Candidates?.FirstOrDefault(c => c.Id == candidateId);
            if (candidate == null)
            {
                _logger.LogWarning("Candidate {CandidateId} not found in match {MatchId}", candidateId, matchId);
                return false;
            }

            // Check if user already voted
            var existingVote = await _unitOfWork.Votes.GetUserVoteAsync(matchId, userId);
            if (existingVote != null)
            {
                // Update existing vote
                existingVote.CandidateId = candidateId;
                existingVote.UpdatedAt = DateTime.UtcNow;
                await _unitOfWork.Votes.UpdateAsync(existingVote);
                _logger.LogInformation("User {UserId} updated vote in match {MatchId} to candidate {CandidateId}", userId, matchId, candidateId);
            }
            else
            {
                // Create new vote
                var vote = new Vote
                {
                    Id = Guid.NewGuid(),
                    MatchId = matchId,
                    CandidateId = candidateId,
                    UserId = userId,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };

                await _unitOfWork.Votes.AddAsync(vote);
                _logger.LogInformation("User {UserId} voted in match {MatchId} for candidate {CandidateId}", userId, matchId, candidateId);
            }

            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        // Get user's vote in a match
        public async Task<Vote?> GetUserVoteAsync(Guid matchId, string userId)
        {
            return await _unitOfWork.Votes.GetUserVoteAsync(matchId, userId);
        }

        private bool IsPowerOfTwo(int n)
        {
            return n > 0 && (n & (n - 1)) == 0;
        }
    }
}
