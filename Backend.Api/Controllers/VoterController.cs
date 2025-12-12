using Backend.BL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Api.Controllers
{

    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class VoterController : Controller
    {
        private readonly ILogger<VoterController> _logger;
        private readonly IVoterService _voterService;
        public VoterController(ILogger<VoterController> logger, IVoterService voterService)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _voterService = voterService ?? throw new ArgumentNullException(nameof(voterService));
        }

    }
}
