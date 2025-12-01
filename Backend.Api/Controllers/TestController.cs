using Microsoft.AspNetCore.Mvc;

namespace Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        // GET: api/test/hello
        [HttpGet("hello")]
        public IActionResult Hello()
        {
            return Ok(new { message = "API is working!" });
        }

        // POST: api/test/echo
        [HttpPost("echo")]
        public IActionResult Echo([FromBody] object data)
        {
            return Ok(new { you_sent = data });
        }
    }
}
