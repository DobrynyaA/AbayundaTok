using AbayundaTok.BLL.DTO;
using AbayundaTok.BLL.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.PresentationLayer.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MinioController : ControllerBase
    {
        private readonly IMinioService _minioService;

        public MinioController(IMinioService minioService)
        {
            _minioService = minioService;
        }

        [HttpPost("upload")]
        public async Task<IActionResult> UploadVideo(IFormFile file)
        {
            var objectName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
            await _minioService.UploadVideoAsync(file, objectName);
            return Ok(new { ObjectName = objectName });
        }

        [HttpGet("stream/{objectName}")]
        public async Task<IActionResult> StreamVideo(string objectName)
        {
            var stream = await _minioService.GetVideoAsync(objectName);
            return File(stream, "video/mp4", enableRangeProcessing: true);
        }
    }
}
