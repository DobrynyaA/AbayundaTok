using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Diplom.DAL.Entities;
namespace Diplom.DAL.Configurations
{
    internal class VideoHashtagConfiguration : IEntityTypeConfiguration<VideoHashtag>
    {
        public void Configure(EntityTypeBuilder<VideoHashtag> builder)
        {
            builder.HasKey(vh => new { vh.VideoId, vh.HashtagId });

            builder.HasOne(vh => vh.Video)
                .WithMany(v => v.Hashtags)
                .HasForeignKey(vh => vh.VideoId)
                .OnDelete(DeleteBehavior.Cascade);
            builder.HasOne(vh => vh.Hashtag)
                .WithMany(h => h.VideoHashtags)
                .HasForeignKey(vh => vh.HashtagId)
                .OnDelete(DeleteBehavior.Cascade);
        }
    }
}
