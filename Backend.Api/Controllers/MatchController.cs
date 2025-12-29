using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Backend.Api.Hubs;
using System.Security.Claims;

namespace Backend.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MatchController : ControllerBase
    {
        private readonly ILogger<MatchController> _logger;
        private readonly IMatchService _matchService;
        private readonly IElectionService _electionService;
        private readonly IHubContext<ElectionHub> _hubContext;

        public MatchController(
            ILogger<MatchController> logger, 
            IMatchService matchService, 
            IElectionService electionService,
            IHubContext<ElectionHub> hubContext)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _matchService = matchService ?? throw new ArgumentNullException(nameof(matchService));
            _electionService = electionService ?? throw new ArgumentNullException(nameof(electionService));
            _hubContext = hubContext ?? throw new ArgumentNullException(nameof(hubContext));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<MatchDTO>>> GetAll()
        {
            try
            {
                var matches = await _matchService.GetAllAsync();
                return Ok(matches);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all matches");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<MatchDTO>> GetById(Guid id)
        {
            try
            {
                var match = await _matchService.GetByIdAsync(id);
                if (match == null)
                {
                    return NotFound($"Match with ID {id} not found");
                }
                return Ok(match);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving match {MatchId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("election/{electionId}")]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<MatchDTO>>> GetByElectionId(Guid electionId)
        {
            try
            {
                var matches = await _matchService.GetByElectionIdAsync(electionId);
                return Ok(matches);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving matches for election {ElectionId}", electionId);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost]
        public async Task<ActionResult<MatchDTO>> Create([FromBody] MatchDTO matchDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var createdMatch = await _matchService.CreateAsync(matchDTO);
                return CreatedAtAction(nameof(GetById), new { id = createdMatch.Id }, createdMatch);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating match");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(Guid id, [FromBody] MatchDTO matchDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var result = await _matchService.UpdateAsync(id, matchDTO);
                if (!result)
                {
                    return NotFound($"Match with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating match {MatchId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            try
            {
                var result = await _matchService.DeleteAsync(id);
                if (!result)
                {
                    return NotFound($"Match with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting match {MatchId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // POST: api/match/{id}/finish - Admin only: Finish current match
        [HttpPost("{id}/finish")]
        public async Task<ActionResult> FinishMatch(Guid id)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                    return Unauthorized();

                var match = await _matchService.GetByIdAsync(id);
                if (match == null)
                    return NotFound($"Match with ID {id} not found");

                // Check if user is admin of the election
                var election = await _electionService.GetByIdAsync(match.ElectionId);
                if (election == null || election.AdminId != userId)
                    return Forbid("Only election admin can finish matches");

                match.IsFinished = true;
                var result = await _matchService.UpdateAsync(id, match);
                
                if (!result)
                    return BadRequest("Unable to finish match");

                return Ok(new { message = "Match finished successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error finishing match {MatchId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/match/election/{electionId}/active - Get active match for election
        [HttpGet("election/{electionId}/active")]
        [AllowAnonymous]
        public async Task<ActionResult<MatchDTO>> GetActiveMatch(Guid electionId)
        {
            try
            {
                var match = await _matchService.GetActiveMatchAsync(electionId);
                if (match == null)
                    return NotFound("No active match found for this election");

                return Ok(match);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving active match for election {ElectionId}", electionId);
                return StatusCode(500, "Internal server error");
            }
        }

        // POST: api/match/{id}/end - End match (winner determined by vote count)
        [HttpPost("{id}/end")]
        [AllowAnonymous]
        public async Task<ActionResult> EndMatch(Guid id)
        {
            try
            {
                // Get match to find election ID before ending it
                var match = await _matchService.GetByIdAsync(id);
                if (match == null)
                    return NotFound("Match not found");

                var electionId = match.ElectionId;

                // Winner will be determined by vote count in service layer
                var result = await _matchService.EndMatchAsync(id, Guid.Empty);
                if (!result)
                    return BadRequest("Failed to end match");

                // Send SignalR notification to all users in this election
                await _hubContext.Clients.Group($"election_{electionId}")
                    .SendAsync("MatchEnded", new { matchId = id, electionId = electionId });

                _logger.LogInformation("Match {MatchId} ended. SignalR notification sent to election_{ElectionId}", id, electionId);

                return Ok(new { message = "Match ended successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error ending match {MatchId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // POST: api/match/{id}/vote/{candidateId} - Vote in a match
        [HttpPost("{id}/vote/{candidateId}")]
        [AllowAnonymous]
        public async Task<ActionResult> Vote(Guid id, Guid candidateId)
        {
            try
            {
                // Try to get user ID from header first (for anonymous users)
                var userId = Request.Headers["X-User-Id"].FirstOrDefault();
                
                // Fall back to authenticated user
                if (string.IsNullOrEmpty(userId))
                    userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                    return BadRequest("User ID is required");

                var result = await _matchService.VoteInMatchAsync(id, candidateId, userId);
                if (!result)
                    return BadRequest("Failed to record vote");

                return Ok(new { message = "Vote recorded successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error voting in match {MatchId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/match/{id}/user-vote - Get current user's vote in a match
        [HttpGet("{id}/user-vote")]
        [AllowAnonymous]
        public async Task<ActionResult> GetUserVote(Guid id)
        {
            try
            {
                // Try to get user ID from header first (for anonymous users)
                var userId = Request.Headers["X-User-Id"].FirstOrDefault();
                
                // Fall back to authenticated user
                if (string.IsNullOrEmpty(userId))
                    userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                    return Ok(new { candidateId = (string?)null });

                var vote = await _matchService.GetUserVoteAsync(id, userId);
                
                return Ok(new { candidateId = vote?.CandidateId.ToString() });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user vote for match {MatchId}", id);
                return StatusCode(500, "Internal server error");
            }
        }
    }
}
