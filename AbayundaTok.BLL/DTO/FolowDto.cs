using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.DTO
{
    public class FollowDto
    {
        public string FollowerId { get; set; }
        public string FollowingId { get; set; }
        public DateTime? FollowerDate { get; set;} = DateTime.Now;
    }
}
