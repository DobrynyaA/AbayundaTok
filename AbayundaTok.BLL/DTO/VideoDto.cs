using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.DTO
{
    public class VideoDto
    {
        public int Id { get; set; }
        public string? HlsUrl { get; set; }
        public string? AvtorId { get; set; }
        public string? Description { get; set; }
        public int LikeCount {  get; set; }
        public int CommentCount { get; set; }
        public bool? IsLiked {  get; set; }
        public string? ThumbnailUrl { get; set; }
        public string? AvtorAvatarUrl { get; set; }
        public string? AvtorName { get; set; }
    }
}
