using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Diplom.DAL.Entities
{
    public class Follow
    {
        public int Id { get; set; }
        public string FollowerId { get; set; } // Тот, кто подписывается
        public string FollowingId { get; set; } // На кого подписываются
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Навигационные свойства
        public User Follower { get; set; }
        public User Following { get; set; }
    }
}
