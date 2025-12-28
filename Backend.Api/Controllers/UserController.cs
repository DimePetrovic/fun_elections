using Backend.BL.DTOs;
using Backend.DAL.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UserController : ControllerBase
    {
        private readonly ILogger<UserController> _logger;
        private readonly UserManager<ApplicationUser> _userManager;

        public UserController(ILogger<UserController> logger, UserManager<ApplicationUser> userManager)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _userManager = userManager ?? throw new ArgumentNullException(nameof(userManager));
        }

        // POST: api/user/register
        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] ApplicationUserDTO dto)
        {
            try
            {
                var user = new ApplicationUser
                {
                    UserName = dto.Username,
                    DisplayName = dto.DisplayName ?? dto.Username,
                    Email = dto.Email
                };

                var result = await _userManager.CreateAsync(user, dto.Password!);
                
                if (!result.Succeeded)
                {
                    return BadRequest(new { errors = result.Errors.Select(e => e.Description) });
                }

                return Ok(new { userId = user.Id, username = user.UserName, displayName = user.DisplayName });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating user");
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/user/{userId}
        [HttpGet("{userId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetUser(string userId)
        {
            try
            {
                var user = await _userManager.FindByIdAsync(userId);
                if (user == null)
                    return NotFound("User not found");

                return Ok(new { userId = user.Id, username = user.UserName, displayName = user.DisplayName });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user {UserId}", userId);
                return StatusCode(500, "Internal server error");
            }
        }

        // PUT: api/user/{userId}/username
        [HttpPut("{userId}/username")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateUsername(string userId, [FromBody] ApplicationUserDTO dto)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(dto.Username) || dto.Username.Length > 100)
                    return BadRequest("Username must be between 1 and 100 characters");

                var user = await _userManager.FindByIdAsync(userId);
                if (user == null)
                    return NotFound("User not found");

                // Check if username is taken
                var existingUser = await _userManager.FindByNameAsync(dto.Username);
                if (existingUser != null && existingUser.Id != userId)
                    return BadRequest("Username already taken");

                user.UserName = dto.Username;
                user.DisplayName = dto.Username;
                var result = await _userManager.UpdateAsync(user);

                if (!result.Succeeded)
                    return BadRequest("Failed to update username");

                return Ok(new { message = "Username updated successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating username for user {UserId}", userId);
                return StatusCode(500, "Internal server error");
            }
        }

        // GET: api/user/check-username/{username}
        [HttpGet("check-username/{username}")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckUsernameAvailability(string username)
        {
            try
            {
                var user = await _userManager.FindByNameAsync(username);
                var available = user == null;
                return Ok(new { available });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking username availability");
                return StatusCode(500, "Internal server error");
            }
        }
    }
}
