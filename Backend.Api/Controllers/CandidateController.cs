using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class CandidateController : ControllerBase
    {
        private readonly ILogger<CandidateController> _logger;
        private readonly ICandidateService _candidateService;

        public CandidateController(ILogger<CandidateController> logger, ICandidateService candidateService)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _candidateService = candidateService ?? throw new ArgumentNullException(nameof(candidateService));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<CandidateDTO>>> GetAll()
        {
            try
            {
                var candidates = await _candidateService.GetAllAsync();
                return Ok(candidates);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all candidates");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<CandidateDTO>> GetById(Guid id)
        {
            try
            {
                var candidate = await _candidateService.GetByIdAsync(id);
                if (candidate == null)
                {
                    return NotFound($"Candidate with ID {id} not found");
                }
                return Ok(candidate);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving candidate {CandidateId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("election/{electionId}")]
        public async Task<ActionResult<IEnumerable<CandidateDTO>>> GetByElectionId(Guid electionId)
        {
            try
            {
                var candidates = await _candidateService.GetByElectionIdAsync(electionId);
                return Ok(candidates);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving candidates for election {ElectionId}", electionId);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost]
        public async Task<ActionResult<CandidateDTO>> Create([FromBody] CandidateDTO candidateDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var createdCandidate = await _candidateService.CreateAsync(candidateDTO);
                return CreatedAtAction(nameof(GetById), new { id = createdCandidate.Id }, createdCandidate);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating candidate");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(Guid id, [FromBody] CandidateDTO candidateDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var result = await _candidateService.UpdateAsync(id, candidateDTO);
                if (!result)
                {
                    return NotFound($"Candidate with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating candidate {CandidateId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            try
            {
                var result = await _candidateService.DeleteAsync(id);
                if (!result)
                {
                    return NotFound($"Candidate with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting candidate {CandidateId}", id);
                return StatusCode(500, "Internal server error");
            }
        }
    }
}
