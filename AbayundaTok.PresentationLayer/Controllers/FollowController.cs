using AbayundaTok.BLL.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using AbayundaTok.BLL.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace AbayundaTok.PresentationLayer.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    public class FollowController : ControllerBase
    {
        private readonly IUserService _userService;

        public FollowController(IUserService userService)
        {
            _userService = userService;
        }

        [HttpPost("follow/{signatoryId}")]
        public async Task<IActionResult> Follow(string signatoryId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if(string.IsNullOrEmpty(userId))
                {
                    return BadRequest();
                }

                var result = await _userService.Follow(userId,signatoryId);

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Success = false,
                    Message = "Произошла ошибка при подписке"
                });
            }
        }

        [HttpPost("unfollow/{signatoryId}")]
        public async Task<IActionResult> Unfollow(string signatoryId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return BadRequest();
                }

                var result = await _userService.Unfollow(userId, signatoryId);

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Success = false,
                    Message = "Произошла ошибка при отписке"
                });
            }
        }

        [HttpPost("isfollower/{signatoryId}")]
        public async Task<IActionResult> IsFollow(string signatoryId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return BadRequest();
                }

                var result = await _userService.IsFollowing(userId, signatoryId);

                return Ok(result);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Success = false,
                    Message = "Произошла ошибка при отписке"
                });
            }
        }
    }
}
