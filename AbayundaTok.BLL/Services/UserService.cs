using AbayundaTok.BLL.DTO;
using AbayundaTok.BLL.Interfaces;
using AbayundaTok.DAL;
using AbayundaTok.DAL.Constants;
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
        private readonly IVideoService _videoService;
        private const string BucketName = "avatars";

        public UserService(AppDbContext context, UserManager<User> userManager, IMinioClient minioClient, IVideoService videoService)
        {
            _minioClient = minioClient;
            _context = context;
            _userManager = userManager;
            _videoService = videoService;
        }

        public async Task<ProfileDto> GetUserProfileAsync(string userId)
        {
            var userVideos = await _videoService.GetUserVideosMetadataAsync(userId);
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
                    Videos = userVideos
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
            return $"{URL.Url}/{BucketName}/{photoUrl}";
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

        public async Task<List<FolowerDto>> GetFolowerListAsync(string userId)
        {
            var followers = await _context.Followers
            .Where(f => f.FollowingId == userId) 
            .Include(f => f.Follower) 
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new FolowerDto
            {
                Id = f.Follower.Id,
                UserName = f.Follower.UserName,
                AvatarUrl = $"{URL.Url}/avatars/{f.Follower.AvatarUrl}",
                Bio = f.Follower.Bio ?? string.Empty
            })
            .ToListAsync();

            return followers;
        }

        public async Task<List<FolowerDto>> GetFolowingListAsync(string userId)
        {
            var followers = await _context.Followers
            .Where(f => f.FollowerId == userId)
            .Include(f => f.Following)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new FolowerDto
            {
                Id = f.Following.Id,
                UserName = f.Following.UserName,
                AvatarUrl = $"{URL.Url}/avatars/{f.Following.AvatarUrl}",
                Bio = f.Following.Bio ?? string.Empty
            })
            .ToListAsync();

            return followers;
        }

        public async Task<string> Follow(string userId, string signatoryId)
        {
            var follow = new Follow
            {
                FollowerId = userId,
                FollowingId = signatoryId
            };

            _context.Followers.Add(follow);
            await _context.SaveChangesAsync();

            return "Сервис подписки отработал";
        }

        public async Task<string> Unfollow(string userId, string signatoryId)
        {
                var request = await _context.Followers.FirstOrDefaultAsync(e => e.FollowerId == userId && e.FollowingId == signatoryId);
                if (request == null)
                    return "Пользователь не найден";

                _context.Followers.Remove(request);
                await _context.SaveChangesAsync();

                return "Сервис отписки отработал";
        }

        public async Task<bool> IsFollowing(string userId, string signatoryId)
        {
            return await _context.Followers.AnyAsync(e => e.FollowerId == userId && e.FollowingId == signatoryId);
        }

        public async Task<string> EditUserAsync(EditUserDto user, string userId)
        {
            var userFromDb = await _context.Users.FirstOrDefaultAsync(e => e.Id == userId);
            if (userFromDb == null)
                return "Пользователь не найднед";

            userFromDb.Bio = user.Bio;
            userFromDb.UserName = user.UserName;
            _context.Users.Update(userFromDb);
            await _context.SaveChangesAsync();
            return "Пользователь изменен";

        }
    }
}

