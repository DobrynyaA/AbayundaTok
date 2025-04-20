using Diplom.DAL.Configurations;
using Diplom.DAL.Entities;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace AbayundaTok.DAL
{
    public class AppDbContext : IdentityDbContext<User>
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
        {
        }
        public DbSet<User> Users { get; set; }
        public DbSet<Comment> Comments { get; set; }
        public DbSet<Follow> Followers { get; set; }
        public DbSet<Like> Likes { get; set; }
        public DbSet<Role> Roles { get; set; }
        public DbSet<Video> Videos { get; set; }
        public DbSet<Hashtag> Hashtags { get; set; }
        public DbSet<VideoHashtag> VideoHashtags { get; set; }
        public DbSet<View> Views { get; set; }
        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            modelBuilder.ApplyConfiguration(new FollowConfiguration());
            modelBuilder.ApplyConfiguration(new VideoHashtagConfiguration());
        }
    }
}
