using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Diplom.DAL.Entities
{
    public class Hashtag
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public ICollection<VideoHashtag> VideoHashtags { get; set; }
    }

    public class VideoHashtag
    {
        public int VideoId { get; set; }
        public int HashtagId { get; set; }

        public Video Video { get; set; }
        public Hashtag Hashtag { get; set; }
    }
}
