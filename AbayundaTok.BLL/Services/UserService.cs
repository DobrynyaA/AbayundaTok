using AbayundaTok.BLL.DTO;
using AbayundaTok.BLL.Interfaces;
using AbayundaTok.DAL;
using Diplom.DAL.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Services
{
    public class UserService : IUserService
    {
        private readonly AppDbContext _context;
        private readonly UserManager<User> _userManager;

        public UserService(AppDbContext context, UserManager<User> userManager)
        {
            _context = context;
            _userManager = userManager;
        }

        public async Task<ProfileDto> GetUserProfileAsync(string userId)
        {
            return await _userManager.Users
                .Where(u => u.Id == userId)
                .Select(u => new ProfileDto
                {
                    UserName = u.UserName,
                    AvatarUrl = u.AvatarUrl,
                    Bio = u.Bio,
                    FollowersCount = u.Followers.Count,
                    FollowingCount = u.Following.Count,
                    CreatedAt = u.CreatedAt
                })
                .FirstOrDefaultAsync();
        }

        public async Task<ProfileDto> GetCurrentUserProfileAsync(string currentUserId)
        {
            return await GetUserProfileAsync(currentUserId);
        }
    }
}

