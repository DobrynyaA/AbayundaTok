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
    public class CommentService : ICommentService
    {
        private readonly AppDbContext _dbContext;
        private readonly UserManager<User> _userManager;

        public CommentService(AppDbContext context, UserManager<User> userManager)
        {
            _dbContext = context;
            _userManager = userManager;
        }

        public async Task<Comment> AddComment(int videoId, string userId, string text)
        {
            using var transaction = await _dbContext.Database.BeginTransactionAsync();
            try
            {
                var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
                var comment = new Comment
                {
                    UserId = userId,
                    VideoId = videoId,
                    Text = text,
                    UserName = user.UserName,
                };
                var video = await _dbContext.Videos.FirstOrDefaultAsync(u => u.Id == videoId);
                video.CommentCount++;
                _dbContext.Comments.Add(comment);
                await _dbContext.SaveChangesAsync();
                await transaction.CommitAsync();
                return comment;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                Console.WriteLine($"Не удалось добавить комментарий: {ex}");
                throw;
            }
        }

        public async Task<List<Comment>> GetCommentsForVideo(int videoId)
        {
            return await _dbContext.Comments.Where(v => v.VideoId == videoId).ToListAsync();
        }
    }
}
