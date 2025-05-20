using AbayundaTok.BLL.DTO;
using AbayundaTok.BLL.Interfaces;
using Diplom.DAL.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
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
    public class ProfileController : ControllerBase
    {
        private readonly IUserService _profileService;

        public ProfileController(IUserService profileService)
        {
            _profileService = profileService;
        }

        [HttpGet("my")]
        [Authorize]
        public async Task<ActionResult<ProfileDto>> GetMyProfile()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var profile = await _profileService.GetCurrentUserProfileAsync(userId);

            if (profile == null)
                return NotFound();

            return profile;
        }

        [HttpGet("{userId}")]
        public async Task<ActionResult<ProfileDto>> GetUserProfile(string userId)
        {
            var profile = await _profileService.GetUserProfileAsync(userId);

            if (profile == null)
                return NotFound();

            return profile;
        }
        [Authorize]
        [HttpPost("uploadAvatar")]
        public async Task<IActionResult> UploadPhoto(IFormFile file)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if(userId is null)
                throw new ArgumentNullException(nameof(userId));

            if (file == null || file.Length == 0)
                return BadRequest("No file uploaded");

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(extension))
                return BadRequest("Invalid file type");

            try
            {
                var photoUrl = await _profileService.UploadAvatarAsync(file, userId);
                return Ok(new { PhotoUrl = photoUrl });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost("AvatarUrl")]
        public async Task<string> GetAvatarUrl(string avatarUrl)
        {
            return await _profileService.GetAvatarUrlAsync(avatarUrl);
        }

        [HttpGet("/folowwers/{userId}")]
        public async Task<ActionResult<List<FolowerDto>>> GetFolowers(string userId)
        {
            var folowers = await _profileService.GetFolowerListAsync(userId);

            if (folowers == null)
                return NotFound();

            return folowers;
        }

        [HttpGet("/folowing/{userId}")]
        public async Task<ActionResult<List<FolowerDto>>> GetFolowing(string userId)
        {
            var folowers = await _profileService.GetFolowingListAsync(userId);

            if (folowers == null)
                return NotFound();

            return folowers;
        }

        [HttpPut("update")]
        [Authorize]
        public async Task<IActionResult> UpdateProfile(EditUserDto model)
        {
            try 
            { 
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (userId is null)
                    throw new ArgumentNullException(nameof(userId));

                if (model.Avatar != null && model.Avatar.Length != 0)
                {
                    var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif" };
                    var extension = Path.GetExtension(model.Avatar.FileName).ToLowerInvariant();

                    if (!allowedExtensions.Contains(extension))
                        return BadRequest("Invalid file type");
                    var photoUrl = await _profileService.UploadAvatarAsync(model.Avatar, userId);
                }
                var request = await _profileService.EditUserAsync(model,userId);
                return Ok();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}
