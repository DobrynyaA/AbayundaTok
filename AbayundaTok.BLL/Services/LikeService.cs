using AbayundaTok.BLL.Interfaces;
using AbayundaTok.DAL;
using Diplom.DAL.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Minio;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Services
{
    public class LikeService : ILikeService
    {
        private readonly AppDbContext _dbContext;
        private readonly UserManager<User> _userManager;

        public LikeService(AppDbContext context, UserManager<User> userManager)
        {
            _dbContext = context;
            _userManager = userManager;
        }

        public async Task<string> PutLike(int videoId, string userId)
        {
            var existingLike = await _dbContext.Likes.FirstOrDefaultAsync(l => l.VideoId == videoId && l.UserId == userId);

            if (existingLike != null)
            {
                return "Лайк уже поставлен";
            }

            using var transaction = await _dbContext.Database.BeginTransactionAsync();

            var like = new Like
            {
                VideoId = videoId,
                UserId = userId
            };
            try
            {
                _dbContext.Likes.Add(like);
                var changeVideo = await _dbContext.Videos.FirstOrDefaultAsync(v => v.Id == videoId);
                changeVideo.LikeCount++;
                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();
                return changeVideo.LikeCount.ToString();
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                Console.WriteLine("Не удалось поставить лайк!");
                throw;
            }
        }

        public async Task<string> RemoveLike(int videoId, string userId)
        {
            var existingLike = await _dbContext.Likes.FirstOrDefaultAsync(l => l.VideoId == videoId && l.UserId == userId);

            if (existingLike == null)
            {
                return "Лайк не найден";
            }

            using var transaction = await _dbContext.Database.BeginTransactionAsync();

            try
            {
                _dbContext.Likes.Remove(existingLike);
                var video = await _dbContext.Videos.FirstOrDefaultAsync(v => v.Id == videoId);

                if (video == null)
                {
                    return "Видео не найдено";
                }

                video.LikeCount--;
                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();
                return video.LikeCount.ToString();
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                Console.WriteLine($"Ошибка при удалении лайка: {ex.Message}");
                throw;
            }
        }

        public async Task<bool> HasUserLiked(int videoId, string userId)
        {
            return await _dbContext.Likes
                .AnyAsync(l => l.VideoId == videoId && l.UserId == userId);
        }
    }
}
