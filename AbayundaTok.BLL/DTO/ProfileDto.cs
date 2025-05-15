using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.DTO
{
    public class ProfileDto
    {
        public string? UserName { get; set; }
        public string? AvatarUrl { get; set; }
        public string? Bio { get; set; }
        public int FollowersCount { get; set; }
        public int FollowingCount { get; set; }
        public DateTime? CreatedAt { get; set; }
        public long LikeCount {  get; set; }
        public List<VideoDto> Videos { get; set; }

    }
}
