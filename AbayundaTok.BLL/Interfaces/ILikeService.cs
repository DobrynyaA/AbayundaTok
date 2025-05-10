using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Interfaces
{
    public interface ILikeService
    {
        Task<string> PutLike(int videoId, string userId);
        Task<string> RemoveLike(int videoId, string userId);
        Task<bool> HasUserLiked(int videoId, string userId);
    }
}
