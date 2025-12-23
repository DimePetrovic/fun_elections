using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class MatchController : ControllerBase
    {
        private readonly ILogger<MatchController> _logger;
        private readonly IMatchService _matchService;

        public MatchController(ILogger<MatchController> logger, IMatchService matchService)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _matchService = matchService ?? throw new ArgumentNullException(nameof(matchService));
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
    }
}
