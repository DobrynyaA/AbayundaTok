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

namespace AbayundaTok.PresentationLayer.Controllers
{
    public class VideoController : ControllerBase
    {
        private readonly IVideoService _videoService;

        public VideoController(IVideoService videoService)
        {
            _videoService = videoService;
        }

        [Authorize]
        [HttpPost("upload")]
        public async Task<IActionResult> UploadVideo(IFormFile file)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var videoId = await _videoService.UploadVideoAsync(file,userId);
            return Ok(new { VideoId = videoId });
        }

        // Получение HLS-плейлиста
        [HttpGet("{videoUrl}/playlist")]
        public async Task<IActionResult> GetPlaylist(string videoUrl)
        {
            var playlistUrl = await _videoService.GetVideoPlaylistAsync(videoUrl);
            return Ok(new { PlaylistUrl = playlistUrl });
        }

        // Получение метаданных
        [HttpGet("{videoUrl}/metadata")]
        public async Task<IActionResult> GetMetadata(string videoUrl)
        {
            var meta = await _videoService.GetVideoMetadataAsync(videoUrl);
            return Ok(meta);
        }
    }
}
