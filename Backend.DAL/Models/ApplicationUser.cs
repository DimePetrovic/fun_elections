using Microsoft.AspNetCore.Identity;

namespace Backend.DAL.Models;
public class ApplicationUser : IdentityUser
{
    public string DisplayName { get; set; } = string.Empty;
    public List<Voter> Voters { get; set; } = new();
}
