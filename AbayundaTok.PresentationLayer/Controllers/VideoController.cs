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
using System.IdentityModel.Tokens.Jwt;

namespace AbayundaTok.PresentationLayer.Controllers
{
    [Route("api/[controller]")]
    public class VideoController : ControllerBase
    {
        private readonly IVideoService _videoService;
        private readonly ILikeService _likeService;

        public VideoController(IVideoService videoService, ILikeService likeService)
        {
            _videoService = videoService;
            _likeService = likeService;
        }

        [Authorize]
        [HttpPost("upload")]
        public async Task<IActionResult> UploadVideo(UploadVideo video)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var videoId = await _videoService.UploadVideoAsync(video.VideoFile,video.Description,userId);
            return Ok(new { VideoId = videoId });
        }

        [HttpGet("{videoUrl}/playlist")]
        public async Task<IActionResult> GetPlaylist(string videoUrl)
        {
            var playlistUrl = await _videoService.GetVideoPlaylistAsync(videoUrl);
            return Ok(new { PlaylistUrl = playlistUrl });
        }

        [HttpGet("{videoUrl}/metadata")]
        public async Task<IActionResult> GetMetadata(string videoUrl)
        {
            var meta = await _videoService.GetVideoMetadataAsync(videoUrl);
            var token = Request.Headers["Authorization"].FirstOrDefault()?.Split(" ").Last();
            string? userId;
            if (token == null)
            {
                userId = null;
            }
            else
            {
                try
                {
                    var handler = new JwtSecurityTokenHandler();
                    var jwtToken = handler.ReadJwtToken(token);
                    userId = jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
                    meta.IsLiked = await _likeService.HasUserLiked(meta.Id, userId);
                }
                catch
                {
                    userId = null;
                }
            }

            return Ok(meta);
        }

        [HttpGet("lenta")]
        public async Task<ActionResult<IEnumerable<VideoDto>>> GetVideo([FromQuery] int page = 1, [FromQuery] int limit = 3)
        {
            try
            {
                if (page < 1 || limit < 1 || limit > 100)
                    return BadRequest("Invalid pagination parameters");

                var result = await _videoService.GetVideosAsync(page, limit);

                return Ok(result);
            }
            catch (Exception ex)
            {

                return StatusCode(500, "Internal server error");
            }
        }
        private string? GetUserIdFromToken()
        {
            var token = Request.Headers["Authorization"].FirstOrDefault()?.Split(" ").Last();
            if (string.IsNullOrEmpty(token))
                return null;

            try
            {
                var handler = new JwtSecurityTokenHandler();
                var jwtToken = handler.ReadJwtToken(token);
                return jwtToken.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
            }
            catch
            {
                return null;
            }
        }
    }
}
