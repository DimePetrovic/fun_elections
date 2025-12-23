using Backend.BL.DTOs;
using Backend.BL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class GroupController : ControllerBase
    {
        private readonly ILogger<GroupController> _logger;
        private readonly IGroupService _groupService;

        public GroupController(ILogger<GroupController> logger, IGroupService groupService)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _groupService = groupService ?? throw new ArgumentNullException(nameof(groupService));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<GroupDTO>>> GetAll()
        {
            try
            {
                var groups = await _groupService.GetAllAsync();
                return Ok(groups);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all groups");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<GroupDTO>> GetById(Guid id)
        {
            try
            {
                var group = await _groupService.GetByIdAsync(id);
                if (group == null)
                {
                    return NotFound($"Group with ID {id} not found");
                }
                return Ok(group);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving group {GroupId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpGet("election/{electionId}")]
        public async Task<ActionResult<IEnumerable<GroupDTO>>> GetByElectionId(Guid electionId)
        {
            try
            {
                var groups = await _groupService.GetByElectionIdAsync(electionId);
                return Ok(groups);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving groups for election {ElectionId}", electionId);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPost]
        public async Task<ActionResult<GroupDTO>> Create([FromBody] GroupDTO groupDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var createdGroup = await _groupService.CreateAsync(groupDTO);
                return CreatedAtAction(nameof(GetById), new { id = createdGroup.Id }, createdGroup);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating group");
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(Guid id, [FromBody] GroupDTO groupDTO)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var result = await _groupService.UpdateAsync(id, groupDTO);
                if (!result)
                {
                    return NotFound($"Group with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating group {GroupId}", id);
                return StatusCode(500, "Internal server error");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            try
            {
                var result = await _groupService.DeleteAsync(id);
                if (!result)
                {
                    return NotFound($"Group with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting group {GroupId}", id);
                return StatusCode(500, "Internal server error");
            }
        }
    }
}
