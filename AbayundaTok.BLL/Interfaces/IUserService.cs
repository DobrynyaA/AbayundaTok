using AbayundaTok.BLL.DTO;
using Diplom.DAL.Entities;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Interfaces
{
    public  interface IUserService
    {
        Task<ProfileDto> GetUserProfileAsync(string userId);
        Task<ProfileDto> GetCurrentUserProfileAsync(string currentUserId);
        Task<string> UploadAvatarAsync(IFormFile file, string userId);
        Task<Stream> GetAvatarStreamAsync(string photoUrl);
        Task<string> GetAvatarUrlAsync(string photoUrl);
        Task<List<FolowerDto>> GetFolowerListAsync(string userId);
        Task<List<FolowerDto>> GetFolowingListAsync(string userId);
        Task<string> Follow(string userId, string signatoryId);
        Task<string> Unfollow(string userId, string signatoryId);
        Task<bool> IsFollowing(string userId,string signatoryId);
        Task<string> EditUserAsync(EditUserDto user,  string userId);
    }
}
