using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.DTO
{
    public  class CommentDto
    {
        public int VideoId { get; set; }
        public string Text { get; set; }
        public string? UserId { get; set; }
        public int? Id { get; set; }
        public string? UserName { get; set; }
        public DateTime? CreatedAt { get; set; }
    }
}
