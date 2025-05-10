
using AbayundaTok.BLL.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using AbayundaTok.BLL.DTO;

namespace AbayundaTok.PresentationLayer.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    public class LikeController : ControllerBase
    {
        private readonly ILikeService _likeService;

        public LikeController(ILikeService likeService)
        {
            _likeService = likeService;
        }

        [HttpPost("{videoId}")]
        public async Task<IActionResult> AddLike(int videoId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { Message = "Требуется авторизация" });
                }

                var result = await _likeService.PutLike(videoId, userId);

                return Ok(new
                {
                    Success = true,
                    LikeCount = result,
                    Message = "Лайк успешно добавлен"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Success = false,
                    Message = "Произошла ошибка при добавлении лайка"
                });
            }
        }

        [HttpDelete("{videoId}")]
        public async Task<IActionResult> RemoveLike(int videoId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { Message = "Требуется авторизация" });
                }

                var result = await _likeService.RemoveLike(videoId, userId);

                return Ok(new
                {
                    Success = true,
                    LikeCount = result,
                    Message = "Лайк успешно убран"
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Success = false,
                    Message = "Произошла ошибка при удалении лайка"
                });
            }
        }

        [HttpGet("{videoId}/check")]
        public async Task<IActionResult> CheckLike(int videoId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized(new { Message = "Требуется авторизация" });
                }

                var hasLiked = await _likeService.HasUserLiked(videoId, userId);

                return Ok(new
                {
                    Success = true,
                    HasLiked = hasLiked
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    Success = false,
                    Message = "Произошла ошибка при проверке лайка"
                });
            }
        }
    }
}
