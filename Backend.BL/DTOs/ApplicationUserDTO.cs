using System.ComponentModel.DataAnnotations;

namespace Backend.BL.DTOs
{
    public class ApplicationUserDTO
    {
        public string? UserId { get; set; }

        [Required]
        [StringLength(100)]
        public string Username { get; set; } = string.Empty;

        [StringLength(100)]
        public string? DisplayName { get; set; }

        [EmailAddress]
        public string? Email { get; set; }

        [StringLength(100, MinimumLength = 6)]
        public string? Password { get; set; }
    }
}
