using AbayundaTok.BLL.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using AbayundaTok.BLL.DTO;

namespace AbayundaTok.PresentationLayer.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    public class CommentController : ControllerBase
    {
        private readonly ICommentService _commentService;

        public CommentController(ICommentService commentService)
        {
            _commentService = commentService;
        }

        [HttpGet("{videoId}")]
        public async Task<IActionResult> GetComments(int videoId)
        {
            var comments = await _commentService.GetCommentsForVideo(videoId);
            return Ok(comments);
        }

        [HttpPost]
        public async Task<IActionResult> AddComment([FromBody] CommentDto commentDto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var userName = User.FindFirstValue(ClaimTypes.Name);

            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized();
            }

            var comment = await _commentService.AddComment(
                commentDto.VideoId,
                userId,
                commentDto.Text
            );
            var result = new CommentDto
            {
                Id = comment.Id,
                UserId = userId,
                VideoId = comment.VideoId,
                UserName = comment.UserName,
                Text = comment.Text,
                CreatedAt = comment.CreatedAt,
            };
            return Ok(result);
        }
    }
}
