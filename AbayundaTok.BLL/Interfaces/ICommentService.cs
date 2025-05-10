using Diplom.DAL.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.Interfaces
{
    public interface ICommentService
    {
        Task<List<Comment>> GetCommentsForVideo(int videoId);
        Task<Comment> AddComment(int videoId, string userId, string text);
    }
}
