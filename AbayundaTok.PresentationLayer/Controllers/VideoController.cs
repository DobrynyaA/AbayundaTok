using AbayundaTok.BLL.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.PresentationLayer.Controllers
{
    public class VideoController : ControllerBase
    {
        private readonly IVideoService _videoService;

        public VideoController(IVideoService videoService)
        {
            _videoService = videoService;
        }

        // Загрузка видео
        [HttpPost("upload")]
        public async Task<IActionResult> UploadVideo(IFormFile file, string name)
        {
            var videoId = await _videoService.UploadVideoAsync(file, name);
            return Ok(new { VideoId = videoId });
        }

        // Получение HLS-плейлиста
        [HttpGet("{videoId}/playlist")]
        public async Task<IActionResult> GetPlaylist(int videoId)
        {
            var playlistUrl = await _videoService.GetVideoPlaylistAsync(videoId);
            return Ok(new { PlaylistUrl = playlistUrl });
        }

        // Получение метаданных
        [HttpGet("{videoId}/metadata")]
        public async Task<IActionResult> GetMetadata(int videoId)
        {
            var meta = await _videoService.GetVideoMetadataAsync(videoId);
            return Ok(meta);
        }
    }
}
