using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AbayundaTok.BLL.DTO
{
    public class AuthResponseDto
    {
        public string Token { get; set; }
        public DateTime Expiration { get; set; }
        public string? Email { get; set; }
        public string? UserId { get; set; }

    }
}
