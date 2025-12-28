using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace Backend.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ElectionController : ControllerBase
    {
        private readonly ILogger<ElectionController> _logger;
        private readonly IElectionService _electionService;

        public ElectionController(ILogger<ElectionController> logger, IElectionService electionService)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _electionService = electionService ?? throw new ArgumentNullException(nameof(electionService));
        }

        // GET: api/election
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var elections = await _electionService.GetAllAsync();
                // Filter to only show active elections in public list
                var activeElections = elections.Where(e => e.Status == 0); // 0 = Active
                return Ok(activeElections);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all elections");
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/election/{id}
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                var election = await _electionService.GetByIdAsync(id);
                if (election == null)
                    return NotFound($"Election with id {id} not found");

                return Ok(election);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting election {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/election/code/{code}
        [HttpGet("code/{code}")]
        public async Task<IActionResult> GetByCode(string code)
        {
            try
            {
                var election = await _electionService.GetByCodeAsync(code);
                if (election == null)
                    return NotFound($"Election with code {code} not found");

                return Ok(election);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting election by code {Code}", code);
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/election/public
        [HttpGet("public")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPublicElections()
        {
            try
            {
                var elections = await _electionService.GetPublicElectionsAsync();
                return Ok(elections);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting public elections");
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/election/my
        [HttpGet("my")]
        public async Task<IActionResult> GetMyElections()
        {
            try
            {
                // Try to get user ID from header first (for anonymous users)
                var userId = Request.Headers["X-User-Id"].FirstOrDefault();
                
                // Fall back to authenticated user
                if (string.IsNullOrEmpty(userId))
                    userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                
                if (string.IsNullOrEmpty(userId))
                    return Unauthorized();

                var elections = await _electionService.GetElectionsByUserIdAsync(userId);
                return Ok(elections);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user elections");
                return StatusCode(500, "Internal server error");
            }
        }

        // POST: api/election
        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> Create([FromBody] ElectionDTO electionDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                // Try to get user ID from header first (for anonymous users)
                var userId = Request.Headers["X-User-Id"].FirstOrDefault();
                
                // Fall back to authenticated user
                if (string.IsNullOrEmpty(userId))
                    userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                
                // Temporary fallback for development
                if (string.IsNullOrEmpty(userId))
                    userId = "temp-admin-id";

                var created = await _electionService.CreateAsync(electionDTO, userId);
                return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating election");
                return StatusCode(500, "Internal server error");
            }
        }

        // PUT: api/election/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] ElectionDTO electionDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                var updated = await _electionService.UpdateAsync(id, electionDTO);
                if (updated == null)
                    return NotFound($"Election with id {id} not found");

                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating election {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // DELETE: api/election/{id}
        [HttpDelete("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                var result = await _electionService.DeleteAsync(id);
                if (!result)
                    return NotFound($"Election with id {id} not found");

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting election {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // POST: api/election/{id}/join
        [HttpPost("{id}/join")]
        [AllowAnonymous]
        public async Task<IActionResult> Join(Guid id)
        {
            try
            {
                // Try to get user ID from header first (for anonymous users)
                var userId = Request.Headers["X-User-Id"].FirstOrDefault();
                
                // Fall back to authenticated user
                if (string.IsNullOrEmpty(userId))
                    userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                
                // Temporary fallback for development
                if (string.IsNullOrEmpty(userId))
                    userId = "temp-user-" + Guid.NewGuid().ToString();

                var result = await _electionService.JoinElectionAsync(id, userId);
                if (!result)
                    return BadRequest("Unable to join election");

                return Ok(new { message = "Successfully joined election" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error joining election {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        // POST: api/election/{id}/leave
        [HttpPost("{id}/leave")]
        [AllowAnonymous]
        public async Task<IActionResult> Leave(Guid id)
        {
            try
            {
                // Try to get user ID from header first (for anonymous users)
                var userId = Request.Headers["X-User-Id"].FirstOrDefault();
                
                // Fall back to authenticated user
                if (string.IsNullOrEmpty(userId))
                    userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                
                // Temporary fallback for development
                if (string.IsNullOrEmpty(userId))
                    userId = "temp-user-" + Guid.NewGuid().ToString();

                var result = await _electionService.LeaveElectionAsync(id, userId);
                if (!result)
                    return BadRequest("Unable to leave election");

                return Ok(new { message = "Successfully left election" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error leaving election {Id}", id);
                return StatusCode(500, "Internal server error");
            }
        }
    }
}
