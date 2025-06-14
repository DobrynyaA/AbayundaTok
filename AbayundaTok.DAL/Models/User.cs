using Microsoft.EntityFrameworkCore.Metadata.Internal;
using System;
using Microsoft.AspNetCore.Identity;

namespace Diplom.DAL.Entities
{
    public class User : IdentityUser
    {
        public string? AvatarUrl { get; set; }
        public string? Bio { get; set; }
        public DateTime? CreatedAt { get; set; } = DateTime.UtcNow;
        public bool? IsActive { get; set; } = true;
        public ICollection<Video> Videos { get; set; }
        public ICollection<Like>? Likes { get; set; }
        public ICollection<Comment>? Comments { get; set; }
        public ICollection<Follow>? Followers { get; set; } // Подписчики
        public ICollection<Follow>? Following { get; set; } // Подписки пользователя
        public ICollection<View>? Views { get; set; }
    }
}
