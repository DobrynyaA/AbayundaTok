using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Diplom.DAL.Entities
{
    public class View
    {
        public int Id { get; set; }
        public string? UserId { get; set; } // Может быть null (анонимный просмотр)
        public int VideoId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public User User { get; set; }
        public Video Video { get; set; }
    }
}
