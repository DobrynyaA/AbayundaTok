using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Diplom.DAL.Entities
{
    public class Comment
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int VideoId { get; set; }
        public string Text { get; set; }
        public int? ParentCommentId { get; set; } // Для вложенных комментариев
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Навигационные свойства
        public User User { get; set; }
        public Video Video { get; set; }
        public Comment ParentComment { get; set; }
        public ICollection<Comment> Replies { get; set; }
    }
}
