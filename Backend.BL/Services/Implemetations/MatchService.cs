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

            // Use exact order from frontend: candidates are already in correct order
            // For 4 candidates: Match 1 (C1 vs C2), Match 2 (C3 vs C4)
            // For 8 candidates: Match 1 (C1 vs C2), Match 2 (C3 vs C4), Match 3 (C5 vs C6), Match 4 (C7 vs C8)
            
            // Create first round matches
            int matchIndex = 1;
            for (int i = 0; i < candidates.Count; i += 2)
            {
                var match = new Match
                {
                    Id = Guid.NewGuid(),
                    ElectionId = electionId,
                    MatchIndex = matchIndex,
                    RoundNumber = 1,
                    IsActive = matchIndex == 1, // Only first match is active
                    IsFinished = false,
                    Candidates = new List<Candidate> { candidates[i], candidates[i + 1] },
                    Points = new List<int> { 0, 0 }
                };

                await _unitOfWork.Matches.AddAsync(match);
                matchIndex++;
            }

            await _unitOfWork.SaveChangesAsync();
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

            // Set winner as the candidate with most votes
            Guid actualWinnerId = voteCounts.Any() ? voteCounts.First().CandidateId : winnerId;

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

            // Get election to determine type
            var election = await _unitOfWork.Elections.GetByIdAsync(match.ElectionId);
            if (election == null) return false;

            // For knockout, check if we need to create next match
            if (election.ElectionType == EElectionType.Knockout || 
                election.ElectionType == EElectionType.GroupThenKnockout)
            {
                await AdvanceWinnerInKnockoutAsync(match, actualWinnerId);
                await _unitOfWork.SaveChangesAsync(); // Save new matches immediately
            }

            // Check if all matches are finished - if so, mark election as Ended
            var allMatches = await _unitOfWork.Matches.GetByElectionIdAsync(match.ElectionId);
            if (allMatches.All(m => m.IsFinished))
            {
                election.Status = EElectionStatus.Ended;
                await _unitOfWork.Elections.UpdateAsync(election);
                _logger.LogInformation("All matches finished for election {ElectionId}. Status set to Ended.", election.Id);
            }

            await _unitOfWork.SaveChangesAsync();
            return true;
        }

        private async Task AdvanceWinnerInKnockoutAsync(Match finishedMatch, Guid winnerId)
        {
            // Get all matches from current round
            var allMatches = (await _unitOfWork.Matches.GetByElectionIdAsync(finishedMatch.ElectionId))
                .OrderBy(m => m.RoundNumber)
                .ThenBy(m => m.MatchIndex)
                .ToList();

            var currentRoundMatches = allMatches
                .Where(m => m.RoundNumber == finishedMatch.RoundNumber)
                .OrderBy(m => m.MatchIndex)
                .ToList();

            // Check how many matches finished in current round
            var finishedInRound = currentRoundMatches.Where(m => m.IsFinished).ToList();
            
            _logger.LogInformation("Round {Round}: {Finished}/{Total} matches finished", 
                finishedMatch.RoundNumber, finishedInRound.Count, currentRoundMatches.Count);

            // If this is the last match (final), tournament is over
            if (currentRoundMatches.Count == 1)
            {
                _logger.LogInformation("Tournament finished! Winner: {WinnerId}", winnerId);
                return;
            }

            // Determine which pair this match belongs to
            // For 4 candidates: Match 1 and Match 2 are pair 0
            // For 8 candidates: Match 1-2 are pair 0, Match 3-4 are pair 1, etc.
            int matchIndexInRound = finishedMatch.MatchIndex - currentRoundMatches.First().MatchIndex;
            int pairIndex = matchIndexInRound / 2;
            
            // Get both matches in the pair
            var firstMatchInPair = currentRoundMatches.ElementAtOrDefault(pairIndex * 2);
            var secondMatchInPair = currentRoundMatches.ElementAtOrDefault(pairIndex * 2 + 1);

            _logger.LogInformation("Match {MatchIndex} belongs to pair {PairIndex}. First: MatchIndex {First}, Second: MatchIndex {Second}", 
                finishedMatch.MatchIndex, pairIndex, 
                firstMatchInPair?.MatchIndex, secondMatchInPair?.MatchIndex);

            if (firstMatchInPair != null && secondMatchInPair != null && 
                firstMatchInPair.IsFinished && secondMatchInPair.IsFinished)
            {
                // Both matches in pair finished - create next round match with BOTH winners
                var winner1 = await _unitOfWork.Candidates.GetByIdAsync(firstMatchInPair.WinnerId!.Value);
                var winner2 = await _unitOfWork.Candidates.GetByIdAsync(secondMatchInPair.WinnerId!.Value);

                if (winner1 == null || winner2 == null)
                {
                    _logger.LogError("Winners not found for advancing knockout. Winner1: {W1}, Winner2: {W2}", 
                        firstMatchInPair.WinnerId, secondMatchInPair.WinnerId);
                    return;
                }

                _logger.LogInformation("Both matches in pair {PairIndex} finished. Creating next round match: {Winner1} vs {Winner2}", 
                    pairIndex, winner1.Name, winner2.Name);

                // Check if next round match already exists for these winners
                var nextRoundMatches = allMatches.Where(m => m.RoundNumber == finishedMatch.RoundNumber + 1).ToList();
                var existingNextMatch = nextRoundMatches.FirstOrDefault(m => 
                    m.Candidates.Any(c => c.Id == winner1.Id) && m.Candidates.Any(c => c.Id == winner2.Id));

                if (existingNextMatch == null)
                {
                    // Calculate next match index in the new round
                    int nextRoundMatchIndex = nextRoundMatches.Any() ? nextRoundMatches.Max(m => m.MatchIndex) + 1 : 1;

                    var nextMatch = new Match
                    {
                        Id = Guid.NewGuid(),
                        ElectionId = finishedMatch.ElectionId,
                        MatchIndex = nextRoundMatchIndex,
                        RoundNumber = finishedMatch.RoundNumber + 1,
                        IsActive = true, // Activate immediately
                        IsFinished = false,
                        Candidates = new List<Candidate> { winner1, winner2 },
                        Points = new List<int> { 0, 0 }
                    };

                    await _unitOfWork.Matches.AddAsync(nextMatch);
                    _logger.LogInformation("✅ Created Round {Round} Match {MatchIndex}: {Winner1} vs {Winner2}", 
                        nextMatch.RoundNumber, nextMatch.MatchIndex, winner1.Name, winner2.Name);
                }
                else
                {
                    _logger.LogInformation("Next round match already exists for {Winner1} vs {Winner2}", 
                        winner1.Name, winner2.Name);
                }
            }
            else
            {
                _logger.LogInformation("Pair {PairIndex} not complete yet. First finished: {First}, Second finished: {Second}", 
                    pairIndex, firstMatchInPair?.IsFinished, secondMatchInPair?.IsFinished);
                
                // Pair not complete yet - activate next unfinished match in current round
                var nextUnfinished = currentRoundMatches
                    .Where(m => !m.IsFinished && !m.IsActive)
                    .OrderBy(m => m.MatchIndex)
                    .FirstOrDefault();

                if (nextUnfinished != null)
                {
                    nextUnfinished.IsActive = true;
                    await _unitOfWork.Matches.UpdateAsync(nextUnfinished);
                    _logger.LogInformation("Activated next match in round: MatchIndex {Index}", nextUnfinished.MatchIndex);
                }
            }
        }

        public async Task<MatchDTO?> GetActiveMatchAsync(Guid electionId)
        {
            var matches = await _unitOfWork.Matches.GetByElectionIdAsync(electionId);
            var activeMatch = matches.FirstOrDefault(m => m.IsActive && !m.IsFinished);
            
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
