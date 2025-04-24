using AbayundaTok.BLL.DTO;
using Diplom.DAL.Entities;
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
    }
}
