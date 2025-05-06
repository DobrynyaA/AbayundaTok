using AbayundaTok.BLL.DTO;
using AbayundaTok.BLL.Interfaces;
using AbayundaTok.DAL;
using Diplom.DAL.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Minio;
using Minio.DataModel.Args;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Services
{
    public class UserService : IUserService
    {
        private readonly IMinioClient _minioClient;
        private readonly AppDbContext _context;
        private readonly UserManager<User> _userManager;
        private const string BucketName = "avatars";

        public UserService(AppDbContext context, UserManager<User> userManager, IMinioClient minioClient)
        {
            _minioClient = minioClient;
            _context = context;
            _userManager = userManager;
        }

        public async Task<ProfileDto> GetUserProfileAsync(string userId)
        {
            var userProfile = await _userManager.Users
                .Where(u => u.Id == userId)
                .Select(u => new ProfileDto
                {
                    UserName = u.UserName,
                    AvatarUrl = u.AvatarUrl,
                    Bio = u.Bio,
                    FollowersCount = u.Followers.Count,
                    FollowingCount = u.Following.Count,
                    CreatedAt = u.CreatedAt,
                })
                .FirstOrDefaultAsync();
            userProfile.AvatarUrl = await GetAvatarUrlAsync(userProfile.AvatarUrl);
            userProfile.LikeCount = await _context.Videos.Where(u=>u.UserId == userId).SumAsync(likes => likes.LikeCount);
            return userProfile;
        }

        public async Task<ProfileDto> GetCurrentUserProfileAsync(string currentUserId)
        {
            return await GetUserProfileAsync(currentUserId);
        }

        public async Task<string> UploadAvatarAsync(IFormFile file, string userId)
        {
            await EnsureBucketExistsAsync();

            var photoUrl = Guid.NewGuid().ToString();
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var objectName = $"{photoUrl}{extension}";

            await using (var stream = file.OpenReadStream())
            {
                await _minioClient.PutObjectAsync(
                    new PutObjectArgs()
                        .WithBucket(BucketName)
                        .WithObject(objectName)
                        .WithStreamData(stream)
                        .WithObjectSize(file.Length)
                        .WithContentType(file.ContentType)
                );
            }

            var user = await _context.Users.FindAsync(userId);
            if (user != null)
            {
                user.AvatarUrl = objectName;
                await _context.SaveChangesAsync();
            }

            return objectName;
        }

        public Task<Stream> GetAvatarStreamAsync(string photoUrl)
        {
            throw new NotImplementedException();
        }

        public async Task<string> GetAvatarUrlAsync(string photoUrl)
        {
            return $"http://10.0.2.2:9000/{BucketName}/{photoUrl}";
        }

        private async Task EnsureBucketExistsAsync()
        {
            var exists = await _minioClient.BucketExistsAsync(
                new BucketExistsArgs().WithBucket(BucketName)
            );

            if (!exists)
                await _minioClient.MakeBucketAsync(
                    new MakeBucketArgs().WithBucket(BucketName)
                );
        }
    }
}

