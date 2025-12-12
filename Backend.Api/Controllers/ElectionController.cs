using Backend.BL.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class ElectionController : Controller
    {
        private readonly ILogger<ElectionController> _logger;
        private readonly IElectionService _ElectionService;

        public ElectionController(ILogger<ElectionController> logger, IElectionService ElectionService)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _ElectionService = ElectionService ?? throw new ArgumentNullException(nameof(ElectionService));
        }



    }
}
