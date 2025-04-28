using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Diplom.DAL.Entities
{
    public class Like
    {
        public int Id { get; set; }
        public string UserId { get; set; }
        public int VideoId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Навигационные свойства
        public User User { get; set; }
        public Video Video { get; set; }
    }
}
